% Spica_rollcontrol3.0
% edit by sano taisei

% for Spica_rollcontrol3.1

classdef Calculation2
    %CALCULATION2 計算実行＋結果格納用クラス

    properties
        %====General setting=====
        general_setting;

        %=====calculation=====
        % res は mode 名をフィールドとする struct。
        %   res.Hard    → elev × Vw0 × Wpsi × param の MainSolver 配列
        %   res.Descent → 同上（"Both" または "Descent" 選択時のみ存在）
        res = struct();
        ms = [];
        para_num = [];
        output_dir = "";        % ログ・画像等の出力先（paramN フォルダの絶対パス）

        % 計算中にスキップ／失敗した条件の情報を蓄積（§3-7）
        skipped_conditions = strings(0,1);
        % ログ出力の累計ファイル数（§3-5）
        log_file_count = 0;
    end

    methods

        function obj = Calculation2(gs)
            obj.general_setting = gs;
            obj.ms = repmat(MainSolver(gs,1), 1, gs.param_n);
            for i = 2:gs.param_n
                obj.ms(i) = MainSolver(gs,i);
            end
            % 射点緯経度（諸元表の lat/lon）から経緯度変換クラスを構築する。
            % 落下点・vs-time ログ・KML の緯度経度計算に general_setting.ll を使用する。
            % 未設定（ll が空）のときのみ生成し、既存設定は尊重する。
            if isempty(obj.general_setting.ll) && ~isempty(obj.ms)
                obj.general_setting.ll = lon_lat([obj.ms(1).lat, obj.ms(1).lon]);
            end
            obj = obj.calculation();
        end

        function obj = calculation(obj) % 計算実行関数
            disp(" ")
            disp("***** Calculation Start! *****")

            % 出力先フォルダを事前確定（ログ・画像共通）
            obj = obj.init_output_dir();

            % "Both" を {"Hard","Descent"} に展開
            ml = string(obj.general_setting.mode_landing);
            if ml == "Both"
                mode_list = {'Hard', 'Descent'};
            else
                mode_list = {char(ml)};
            end

            for iMode = 1:numel(mode_list)
                cur_mode = mode_list{iMode};
                disp(strcat("Landing Mode：", cur_mode))

                % MSM/csv wind_model: Vw0/Wpsi ループを無効化
                wm = string(obj.general_setting.wind_model);
                if wm == "MSM" || wm == "csv"
                    eff_Vw0_n  = 1;
                    eff_Wpsi_n = 1;
                    disp('wind_model MSM/csv: Vw0/Wpsi loop disabled.')
                else
                    eff_Vw0_n  = obj.general_setting.Vw0_n;
                    eff_Wpsi_n = obj.general_setting.Wpsi_n;
                end

                % 各段(MainSolver)へランディングモードを流し込む
                for k = 1:obj.general_setting.param_n
                    obj.ms(k).mode_landing = cur_mode;
                end

                %==== 4次元コンテナ(elev × Vw0 × Wpsi × param)を生成 ====
                res_4d = repmat(obj.ms(1), ...
                    obj.general_setting.elev_n, ...
                    eff_Vw0_n, ...
                    eff_Wpsi_n, ...
                    obj.general_setting.param_n);

                for j = 2:obj.general_setting.param_n
                    res_4d(:,:,:,j) = repmat(obj.ms(j), ...
                        obj.general_setting.elev_n, ...
                        eff_Vw0_n, ...
                        eff_Wpsi_n, 1);
                end

                %==== 3重ループ（Wpsi だけ parfor）====
                for jElev = 1:obj.general_setting.elev_n
                    disp(strcat("Elevation = ", num2str(obj.general_setting.elev(jElev)), "°"))
                    for jV = 1:eff_Vw0_n
                        disp(strcat("Now Calculating：Vw0 = ", num2str(obj.general_setting.Vw0(jV)), "..."))

                        Wn      = eff_Wpsi_n;
                        pn      = obj.general_setting.param_n;
                        gs_loc  = obj.general_setting;
                        ms_loc  = obj.ms;

                        % べき法則風かつ Vw0=0 の条件では風向依存性が無いため
                        % 風向ループを 1 条件 (Wpsi=0deg) にまとめる
                        is_zero_wind = (string(gs_loc.wind_model) == "PowerLaw") ...
                                       && (gs_loc.Vw0(jV) == 0);
                        if is_zero_wind
                            Wn_eff = 1;
                            disp('  -> Vw0=0 m/s in PowerLaw: Wpsi loop collapsed to a single Wpsi=0deg case.')
                        else
                            Wn_eff = Wn;
                        end

                        res_line = repmat(ms_loc(1), Wn, 1, 1, pn);

                        if strcmpi(gs_loc.parallel,'Yes')
                            parfor jPsi = 1:Wn_eff
                                res_line(jPsi,1,1,:) = Calculation2.run_one_condition( ...
                                    ms_loc, gs_loc, jElev, jV, jPsi);
                            end
                        else
                            for jPsi = 1:Wn_eff
                                res_line(jPsi,1,1,:) = Calculation2.run_one_condition( ...
                                    ms_loc, gs_loc, jElev, jV, jPsi);
                            end
                        end

                        % Vw0=0 のとき Wpsi 表示を 0deg に統一（ログファイル名等の整合用）
                        if is_zero_wind
                            for iStage = 1:pn
                                res_line(1,1,1,iStage).Wpsi = 0;
                            end
                        end

                        res_4d(jElev, jV, :, :) = res_line;

                        % §2.2: Vw0 1 条件（実計算した Wpsi × 全段）の解析完了直後に逐次ログ出力
                        obj = obj.record_logs_for_Vw0( ...
                            res_4d, jElev, jV, Wn_eff, obj.general_setting.param_n);

                    end
                end

                % モード別に格納
                obj.res.(cur_mode) = res_4d;
            end

            % 計算完了後のサマリ・ログ未記録条件の検出（§3-7）
            obj = obj.collect_unrecorded_skips();

            % §3-1: 実行条件サマリの書き出し
            obj.write_run_info();

            fprintf('***** Calculation Done. log files written = %d, skipped = %d *****\n', ...
                    obj.log_file_count, numel(obj.skipped_conditions));
        end

        function obj = init_output_dir(obj)    % 出力先フォルダ（paramN）の確定と作成
            if ~isfolder(obj.general_setting.result_path)
                mkdir(obj.general_setting.result_path);
            end

            if obj.general_setting.execute_cont
                func_dir = obj.general_setting.control_func;
            else
                func_dir = 'uncontroled';
            end
            func_path = fullfile(obj.general_setting.result_path, func_dir);
            if ~isfolder(func_path)
                mkdir(func_path);
            end

            manual_para_num = ~isempty(obj.para_num);
            if ~manual_para_num
                existing = dir(fullfile(func_path, 'param*'));
                existing = existing([existing.isdir]);
                if ~isempty(existing)
                    nums = str2double(erase({existing.name}, 'param'));
                    nums = nums(~isnan(nums));
                    if ~isempty(nums)
                        obj.para_num = max(nums) + 1;
                    else
                        obj.para_num = 1;
                    end
                else
                    obj.para_num = 1;
                end
            end

            para_path = fullfile(func_path, strcat('param', num2str(obj.para_num)));

            % §3-6: para_num を明示指定したとき、既存フォルダに中身があれば警告。
            if manual_para_num && isfolder(para_path)
                entries = dir(para_path);
                entries = entries(~ismember({entries.name}, {'.','..'}));
                if ~isempty(entries)
                    warning(['init_output_dir: para_num=%d で既存の paramN フォルダが' ...
                             ' 使用されます: %s\n  既存ファイルが上書き／混在する可能性があります。'], ...
                            obj.para_num, para_path);
                end
            end

            if ~isfolder(para_path)
                mkdir(para_path);
            end
            obj.output_dir = para_path;
        end

        function [dir_fn,dir_tmp,obj] = make_outputfile(obj, file_type, fn, subdir)
            % 記録ファイル作成用関数。
            % subdir を渡すと output_dir からの相対サブフォルダ配下に作成する。
            if nargin < 4, subdir = ''; end

            if isempty(obj.output_dir) || ~isfolder(obj.output_dir)
                obj = obj.init_output_dir();
            end

            switch file_type
                case 'log'
                    format = 'Format_Log.xlsx';
                case 'control'
                    format = 'Format_Control.xlsx';
            end

            if isempty(subdir) || strlength(string(subdir)) == 0
                dir_tmp = char(obj.output_dir);
            else
                dir_tmp = char(fullfile(obj.output_dir, subdir));
            end
            if ~isfolder(dir_tmp)
                mkdir(dir_tmp);
            end
            dir_fn = fullfile(dir_tmp, fn);
            form = fullfile(char(obj.general_setting.dir.form), format);
            copyfile(form, dir_fn, 'f')
        end

        function [obj, skipped] = record_log(obj, ms_res, stage_idx)
            % vs-time ログ等を新階層へ出力する（§2.1+§2.3）。
            %   出力先: <paramN>/<Mode>/TimeLog/elev<E>deg/Vw0<V>ms/
            %   ファイル名末尾に Wpsi<W>deg / Ns<n> / roll factor / Launch|Rot を付与し、
            %   全条件で一意な名前にすることで上書き衝突を回避する。
            skipped = false;
            if nargin < 3, stage_idx = []; end

            if isempty(ms_res.ys) || isempty(ms_res.xs)
                cond_label = obj.cond_label_for_skip(ms_res, stage_idx);
                warning('record_log: xs/ys is empty, skipping log output (%s).', cond_label);
                obj.skipped_conditions(end+1,1) = string(cond_label);
                skipped = true;
                return;
            end

            % --- 条件接尾辞の組み立て（§2.1） ---
            if strcmp(ms_res.roll_factor,"Coefficience")
                roll_str = strcat("Cl0_", Calculation2.num_token(ms_res.Cl0));
            else
                roll_str = strcat("Mx_", extractBefore(string(ms_res.Mx_csv.fn), "."));
            end
            if strcmp(ms_res.simu_mode,"Rotational")
                log_out = setdiff(obj.general_setting.log_select,[1,2,5,6,7]);
                mode_suffix = "Rot";
            else
                log_out = obj.general_setting.log_select;
                mode_suffix = "Lunch";
            end

            wpsi_tok = Calculation2.angle_token('Wpsi', ms_res.Wpsi);
            if isempty(stage_idx)
                ns_tok = "NsX";
            else
                ns_tok = strcat("Ns", num2str(stage_idx));
            end

            cond_suffix = strcat(wpsi_tok, "_", ns_tok, "_", roll_str, "_", mode_suffix);

            subdir = Calculation2.timelog_subdir(ms_res);

            log_fn_name = strcat("log_",     cond_suffix, ".xlsx");
            ctl_fn_name = strcat("control_", cond_suffix, ".xlsx");
            ble_fn_name = strcat("blender_", cond_suffix, ".csv");

            [dir_fn, dir_tmp, obj] = make_outputfile(obj, 'log', log_fn_name, subdir);

            str = split(obj.general_setting.log_ind,'(');
            log_names = str(:,1);
            log_nums = extractBefore(str(:,2),',');
            ts = ms_res.ts';
            % ランチクリア時刻（第二ラグ離脱時刻）。0 以下なら未到達として扱う。
            if ~isempty(ms_res.t_lc) && size(ms_res.t_lc,2) >= 2 && ms_res.t_lc(1,2) > 0
                t_lc_mask = ms_res.t_lc(1,2);
            else
                t_lc_mask = [];
            end
            for k = 1:size(obj.general_setting.log_list,1)
                if ismember(k,log_out)
                    sheet_name = obj.general_setting.log_list(k,:);
                    if contains(log_nums(k,1),":")
                        log_num = str2double(split(log_nums(k,1),':'));
                        log_data = ms_res.(log_names{k,:})(log_num(1,1):log_num(2,1),:);
                        log_data = log_data';
                    else
                        log_num = str2double(log_nums(k,1));
                        log_data = ms_res.(log_names{k,:})(log_num,:);
                        log_data = log_data';
                    end
                    % alpha,beta シート: ランチクリア前は迎角・横滑り角を 0 にする
                    % （ランチャ拘束中は空力的に意味を持たないため）
                    if strcmpi(string(sheet_name), "alpha,beta") && ~isempty(t_lc_mask)
                        log_data(ts < t_lc_mask, :) = 0;
                    end
                    writematrix([ts,log_data],dir_fn,...
                                'Sheet',sheet_name,'Range','A2');
                end
            end

            % --- Xe シート E 列: 射点間距離（射点からの水平距離, 高度を含めない）[m] ---
            % E1 ラベルはテンプレ側で記入済みのため、E2 以降にデータのみ書き込む。
            % Xe(=log_list(1)) が出力対象（log_out に 1 を含む）のときのみ追記する。
            if ismember(1, log_out)
                horiz_dist = vecnorm(ms_res.xs(1:2,:), 2, 1)';   % 各時刻の射点からの水平距離
                writematrix(horiz_dist, dir_fn, ...
                            'Sheet', obj.general_setting.log_list(1,:), 'Range', 'E2');
            end

            % --- extra シート / 審査書用 シート ---
            obj.write_extra_and_summary(ms_res, dir_fn, ts);

            obj.log_file_count = obj.log_file_count + 1;

            t_Ble = 0:0.01:ms_res.t_max;
            if ~isempty(t_Ble), t_Ble(end) = []; end
            q_Ble = interp1(ms_res.ts', ms_res.xs(7:10,:)',t_Ble','linear');
            Xe_Ble = interp1(ms_res.ts', ms_res.xs(1:3,:)',t_Ble','linear');
            all_Ble = [1:size(t_Ble,2);q_Ble';Xe_Ble'];
            writematrix(all_Ble, fullfile(dir_tmp, ble_fn_name));
            obj.log_file_count = obj.log_file_count + 1;

            [dir_fn, ~, obj] = make_outputfile(obj, 'control', ctl_fn_name, subdir);
            obj.log_file_count = obj.log_file_count + 1;

            if isprop(ms_res.rc, "para")
                writecell(fieldnames(ms_res.rc.para), dir_fn, 'Range', 'A2', 'Sheet', 'para')
                writecell(struct2cell(ms_res.rc.para), dir_fn,'Range', 'B2', 'Sheet', 'para')
            end
            if isprop(ms_res.rc, "log")
                names = (fieldnames(ms_res.rc.log))';
                names(:,end) = [];
                names = [names,'p','i','d'];
                writematrix("t[s]", dir_fn, 'Range', 'A1', 'Sheet', 'log')
                writematrix(ms_res.ts', dir_fn, 'Range', 'A2', 'Sheet', 'log')
                writecell(names, dir_fn, 'Range', 'B1', 'Sheet', 'log')
                writematrix((cell2mat(struct2cell(ms_res.rc.log)))', dir_fn, 'Range', 'B2', 'Sheet', 'log')
            end
            if isprop(ms_res.rc, "m_log")
                writematrix("t[s]", dir_fn, 'Range', 'A1', 'Sheet', 'm_log')
                writematrix(ms_res.ts', dir_fn, 'Range', 'A2', 'Sheet', 'm_log')
                writecell((fieldnames(ms_res.rc.m_log))', dir_fn, 'Range', 'B1', 'Sheet', 'm_log')
                writematrix((cell2mat(struct2cell(ms_res.rc.m_log)))', dir_fn, 'Range', 'B2', 'Sheet', 'm_log')
            end

        end

        function write_extra_and_summary(obj, ms_res, log_fn, ts_col)
            % Format_Log.xlsx の "extra" / "審査書用" シートへ書き込む。
            % extra:    A=t[s], B=Fst[%], C=動圧[kPa]
            % 審査書用: A=項目名(テンプレに固定記入済) B=Value, C=Time
            % あわせて alpha,beta シート D 列に AoA[deg] (=rad2deg(alpha)) を追記。
            % D1 ラベルはテンプレ側で記入済みのためデータのみ書き込む。
            ys = ms_res.ys;
            xs = ms_res.xs;
            ts_row = ms_res.ts;          % 1 x N

            % Fst / dp は MainSolver で y(25)/y(26) に追加済み
            if size(ys,1) >= 26
                Fst_tr = ys(25,:);
                dp_tr  = ys(26,:);
            else
                Fst_tr = nan(1, numel(ts_row));
                dp_tr  = nan(1, numel(ts_row));
            end
            % AoA はピッチ面迎角 alpha = atan2(Va_z, Va_x)（rad, 符号付き）
            aoa_tr = ys(8,:);
            % ランチクリア前は迎角を 0 にする（alpha,beta シート B/C 列の処理と整合）。
            % これにより 審査書用 の max/min alpha・対応高度も拘束区間を除外できる。
            if ~isempty(ms_res.t_lc) && size(ms_res.t_lc,2) >= 2 && ms_res.t_lc(1,2) > 0
                aoa_tr(ts_row < ms_res.t_lc(1,2)) = 0;
            end

            % --- extra シート ---
            writematrix([ts_col, Fst_tr', dp_tr'], log_fn, ...
                        'Sheet', 'extra', 'Range', 'A2');

            % --- alpha,beta シート D 列: AoA[deg] ---
            writematrix(rad2deg(aoa_tr)', log_fn, ...
                        'Sheet', 'alpha,beta', 'Range', 'D2');

            % --- 審査書用 代表値 ---
            z           = xs(3,:);
            Van         = ys(7,:);
            Ab_norm     = vecnorm(ys(1:3,:), 2, 1);      % 機体軸加速度の大きさ

            % 上昇区間（射出 ～ 頂点到達）のインデックス範囲
            % Hard モード等で着地時に Van/dp が再増加するのを max 探索から除外する。
            [z_max_v, iZ] = max(z);
            iTop = iZ;
            if isprop(ms_res, 't_top') && ~isempty(ms_res.t_top) && ms_res.t_top > 0
                iTop_t = find(ts_row <= ms_res.t_top, 1, 'last');
                if ~isempty(iTop_t)
                    iTop = max(iTop, iTop_t);
                end
            end
            up = 1:iTop;

            [Accel_max,  iAcc]  = max(Ab_norm(up));
            [Van_max_v,  iVan]  = max(Van(up));
            [dp_max_v,   iDp]   = max(dp_tr(up));
            % 「迎角」はピッチ面 alpha（符号付き）で評価
            [a_max_rad,  iAmax] = max(aoa_tr(up));
            [a_min_rad,  iAmin] = min(aoa_tr(up));
            [Fst_max_v,  iFmax] = max(Fst_tr(up));
            [Fst_min_v,  iFmin] = min(Fst_tr(up));

            % 着地点（射点原点系）と緯経度
            xe_end    = xs(1:2, end);
            fall_dist = norm(xe_end);
            t_end     = ts_row(end);

            gs = obj.general_setting;
            if isprop(gs,'ll') && ~isempty(gs.ll)
                [x_geo, ~] = gs.ll.Vincenty_direct([xe_end(1), xe_end(2)]);
                fall_lat = x_geo(1,1);
                fall_lon = x_geo(1,2);
            else
                fall_lat = NaN;
                fall_lon = NaN;
            end

            % ランチクリア時刻: t_lc(1,2) に格納（MainSolver.m:1119）
            if ~isempty(ms_res.t_lc) && size(ms_res.t_lc,2) >= 2 && ms_res.t_lc(1,2) > 0
                t_lc = ms_res.t_lc(1,2);
                [~, iLc] = min(abs(ts_row - t_lc));
                z_lc = z(iLc);
            else
                t_lc = NaN;
                z_lc = NaN;
            end

            % テンプレ A 列の順序に合わせて B,C を組み立てる
            vals = [ ms_res.Vn_lc,        t_lc;
                     z_lc,                t_lc;
                     Accel_max,           ts_row(iAcc);
                     Van_max_v,           ts_row(iVan);
                     dp_max_v,            ts_row(iDp);
                     z_max_v,             ts_row(iZ);
                     rad2deg(a_max_rad),  ts_row(iAmax);
                     rad2deg(a_min_rad),  ts_row(iAmin);
                     fall_dist,           t_end;
                     z(iAcc),             ts_row(iAcc);
                     z(iVan),             ts_row(iVan);
                     z(iDp),              ts_row(iDp);
                     Van(iZ),             ts_row(iZ);
                     z(iAmax),            ts_row(iAmax);
                     z(iAmin),            ts_row(iAmin);
                     Fst_max_v,           ts_row(iFmax);
                     Fst_min_v,           ts_row(iFmin);
                     fall_lat,            t_end;
                     fall_lon,            t_end ];

            writematrix(vals, log_fn, 'Sheet', '審査書用', 'Range', 'B2');
        end

        function tbl = featureTable(obj)
            % モード×段×条件で特徴値を集約した table を返す。
            % xs が空（計算中断 or 未計算）の条件はスキップ。
            gs = obj.general_setting;
            has_ll = isprop(gs,'ll') && ~isempty(gs.ll);

            rows = {};
            modes = fieldnames(obj.res);
            for iMode = 1:numel(modes)
                cur_mode = modes{iMode};
                res_mode = obj.res.(cur_mode);
                [ne, nv, nw, np] = size(res_mode);
                for jElev = 1:ne
                    for jV = 1:nv
                        for jPsi = 1:nw
                            for iStage = 1:np
                                ms_res = res_mode(jElev, jV, jPsi, iStage);
                                if isempty(ms_res.xs), continue; end

                                xe_end = ms_res.xs(1:2, end);
                                fall_E = xe_end(1);
                                fall_N = xe_end(2);
                                fall_dist = norm(xe_end);

                                if has_ll
                                    [x_geo, ~] = gs.ll.Vincenty_direct([fall_E, fall_N]);
                                    fall_lat = x_geo(1,1);
                                    fall_lon = x_geo(1,2);
                                else
                                    fall_lat = NaN;
                                    fall_lon = NaN;
                                end

                                rows(end+1, :) = { ...
                                    string(cur_mode), iStage, ...
                                    ms_res.elev, ms_res.Vw0, ms_res.Wpsi, ...
                                    ms_res.z_max, ms_res.Vn_lc, ms_res.Van_max, ms_res.Mach_max, ...
                                    ms_res.t_top, ms_res.Van_top, ms_res.Va_para, ...
                                    rad2deg(ms_res.alpha_max), rad2deg(ms_res.beta_max), ...
                                    ms_res.AngleAccel_max, ...
                                    fall_dist, fall_E, fall_N, fall_lat, fall_lon ...
                                }; %#ok<AGROW>
                            end
                        end
                    end
                end
            end

            varNames = { ...
                'Mode','Stage','Elev_deg','Vw0_mps','Wpsi_deg', ...
                'z_max_m','Vn_lc_mps','Van_max_mps','Mach_max', ...
                't_top_s','Van_top_mps','Va_para_mps', ...
                'alpha_max_deg','beta_max_deg','AngleAccel_max', ...
                'FallDist_m','FallE_m','FallN_m','FallLat_deg','FallLon_deg' };

            if isempty(rows)
                tbl = cell2table(cell(0, numel(varNames)), 'VariableNames', varNames);
            else
                tbl = cell2table(rows, 'VariableNames', varNames);
            end
        end

        function exportFeatureTable(obj, tbl)
            % gs.output が "FeatureValues" or "vs-time_Logs" の場合のみ
            % 出力先フォルダ（cc.output_dir）に FeatureValues.xlsx + .csv を書き出す。
            % .csv はスクリプト処理向けに英識別子ヘッダで併出力する（§3-2）。
            if isempty(tbl) || height(tbl) == 0, return; end
            out_set = string(obj.general_setting.output);
            export_modes = ["FeatureValues", "vs-time_Logs"];
            if ~any(out_set == export_modes), return; end

            if isempty(obj.output_dir) || ~isfolder(obj.output_dir)
                warning('exportFeatureTable: output_dir is not available, skipping export.');
                return
            end
            out_xlsx = fullfile(obj.output_dir, 'FeatureValues.xlsx');
            out_csv  = fullfile(obj.output_dir, 'FeatureValues.csv');
            try
                writetable(tbl, out_xlsx);
                disp(strcat("FeatureValues exported: ", out_xlsx));
            catch ME
                warning(ME.identifier, 'FeatureValues xlsx export failed: %s', ME.message);
            end
            try
                writetable(tbl, out_csv);
                disp(strcat("FeatureValues exported: ", out_csv));
            catch ME
                warning(ME.identifier, 'FeatureValues csv export failed: %s', ME.message);
            end
        end

        function obj = record_logs_for_Vw0(obj, res_4d, jElev, jV, Wn, pn)
            % §2.2: Vw0 1 条件分（全 Wpsi × 全段）の解析が完了した直後に呼び、
            % その Vw0 配下のログを出力する。parfor の外（逐次区間）で呼ぶこと。
            if ~ismember("vs-time_Logs", string(obj.general_setting.output))
                return;
            end
            n_written = 0;
            n_skip    = 0;
            for jPsi = 1:Wn
                for jParam = 1:pn
                    [obj, was_skipped] = obj.record_log( ...
                        res_4d(jElev, jV, jPsi, jParam), jParam);
                    if was_skipped
                        n_skip = n_skip + 1;
                    else
                        n_written = n_written + 1;
                    end
                end
            end
            elev_val = obj.general_setting.elev(jElev);
            vw_val   = obj.general_setting.Vw0(jV);
            fprintf('  -> vs-time logs written: elev=%g deg, Vw0=%g m/s (ok=%d, skipped=%d)\n', ...
                    elev_val, vw_val, n_written, n_skip);
        end

        function cond_label = cond_label_for_skip(obj, ms_res, stage_idx)
            % スキップ条件のラベルを統一形式で組み立てる。
            if isempty(stage_idx), ns_str = "?"; else, ns_str = string(stage_idx); end
            mode = string(ms_res.mode_landing);
            if strlength(mode) == 0, mode = "-"; end
            cond_label = sprintf('Mode=%s, elev=%g, Vw0=%g, Wpsi=%g, Ns=%s', ...
                mode, ms_res.elev, ms_res.Vw0, ms_res.Wpsi, ns_str);
        end

        function obj = collect_unrecorded_skips(obj)
            % vs-time_Logs オフの場合は record_log が呼ばれずスキップ検出が走らない。
            % 計算完了後に res 全体を走査して xs 空の条件を skipped_conditions に蓄積する。
            % べき法則風 + Vw0=0 では jW>=2 が意図的に空のため、これは skip 集計から除外する。
            already = obj.skipped_conditions;
            modes = fieldnames(obj.res);
            wm = string(obj.general_setting.wind_model);
            for iMode = 1:numel(modes)
                cur_mode = modes{iMode};
                res_mode = obj.res.(cur_mode);
                [ne, nv, nw, np] = size(res_mode);
                for jE = 1:ne
                    for jV = 1:nv
                        is_zero_wind = (wm == "PowerLaw") && ...
                            (obj.general_setting.Vw0(jV) == 0);
                        for jW = 1:nw
                            if is_zero_wind && jW >= 2
                                continue;   % 意図的に未計算のスロット
                            end
                            for jP = 1:np
                                ms_res = res_mode(jE, jV, jW, jP);
                                if isempty(ms_res.xs)
                                    lbl = obj.cond_label_for_skip(ms_res, jP);
                                    if ~any(strcmp(string(lbl), already))
                                        obj.skipped_conditions(end+1,1) = string(lbl);
                                        already(end+1,1) = string(lbl); %#ok<AGROW>
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        function write_run_info(obj)
            % §3-1: 実行条件サマリを paramN 直下に run_info.txt として出力。
            % §3-7: skipped_conditions も併記する。
            if isempty(obj.output_dir) || ~isfolder(obj.output_dir), return; end
            gs = obj.general_setting;
            fn = fullfile(obj.output_dir, 'run_info.txt');

            try
                fid = fopen(fn, 'w');
                if fid < 0
                    warning('write_run_info: cannot open %s', fn);
                    return;
                end
                cleaner = onCleanup(@() fclose(fid));

                fprintf(fid, 'Spica run summary\n');
                fprintf(fid, '=================\n');
                fprintf(fid, 'Generated      : %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
                fprintf(fid, 'Output dir     : %s\n', obj.output_dir);
                if isprop(gs,'execute_cont') && gs.execute_cont
                    fprintf(fid, 'Control func   : %s\n', char(string(gs.control_func)));
                else
                    fprintf(fid, 'Control func   : (uncontrolled)\n');
                end
                if isprop(gs,'param') && isstruct(gs.param) && isfield(gs.param, 'fn')
                    fprintf(fid, 'Parameter file : %s\n', char(strjoin(string(gs.param.fn), '; ')));
                end
                if isprop(gs,'thrust') && isstruct(gs.thrust) && isfield(gs.thrust, 'fn')
                    fprintf(fid, 'Thrust file    : %s\n', char(string(gs.thrust.fn)));
                end
                fprintf(fid, 'Landing mode   : %s\n', char(string(gs.mode_landing)));
                fprintf(fid, 'Wind model     : %s\n', char(string(gs.wind_model)));
                fprintf(fid, 'Parallel       : %s\n', char(string(gs.parallel)));
                if isprop(gs,'dt'), fprintf(fid, 'dt             : %g\n', gs.dt); end

                fprintf(fid, '\n[Sweep ranges]\n');
                fprintf(fid, '  elev [deg] : %s\n', Calculation2.fmt_vec(gs.elev));
                fprintf(fid, '  Vw0  [m/s] : %s\n', Calculation2.fmt_vec(gs.Vw0));
                fprintf(fid, '  Wpsi [deg] : %s\n', Calculation2.fmt_vec(gs.Wpsi));
                fprintf(fid, '  param_n    : %d\n', gs.param_n);

                fprintf(fid, '\n[Output]\n');
                fprintf(fid, '  output flag       : %s\n', char(strjoin(string(gs.output), ', ')));
                fprintf(fid, '  log files written : %d\n', obj.log_file_count);

                fprintf(fid, '\n[Skipped conditions] (xs/ys empty etc.)\n');
                if isempty(obj.skipped_conditions)
                    fprintf(fid, '  (none)\n');
                else
                    for k = 1:numel(obj.skipped_conditions)
                        fprintf(fid, '  - %s\n', char(obj.skipped_conditions(k)));
                    end
                end
            catch ME
                warning(ME.identifier, 'write_run_info failed: %s', ME.message);
            end
        end
    end

    methods (Static)
        function tok = num_token(v)
            % 数値をファイル名に安全な文字列に整形する。
            % 負号 '-' -> 'm', 小数点 '.' -> 'p'。NaN は 'NaN'。
            if isnan(v), tok = "NaN"; return; end
            s = num2str(v, '%g');
            s = strrep(s, '-', 'm');
            s = strrep(s, '.', 'p');
            tok = string(s);
        end

        function tok = angle_token(prefix, v)
            % 例: angle_token("Wpsi", -2.5) -> "Wpsim2p5deg"
            tok = strcat(string(prefix), Calculation2.num_token(v), "deg");
        end

        function tok = vw_token(v)
            % 例: vw_token(5.0) -> "Vw05ms"
            tok = strcat("Vw0", Calculation2.num_token(v), "ms");
        end

        function tok = elev_token(v)
            tok = strcat("elev", Calculation2.num_token(v), "deg");
        end

        function sub = timelog_subdir(ms_res)
            % <Mode>/TimeLog/elev<E>deg/Vw0<V>ms を返す。
            mode = char(string(ms_res.mode_landing));
            if isempty(mode), mode = 'Default'; end
            sub = fullfile(mode, 'TimeLog', ...
                char(Calculation2.elev_token(ms_res.elev)), ...
                char(Calculation2.vw_token(ms_res.Vw0)));
        end

        function s = fmt_vec(v)
            % ベクトル / 配列を簡潔な範囲表記の文字列に変換する。
            if isempty(v)
                s = '(empty)'; return;
            end
            v = v(:)';
            if numel(v) == 1
                s = num2str(v, '%g');
            elseif numel(v) <= 6
                s = strjoin(arrayfun(@(x) num2str(x,'%g'), v, 'UniformOutput', false), ', ');
            else
                s = sprintf('%g..%g (n=%d, step=%g)', v(1), v(end), numel(v), v(2)-v(1));
            end
        end

        function result = run_one_condition(ms_array, gs, num_elev, num_Vw, num_Wpsi)
            % 1 条件（射角・風速・風向）で、全段を通して計算する静的関数。
            % 入出力は obj から切り離しているため、parfor から安全に呼び出せる。

            pn = gs.param_n;
            result = repmat(ms_array(1), 1, pn);  % MainSolver 配列で初期化
            for iStage = 1:min(pn, numel(ms_array))
                result(iStage) = ms_array(iStage);  % 各段の物理パラメータを保持
            end

            ms_on = isprop(gs,'multi_stage') && logical(gs.multi_stage);

            for iStage = 1:pn
                % 条件の初期値設定
                result(iStage).elev = gs.elev(num_elev);
                result(iStage).Vw0  = gs.Vw0(num_Vw);
                result(iStage).Wpsi = gs.Wpsi(num_Wpsi);

                % 前段の情報から続きの初期値
                if iStage > 1
                    % multi_stage(2段式) では stage2, stage3 とも stage1 の分離状態を継承
                    % （stage2=分離上部, stage3=分離下部）
                    if ms_on
                        before = result(1);
                    else
                        before = result(iStage-1);
                    end
                    if isprop(before,'sep_st') && (before.sep_st == 2)
                        idx = max(1, min(round(before.t_sep * before.freq), size(before.xs, 2)));
                        X0  = [before.xs(1:13, idx); before.t_sep];
                    else
                        if ms_on
                            warning('Stage 1 was NOT separated (sep_st ~= 2). Using zero initial state for stage %d.', iStage);
                        end
                        X0 = zeros(14,1);
                    end
                else
                    X0 = zeros(14,1);
                end

                % 段のシミュレーションを実行
                result(iStage) = result(iStage).simulation(X0);
            end
        end
    end
end
