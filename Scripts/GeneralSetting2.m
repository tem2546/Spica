% Spica_rollcontrol3.0
% edit by sano taisei 

% for Spica_rollcontrol3.1

classdef GeneralSetting2
    %GENERAL_SETTING2 条件設定用クラス
    %
    properties
        %-----directory----- 
        dir = struct(...
            'home',"",...           %ホームディレクトリ(Spicaフォルダ)
            'data',"",...
            'res',"",...            %Resultフォルダ
            'scr',"",...            %Scriptフォルダ
            'setting', "",...       %CurrentSettingフォルダ（UI⇔MATLABの作業用settings.json）
            'preset', "",...        %PreSettingsフォルダ（端末ローカルの前回設定スナップショット）
            'UI', "",...            %GeneralSettingUIフォルダ
            'form',"",...           %Formatsフォルダ
            'param',"",...          %ParameterFilesフォルダ
            'thrust',"");           %ThrustDataフォルダ
                    
        %-----model setting-----
        param = struct('fn',"",...  %諸元表ファイル名（multi_stage=true の時は [1段目; 2段目分離上部; 2段目分離下部] の3要素文字列配列）
                       'path',"");  %諸元表インデックス（同上）
        thrust = struct('fn',"",... %推力履歴ファイル名
                       'path',"");  %推力履歴インデックス
        multi_stage = false;        %多段式シミュレーションフラグ（true=2段式, false=単段）
        param_n = 1;                %全段数（multi_stage=true では 3 に自動設定：stage1 / 2段目分離上部 / 2段目分離下部）
        descent_model = 'Vw_model'; %減速降下モデル    Vw_model, Dynamics
        
        %-----condition setting------
        
        base_azm = 'ME';            %基準方位 M:Magnetic T:True, E:East N:North ...
        mode_angle = 'CCW';         %方位角の正方向 CW:ClockWise, CCW:CounterClockWise
        view_azm = 'Magnetic';      %落下分散図の基準方位種類   
        elev = [80, 80, 1];   % 射角 [min max step]
        Vw0  = [1, 1, 1];     % 風速 [min max step]
        Wpsi = [0, 0, 1];     % 風向 [min max step] TN=0deg CW
        % シリアライズ用：UI から受け取った元の [min max step] を保持する
        % （expandConditions により elev/Vw0/Wpsi 自体は展開後の配列に上書きされるため、
        %   PreSettings/settings.json に保存するときの形式維持に使う）
        elev_set = [80, 80, 1];
        Vw0_set  = [1, 1, 1];
        Wpsi_set = [0, 0, 1];
        wind_model = 'PowerLaw';     %風向風速モデル PowerLaw or MSM or csv
        MSM = struct('fn',"",...     %msmファイル名
                     'path',"");     %msmインデックス
        wind_csv = struct(...
            'fn',"",...              %風速csvファイル名
            'path',"");             %風速csvファイル名
        t_max = 60;                  %シミュレーション最大時間
        dt = 1/1000;                 %シミュレーションレート
        mode_landing = 'Hard';           %
        elev_n = 0;                 %射角条件数
        Vw0_n = 0;                  %風速条件数
        Wpsi_n = 0;                 %風向条件数
        fp = struct('fn', "",...
                    'path', "");
        
        %-----roll control setting-----
        execute_cont = true;
        control_func = "example";
        simu_mode = "Launch";         %"Launch" : 打ち上げ　"Rotational" :　速度一定姿勢のみ
        rot_cond = struct(...
            "Va",50,...              %
            "z",200);                %
        roll_factor = "Coefficience";% "Coefficience":ロール空力係数 or "Moment":時間経過ローリングモーメントcsv
        Cl0 = 0.001;
        Mx_csv = struct("fn","",...
                        "path","");
        % 動翼空力データベース（aero DB）
        %   use=true のとき、files のうち use=true のもの（2個以上）を「解析流速 v」軸として
        %   MainSolver が α-δ-V の 3D テーブルとして補間に使用する。use=false で従来の諸元表方式。
        aero_db = struct('use', false, ...
                         'files', struct('use',  {false, false, false, false, false}, ...
                                         'v',    {0, 0, 0, 0, 0}, ...
                                         'fn',   {"", "", "", "", ""}, ...
                                         'path', {"", "", "", "", ""}));

        % パーツ別空力寄与モード（Method B）
        %   use=true のとき、MainSolver が Excel(Components シート)から各部品の
        %   CN_a/X_cp/取付角/可動フラグを読み、ピッチ/ヨーを部品ごとに計算する。
        %   fix_delta=true で固定舵角 delta_fixed[deg] を動翼に印加（制御関数とは独立・重畳可）。
        %   use=false で従来 lumped 方式。
        comp_aero = struct('use', false, 'fix_delta', false, 'fn', "", 'path', "", 'delta_fixed', 0);

        %-----option-----
        ll = [];                        %経緯度変換用クラス(lon_latクラス)
        Ab_log = 'No';                  %ランチクリア前後の加速度ログの出力機能
        t_Ab_log = 0;                   %加速度ログの記録時間
        parallel= 'No';                 %CPU並列計算機能
        mgd = 0;                        %磁気偏角（西偏=正）
        
        %----output setting ------
        mode_export = 'Default';    %結果ファイルの出力先設定
        output = "";
        result_path = ""
        log_str = ["Xe:重心座標@地上座標系";"Ve:重心速度@地上座標系";"q:クォータニオン";...
                   "omega:角速度@機体座標系";"Ab:重心加速度@機体座標系";"Va:対気速度@機体座標系";
                   "Van;対気速度";"alpha,beta:迎え角横滑り角";"delta_a:舵角"]
        log_list = ["Xe";"Ve";"q";"omega";"Ab";"Va";"Van";"alpha,beta";"delta_a"];
        log_ind = ["xs(1:3,:)";"xs(4:6,:)";"xs(7:10,:)";"xs(11:13,:)";"ys(1:3,:)";"ys(4:6,:)";
                   "ys(7,:)";"ys(8:9,:)";"ys(23,:)"];
        log_select = 1:9;
        feat = ["Vn_lc";"Van_max";"Mach_max";"z_max";
                "Van_top";"t_top";"Va_para";"alpha_max";"beta_max";"AngleAccel_max"];

        %-----display-----
        fig_size = struct(...
            'path',[100, 50, 800, 700],...
            'point',[100, 50, 800, 700]);   %図のサイズ
        ax = struct(...
            'path',struct(...
                'range', [-840, 880, -910, 750],...
                'label', ["Magnetic East [m]";"Magnetic North [m]";"Altitude [m]"],...
                'FontSize', 10,...
                'Color', [0, 0, 0],...
                'FontWeight', 'normal'),...
            'point',struct(...
                'range', [-840, 880, -910, 750],...
                'label', ["Magnetic East[m]";"Magnetic North[m]"],...
                'FontSize', 10,...
                'Color', [0, 0, 0],...
                'FontWeight', 'normal'));   %軸関連
        lgd = struct(...
            'path', struct(...
                'pos', [0.8, 0.8, 0.1 ,0.1],...
                'FontSize', 10,...
                'TextColor', [1, 0.9999, 0.9999],...
                'FontWeight', 'bold'),...
            'point', struct(...
                'pos', [0.8, 0.8, 0.1 ,0.1],...
                'FontSize', 10,...
                'TextColor', [1, 0.9999, 0.9999],...
                'FontWeight', 'bold'));     %凡例関連
        kml = struct(...
                'Width',15,...
                'Color', [1 1 1]);         %GoogleEarth用kmlファイル関連
        
        %fallpoint
        back_pict = struct(...
            'fn', 'Oshima_201903.jpg',...
            'img', [],...
            'pos', [-830, 870; -907, 750]); %背景図関連
        marker = struct(...
            'color', [1, 1, 1; 1, 0, 0],...
            'size', 20,...
            'shape', "o",...
            'mfc', 'flat');                 %マーカー関連（風速ごとに色グラデーション）

        list_fig = string.empty(0,1);   %出力する図のリスト（チェックボックス選択）


        %-----MATLAB Addons-----
        add_list = "";              %インストール済みのアドオンリスト

        end_flag = 0; %設定変更時に「キャンセル」された場合のフラグ
        
        
    end
    
    methods
        function obj = GeneralSetting2(varargin)     %コンストラクタメソッド　ディレクトリ初期化のみ
            % 前回設定の自動ロードは行わない（UIの「前回設定を読み込み」ボタン経由のみ）
            obj = obj.path_init();

            %インストール済みのアドオンを取得
            add = matlab.addons.installedAddons;
            obj.add_list = add.Name;
            if ismember("Parallel Computing Toolbox",obj.add_list)==0
                warning("CANNOT use Parallel Computing! \n (MATLAB Addon ""Parallel Computing Toolbox"" is NOT installed.)")
                obj.parallel = 'No';
            end

            obj = obj.applyDefaultSettings(); % 初期値適用
        end
        
        function obj = path_init(obj)       %ファイルパス初期化関数
            disp('File paths are Initialized...')
            %各フォルダの場所を指定
            obj.dir.scr = pwd;
            cd('../');
            home = pwd;
            obj.dir.home = home;
            obj.dir.data = strcat(home,"/Data"); 
            obj.dir.res = strcat(home,"/Result");
            obj.dir.form= strcat(home,"/Formats");
            obj.dir.param = strcat(home,"/ParameterFiles");
            obj.dir.thrust = strcat(home,"/ThrustData");
            obj.dir.launch = strcat(home,"/LaunchSite");
            obj.dir.UI = fullfile(obj.dir.scr, "GeneralSettingUI");
            obj.dir.setting = fullfile(obj.dir.scr, 'CurrentSetting');
            obj.dir.preset  = fullfile(obj.dir.scr, 'PreSettings');
            obj.result_path = obj.dir.res;
            cd(obj.dir.scr)
        end
       
        function obj = setting(obj)   %設定変更

            jsonFile = fullfile(obj.dir.setting, 'settings.json');
            %　設定用フォルダがなければ作成
            if ~isfolder(obj.dir.setting)
                mkdir(obj.dir.setting);
            end
            % PreSettingsフォルダ（端末ローカル用）も用意
            if ~isfolder(obj.dir.preset)
                mkdir(obj.dir.preset);
            end

            %settings.json（共有用ベース）の有無を確認
            if ~isfile(jsonFile)
                % 初期設定（パス空）を書き込む
                obj.makeJsonFile(jsonFile);
                disp('Settings JSON file is created.');
            else
                disp('Settings JSON file is found.');
            end

            % PreSettings.json（端末ローカル）の有無を確認、無ければ初期値で作成
            preFile = fullfile(obj.dir.preset, 'PreSettings.json');
            if ~isfile(preFile)
                obj.makeJsonFile(preFile);
                disp('PreSettings JSON file is created.');
            end

            % 2) UI EXE のパス
            exePath = fullfile(obj.dir.UI, 'dist', 'GeneralSettingUI.exe');  % GeneralSettingUI配下に dist/
            cmd = sprintf('"%s" --settings-dir "%s" --presettings-file "%s"', ...
                          exePath, obj.dir.setting, preFile);

            % 3) UI 起動（同期）
            disp('Launching General Setting UI...');
            if ispc
                % 同期で待つ（UIが閉じるまで）
                status = system(cmd);
                if status ~= 0
                    warning('UI 起動に失敗しました（終了コード: %d）。', status);
                end
            else
                warning('This UI launching method is only supported on Windows.');
            end

            disp('General Setting UI has been closed.');
            
            jsonFile = fullfile(obj.dir.setting, 'settings.json');

            % JSON 読み込み（存在チェック＋安全な読込）
            try
                fid = fopen(jsonFile,'r');
                if fid == -1
                    warning('settings.json が見つかりません。現状の設定を保持します。');
                    return
                end
                raw = fread(fid, inf, '*char')';
                fclose(fid);
                S = jsondecode(raw);   % 一旦 MATLAB 構造体で読み取る
            catch ME
                warning(ME.identifier, "settings.json の読み取りに失敗: %s", ME.message);
                return
            end

            % ウィンドウが「×」で閉じられたかを判定
            if isfield(S,'closed_by_x') && islogical(S.closed_by_x) && S.closed_by_x
                warning('Setting window is closed by "×". Settings change will be cancelled.');
                obj.end_flag = 1;
                return;
            end

            % デフォルト選択（cancelled:true の場合は既定で「いいえ（保持）」に寄せる）
            defaultOpt = 'はい(適用)';
            if isfield(S,'cancelled') && islogical(S.cancelled) && S.cancelled
                defaultOpt = 'いいえ(保持)';
            end
            
            resp = questdlg( ...
                'シミュレーションを実行しますか？', ...   % 質問
                '実行の確認', ...                           % タイトル
                '実行', 'キャンセル', ... % ボタン
                defaultOpt ...                              % 既定のボタン
            );

            switch resp
                case '実行'
                    % 反映
                    obj = obj.readJsonFile(jsonFile);
                    obj = obj.applyDefaultModelPaths();
                    obj = obj.loadFallPointBundle();
                    obj = obj.applyMultiStage();
                    disp('JSON settings loaded into object.');
                    % 端末ローカルの前回設定（パス込み）を保存
                    obj.writePreSettings(preFile);
                otherwise  % キャンセルや閉じる×
                    obj.end_flag = 1;
                    disp('Settings change cancelled.');
            end

            obj = obj.deleteFilePaths(jsonFile);  % 共有用 settings.json のファイルパスを空に戻す
            return;
        end

        function obj = applyDefaultSettings(obj) % 初期値明示適用メソッド
            
            obj.elev = [80, 80, 1];
            obj.Vw0  = [1, 1, 1];
            obj.Wpsi = [0, 0, 1];
            obj.elev_set = obj.elev;
            obj.Vw0_set  = obj.Vw0;
            obj.Wpsi_set = obj.Wpsi;
            obj.wind_model   = 'PowerLaw';
            obj.mode_landing = 'Hard';
            obj.base_azm     = 'MN';
            obj.mode_angle   = 'CCW';
            obj.t_max        = 60;
            obj.dt           = 1/1000;

            obj.descent_model = 'Vw_model';

            obj = obj.expandConditions();
        end

        function makeJsonFile(obj, jsonFile)
            %初期設定の書き込み
            defaultSettings = struct(...
                'multi_stage', obj.multi_stage, ...
                'param', struct('fn', obj.param.fn, 'path', ""), ...
                'thrust', struct('fn', obj.thrust.fn, 'path', ""), ...
                'descent_model', obj.descent_model, ...
                'elev', obj.elev_set, ...
                'Vw0',  obj.Vw0_set, ...
                'Wpsi', obj.Wpsi_set, ...
                't_max', obj.t_max, ...
                'base_azm', obj.base_azm, ...
                'mode_angle', obj.mode_angle, ...
                'dt', obj.dt, ...
                'mode_landing', obj.mode_landing, ...
                'execute_cont', obj.execute_cont, ...
                'control_func', obj.control_func, ...
                'simu_mode', obj.simu_mode, ...
                'rot_cond', obj.rot_cond, ...
                'roll_factor', obj.roll_factor, ...
                'Cl0', obj.Cl0, ...
                'parallel', obj.parallel, ...
                'mgd', obj.mgd, ...
                'mode_export', obj.mode_export, ...
                'result_path', obj.result_path, ...
                'output', obj.output, ...
                'list_fig', obj.list_fig, ...
                'MSM', struct('fn', "", 'path', ""), ...
                'wind_csv', struct('fn', "", 'path', ""), ...
                'fp', struct('fn', "", 'path', ""), ...
                'Mx_csv', struct('fn', "", 'path', ""), ...
                'aero_db', GeneralSetting2.emptyAeroDb(), ...
                'comp_aero', GeneralSetting2.emptyCompAero() ...
            );

            fid = fopen(jsonFile, 'w');
            if fid == -1
                error('Cannot create JSON file: %s', jsonFile);
            end
            fwrite(fid, jsonencode(defaultSettings), 'char');
            fclose(fid);
        end

        function obj = readJsonFile(obj, jsonFile)
            % JSONファイルから設定を読み込む
            fid = fopen(jsonFile, 'r');
            if fid == -1
                error('Cannot open JSON file: %s', jsonFile);
            end
            raw = fread(fid, inf, 'char')';
            fclose(fid);
            settings = jsondecode(char(raw));

            % オブジェクトのプロパティに設定を適用
            fields = fieldnames(settings);
            for i = 1:numel(fields)
                if isprop(obj, fields{i})
                    obj.(fields{i}) = settings.(fields{i});
                end
            end

            % list_fig: JSON 配列 → string 列ベクトルへ正規化
            if isfield(settings, 'list_fig')
                lf = settings.list_fig;
                if isempty(lf)
                    obj.list_fig = string.empty(0,1);
                elseif iscell(lf)
                    obj.list_fig = string(lf(:));
                else
                    obj.list_fig = string(lf);
                end
            end

            % expandConditions が elev/Vw0/Wpsi を展開後の配列で上書きしてしまうため、
            % UI から受け取った元の入力（[min max step] 等）を _set 側に退避してから展開する
            if isfield(settings, 'elev'); obj.elev_set = GeneralSetting2.ensureNumericRow(settings.elev, 'elev'); end
            if isfield(settings, 'Vw0');  obj.Vw0_set  = GeneralSetting2.ensureNumericRow(settings.Vw0,  'Vw0');  end
            if isfield(settings, 'Wpsi'); obj.Wpsi_set = GeneralSetting2.ensureNumericRow(settings.Wpsi, 'Wpsi'); end

            obj = obj.expandConditions();

        end
        
        function obj = applyDefaultModelPaths(obj)
            % UIがpathを提供していればそのまま使用し、空の場合のみ既定ディレクトリを適用
            pfn_arr = GeneralSetting2.toStringVec(obj.param.fn);
            ppath_arr = GeneralSetting2.toStringVec(obj.param.path);
            if numel(ppath_arr) < numel(pfn_arr)
                ppath_arr(end+1:numel(pfn_arr),1) = "";
            end
            for k = 1:numel(pfn_arr)
                if strlength(pfn_arr(k)) > 0 && strlength(ppath_arr(k)) == 0
                    ppath_arr(k) = string(obj.dir.param);
                end
            end
            obj.param.fn   = pfn_arr;
            obj.param.path = ppath_arr;

            if strlength(string(obj.thrust.fn)) > 0 && strlength(string(obj.thrust.path)) == 0
                obj.thrust.path = string(obj.dir.thrust);
            end
            switch obj.wind_model
                case "MSM"
                    if strlength(string(obj.MSM.fn)) > 0 && strlength(string(obj.MSM.path)) == 0
                        obj.MSM.path = string(obj.dir.data);
                    end
                case "csv"
                    if strlength(string(obj.wind_csv.fn)) > 0 && strlength(string(obj.wind_csv.path)) == 0
                        obj.wind_csv.path = string(obj.dir.data);
                    end
            end
            if strlength(string(obj.fp.fn)) > 0 && strlength(string(obj.fp.path)) == 0
                obj.fp.path = string(obj.dir.launch);
            end

            % 動翼空力DB：fn 指定があり path が空のものは ParameterFiles を既定にする
            obj.aero_db = GeneralSetting2.normalizeAeroDb(obj.aero_db);
            for k = 1:numel(obj.aero_db.files)
                if strlength(string(obj.aero_db.files(k).fn)) > 0 && strlength(string(obj.aero_db.files(k).path)) == 0
                    obj.aero_db.files(k).path = string(obj.dir.param);
                end
            end

            % パーツ別空力：fn 指定があり path が空なら ParameterFiles を既定にする
            obj.comp_aero = GeneralSetting2.normalizeCompAero(obj.comp_aero);
            if strlength(string(obj.comp_aero.fn)) > 0 && strlength(string(obj.comp_aero.path)) == 0
                obj.comp_aero.path = string(obj.dir.param);
            end
        end

        function obj = applyMultiStage(obj)
            % multi_stage フラグに応じて param_n を設定し、param.fn/path を正規化
            ms_on = false;
            if islogical(obj.multi_stage)
                ms_on = obj.multi_stage;
            elseif isnumeric(obj.multi_stage)
                ms_on = obj.multi_stage ~= 0;
            elseif ischar(obj.multi_stage) || isstring(obj.multi_stage)
                ms_on = any(strcmpi(string(obj.multi_stage), ["On","Yes","True","1"]));
            end
            obj.multi_stage = logical(ms_on);

            pfn_arr   = GeneralSetting2.toStringVec(obj.param.fn);
            ppath_arr = GeneralSetting2.toStringVec(obj.param.path);

            if obj.multi_stage
                obj.param_n = 3;
                % 3要素に揃える（不足分は空文字、超過分は切り捨て）
                if numel(pfn_arr) < 3
                    pfn_arr(end+1:3,1) = "";
                elseif numel(pfn_arr) > 3
                    pfn_arr = pfn_arr(1:3);
                end
                if numel(ppath_arr) < 3
                    ppath_arr(end+1:3,1) = "";
                elseif numel(ppath_arr) > 3
                    ppath_arr = ppath_arr(1:3);
                end
            else
                obj.param_n = 1;
                if ~isempty(pfn_arr)
                    pfn_arr = pfn_arr(1);
                else
                    pfn_arr = "";
                end
                if ~isempty(ppath_arr)
                    ppath_arr = ppath_arr(1);
                else
                    ppath_arr = "";
                end
            end
            obj.param.fn   = pfn_arr;
            obj.param.path = ppath_arr;
        end

        function obj = loadFallPointBundle(obj)
            % settings.json 読み込み後に呼んで、落下分散図の設定/画像を適用
            try
                if ~isprop(obj,'fp') || ~isstruct(obj.fp) || strlength(obj.fp.fn)==0
                    return;
                end
                P = fullfile(char(obj.fp.path), char(obj.fp.fn));
                if ~isfile(P)
                    warning('FallPoint bundle が見つかりません: %s', P);
                    return;
                end
                data = load(P); % 期待: data.cfg / data.img / (data.raw) / data.name
            
                % ---- cfg → GeneralSetting2 プロパティへ反映 ----
                if isfield(data,'cfg')
                    cfg = data.cfg;
                    % 軸
                    if isfield(cfg,'ax') && isfield(cfg.ax,'range'),    obj.ax.point.range    = cfg.ax.range; end
                    if isfield(cfg,'ax') && isfield(cfg.ax,'label'),    obj.ax.point.label    = cfg.ax.label; end
                    if isfield(cfg,'ax') && isfield(cfg.ax,'FontSize'), obj.ax.point.FontSize = cfg.ax.FontSize; end
                    % 凡例
                    if isfield(cfg,'lgd') && isfield(cfg.lgd,'pos'),      obj.lgd.point.pos      = cfg.lgd.pos; end
                    if isfield(cfg,'lgd') && isfield(cfg.lgd,'FontSize'), obj.lgd.point.FontSize = cfg.lgd.FontSize; end
                    % 背景貼付け矩形
                    if isfield(cfg,'back_pos'), obj.back_pict.pos = cfg.back_pos; end
                    % 表示基準（mgd は FallPoint バンドルからは取得しない）
                    if isfield(cfg,'view_azm'), obj.view_azm = cfg.view_azm; end
                    % マーカー（必要に応じて）
                    if isfield(cfg,'marker'),  obj.marker  = cfg.marker;  end
                end
            
                % ---- 背景画像（配列） ----
                if isfield(data,'img') && ~isempty(data.img)
                    obj.back_pict.img = data.img;    % 画像配列をそのまま保持
                    if isfield(data,'name'), obj.back_pict.fn = data.name; end
                end
            catch ME
                warning(ME.identifier, 'FallPoint bundle 適用中に例外: %s', ME.message);
            end
        end

        function obj = expandConditions(obj)
            % 入力（elev, Vw0, Wpsi）を「数値の行ベクトル」に正規化
            er = GeneralSetting2.ensureNumericRow(obj.elev, 'elev');
            vr = GeneralSetting2.ensureNumericRow(obj.Vw0,  'Vw0');
            wr = GeneralSetting2.ensureNumericRow(obj.Wpsi, 'Wpsi');
        
            %=== 射角と風速：単一値 / [min max step] / リスト の全てを受け付ける ===
            obj.elev = GeneralSetting2.expandRangeOrList(er, 'elev');
            obj.Vw0  = GeneralSetting2.expandRangeOrList(vr, 'Vw0');
        
            %=== 風向：角度特有の扱いを含めて展開 ===
            if numel(wr) == 3
                % [min max step] 形式
                a = wr(1); b = wr(2); s = wr(3);
                if s == 0
                    error('GeneralSetting2:WpsiStepZero', ...
                        'Wpsi の step が 0 です。正の値を指定してください。');
                end
                % 0..360 のフルレンジ指定は 360 を含めない（重複防止）
                if a == 0 && b == 360 && s > 0
                    w_list = a:s:(b - s);
                else
                    % 通常のレンジ（端点を必ず含める）
                    w_list = a:s:b;
                    if isempty(w_list) || w_list(end) ~= b
                        w_list = [w_list, b];
                    end
                end
            elseif numel(wr) >= 1
                % 既に展開済みのリスト
                w_list = wr;
            else
                w_list = [];
            end
        
            %=== 角度系の変換（旧 GeneralSetting 相当） ===
            % 入力は CW 前提 → CCW へ
            if strcmpi(obj.mode_angle, 'CW')
                w_list = 360 - w_list;
            end
        
            % Magnetic → True（base_azm の先頭が 'M' のとき mgd を加算）
            % 内部計算は真方位 (True E/N) で統一する設計のため、磁気入力は加算で True に揃える。
            if ~isempty(obj.base_azm) && ischar(obj.base_azm) && obj.base_azm(1) == 'M'
                w_list = w_list + obj.mgd;
            end
        
            % 第2文字（N/E/W/S）基準の回転補正
            ang = 0;
            if ~isempty(obj.base_azm) && ischar(obj.base_azm) && numel(obj.base_azm) >= 2
                switch obj.base_azm(2)
                    case 'N', ang = 90;
                    case 'E', ang = 0;
                    case 'W', ang = 180;
                    case 'S', ang = -90;
                end
            end
            w_list = w_list + ang;
        
            % 0..360 正規化
            w_list = mod(w_list, 360);
            w_list(w_list < 0) = w_list(w_list < 0) + 360;
        
            % 重複排除（並びは保持）
            obj.Wpsi = unique(w_list, 'stable');
        
            %=== 件数を設定 ===
            obj.elev_n = numel(obj.elev);
            obj.Vw0_n  = numel(obj.Vw0);
            obj.Wpsi_n = numel(obj.Wpsi);
        end

        function obj = deleteFilePaths(obj, jsonFile)
            % 設定ファイル内に保存されているファイルパスを全て空にする（UI上での「キャンセル」選択時などに呼ぶ）
            resetSettings = struct(...
                'multi_stage', obj.multi_stage, ...
                'param', struct('fn', "", 'path', ""), ...
                'thrust', struct('fn', "", 'path', ""), ...
                'descent_model', obj.descent_model, ...
                'elev', obj.elev_set, ...
                'Vw0',  obj.Vw0_set, ...
                'Wpsi', obj.Wpsi_set, ...
                't_max', obj.t_max, ...
                'base_azm', obj.base_azm, ...
                'mode_angle', obj.mode_angle, ...
                'dt', obj.dt, ...
                'mode_landing', obj.mode_landing, ...
                'execute_cont', obj.execute_cont, ...
                'control_func', obj.control_func, ...
                'simu_mode', obj.simu_mode, ...
                'rot_cond', obj.rot_cond, ...
                'roll_factor', obj.roll_factor, ...
                'Cl0', obj.Cl0, ...
                'parallel', obj.parallel, ...
                'mgd', obj.mgd, ...
                'mode_export', obj.mode_export, ...
                'result_path', "", ...
                'output', obj.output, ...
                'list_fig', obj.list_fig, ...
                'MSM', struct('fn', "", 'path', ""), ...
                'wind_csv', struct('fn', "", 'path', ""), ...
                'fp', struct('fn', "", 'path', ""), ...
                'Mx_csv', struct('fn', "", 'path', ""), ...
                'aero_db', GeneralSetting2.emptyAeroDb(), ...
                'comp_aero', GeneralSetting2.emptyCompAero() ...
            );

            fid = fopen(jsonFile, 'w');
            if fid == -1
                error('Failed to open file: %s', jsonFile);
            end
            fwrite(fid, jsonencode(resetSettings), 'char');
            fclose(fid);
            disp('File paths in settings.json have been reset to empty.');
        end

        function writePreSettings(obj, preFile)
            % 端末ローカル用「前回設定」スナップショットを書き出す（ファイル/フォルダのパス込み）
            snapshot = struct(...
                'multi_stage', obj.multi_stage, ...
                'param', struct('fn', obj.param.fn, 'path', obj.param.path), ...
                'thrust', struct('fn', obj.thrust.fn, 'path', obj.thrust.path), ...
                'descent_model', obj.descent_model, ...
                'elev', obj.elev_set, ...
                'Vw0',  obj.Vw0_set, ...
                'Wpsi', obj.Wpsi_set, ...
                't_max', obj.t_max, ...
                'base_azm', obj.base_azm, ...
                'mode_angle', obj.mode_angle, ...
                'dt', obj.dt, ...
                'mode_landing', obj.mode_landing, ...
                'execute_cont', obj.execute_cont, ...
                'control_func', obj.control_func, ...
                'simu_mode', obj.simu_mode, ...
                'rot_cond', obj.rot_cond, ...
                'roll_factor', obj.roll_factor, ...
                'Cl0', obj.Cl0, ...
                'parallel', obj.parallel, ...
                'mgd', obj.mgd, ...
                'mode_export', obj.mode_export, ...
                'result_path', obj.result_path, ...
                'output', obj.output, ...
                'list_fig', obj.list_fig, ...
                'MSM', struct('fn', obj.MSM.fn, 'path', obj.MSM.path), ...
                'wind_csv', struct('fn', obj.wind_csv.fn, 'path', obj.wind_csv.path), ...
                'fp', struct('fn', obj.fp.fn, 'path', obj.fp.path), ...
                'Mx_csv', struct('fn', obj.Mx_csv.fn, 'path', obj.Mx_csv.path), ...
                'aero_db', GeneralSetting2.normalizeAeroDb(obj.aero_db), ...
                'comp_aero', GeneralSetting2.normalizeCompAero(obj.comp_aero) ...
            );

            fid = fopen(preFile, 'w');
            if fid == -1
                warning('Cannot open PreSettings file: %s', preFile);
                return
            end
            fwrite(fid, jsonencode(snapshot), 'char');
            fclose(fid);
            disp('PreSettings.json updated (with file/folder paths).');
        end
    end

    methods (Static)
        function s = emptyAeroDb()
            % 空（未使用）の aero_db 構造体（5スロット）
            s = struct('use', false, ...
                       'files', struct('use',  {false, false, false, false, false}, ...
                                       'v',    {0, 0, 0, 0, 0}, ...
                                       'fn',   {"", "", "", "", ""}, ...
                                       'path', {"", "", "", "", ""}));
        end

        function out = normalizeAeroDb(adb)
            % jsondecode 等で得た aero_db を { use(logical scalar), files(1xN struct: use,v,fn,path) } に正規化
            out = GeneralSetting2.emptyAeroDb();
            if ~isstruct(adb)
                return;
            end
            if isfield(adb, 'use')
                u = adb.use;
                if islogical(u)
                    out.use = logical(u(1));
                elseif isnumeric(u) && ~isempty(u)
                    out.use = (u(1) ~= 0);
                elseif ischar(u) || isstring(u)
                    out.use = any(strcmpi(string(u), ["true","on","yes","1"]));
                end
            end
            if isfield(adb, 'files') && isstruct(adb.files) && ~isempty(adb.files)
                f = adb.files(:).';
                n = numel(f);
                files = repmat(struct('use', false, 'v', 0, 'fn', "", 'path', ""), 1, n);
                for k = 1:n
                    if isfield(f, 'use')
                        uk = f(k).use;
                        if islogical(uk)
                            files(k).use = logical(uk(1));
                        elseif isnumeric(uk) && ~isempty(uk)
                            files(k).use = (uk(1) ~= 0);
                        elseif ischar(uk) || isstring(uk)
                            files(k).use = any(strcmpi(string(uk), ["true","on","yes","1"]));
                        end
                    end
                    if isfield(f, 'v') && isnumeric(f(k).v) && ~isempty(f(k).v)
                        files(k).v = double(f(k).v(1));
                    end
                    if isfield(f, 'fn');   files(k).fn   = string(f(k).fn);   end
                    if isfield(f, 'path'); files(k).path = string(f(k).path); end
                end
                out.files = files;
            end
        end

        function s = emptyCompAero()
            % 空（未使用）の comp_aero 構造体
            s = struct('use', false, 'fix_delta', false, 'fn', "", 'path', "", 'delta_fixed', 0);
        end

        function out = normalizeCompAero(ca)
            % jsondecode 等で得た comp_aero を
            %   { use(logical), fix_delta(logical), fn, path, delta_fixed(double) } に正規化
            out = GeneralSetting2.emptyCompAero();
            if ~isstruct(ca)
                return;
            end
            toLogical = @(v) (islogical(v) && logical(v(1))) || ...
                             (isnumeric(v) && ~isempty(v) && v(1) ~= 0) || ...
                             ((ischar(v) || isstring(v)) && any(strcmpi(string(v), ["true","on","yes","1"])));
            if isfield(ca, 'use');       out.use       = toLogical(ca.use);       end
            if isfield(ca, 'fix_delta'); out.fix_delta = toLogical(ca.fix_delta); end
            if isfield(ca, 'fn');   out.fn   = string(ca.fn);   end
            if isfield(ca, 'path'); out.path = string(ca.path); end
            if isfield(ca, 'delta_fixed') && isnumeric(ca.delta_fixed) && ~isempty(ca.delta_fixed)
                out.delta_fixed = double(ca.delta_fixed(1));
            end
        end
    end

    methods (Static, Access = private)
        function s = toStringVec(val)
            % cell / char / string 混在を string の列ベクトルへ正規化
            if isempty(val)
                s = string.empty(0,1); return;
            end
            s = string(val);
            s = s(:);
        end

        function vec = ensureNumericRow(val, name)
            % val を「数値の行ベクトル double」に正規化する
            if isstring(val)
                val = char(val);
            end
            if ischar(val)
                % 例: "75 85 5" などの文字列も許容
                tmp = str2num(val); %#ok<ST2NM>
                if isempty(tmp)
                    error('GeneralSetting2:%sNotNumeric', ...
                          '%s は数値に変換できませんでした。', name);
                end
                val = tmp;
            end
            if ~isnumeric(val)
                error('GeneralSetting2:%sNotNumeric', ...
                      '%s は数値配列である必要があります。', name);
            end
            vec = double(val(:)).';     % 行ベクトル double
        end
    
        function list = expandRangeOrList(rng, name)
            % 単一値 / [min max step] / 既に展開済みリスト の全てに対応
            n = numel(rng);
            switch n
                case 0
                    list = [];
                case 1
                    list = rng;              % 単一条件
                case 3
                    a = rng(1); b = rng(2); s = rng(3);
                    if s == 0
                        error('GeneralSetting2:%sStepZero', ...
                            '%s の step が 0 です。', name);
                    end
                    % レンジ展開（端点を必ず含める）
                    list = a:s:b;
                    if isempty(list) || list(end) ~= b
                        list = [list, b];
                    end
                otherwise
                    list = rng;              % 既に展開済みの多要素リスト
            end
            % 重複を除去（並び保持）
            list = unique(list, 'stable');
        end
    end
end
