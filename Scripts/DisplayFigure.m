% Spica_plus_NoOption
% 結果表示用クラス
%-------------------------------------------------------------------------%
classdef DisplayFigure
    properties
        %-----directory-----
        dir = struct( ...
        'home',"", 'data',"", 'res',"", 'scr',"", 'setting',"", ...
        'UI',"", 'form',"", 'param',"", 'thrust',"" );
        output_dir = "";        % ログと共通の出力先（paramN フォルダ絶対パス）

        %-----parameter-----
        param_n = 1;                % 全段数

        %-----calculating condition-----
        base_azm = 'ME';
        mode_angle = 'CCW';
        view_azm = 'Magnetic';
        mode_calc = 'Single';
        mode_landing = 'Hard';      % 降下モード（Hard / Descent / Both）
        descent_model = 'Vw_model';
        elev_set = zeros(3,1);
        Vw0_set = zeros(3,1);
        Wpsi_set = zeros(3,1);
        mgd = 0;

        %-----calculating-----
        dt = 0;
        elev = [];
        Vw0 = [];
        Wpsi = [];
        Wpsi_res = [];
        elev_n = 0;
        Vw0_n = 0;
        Wpsi_n = 0;

        %-----result-----
        % Calculation2.res（モード別 struct）をそのまま受け取る
        %   res.Hard    → (elev_n × Vw0_n × Wpsi_n × param_n) の MainSolver 配列
        %   res.Descent → 同上（Both または Descent 選択時）
        res = struct();
        ll = [];                    % 経緯度変換用クラス（lon_latクラス）

        %-----display-----
        list_fig = string.empty(0,1);   % 出力する図のリスト
        fig_size = struct(...
            'path',[100, 50, 800, 700],...
            'point',[100, 50, 800, 700]);
        ax = struct(...
            'path',struct(...
                'range', [-840, 880, -910, 750],...
                'label', ["Magnetic East [m]";
                        "Magnetic North [m]";
                        "Altitude [m]"],...
                'FontSize', 10,...
                'Color', [0, 0, 0],...
                'FontWeight', 'normal'),...
            'point',struct(...
                'range', [-840, 880, -910, 750],...
                'label', ["True East[m]";"True North[m]"],...
                'FontSize', 10,...
                'Color', [0, 0, 0],...
                'FontWeight', 'normal'));
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
                'FontWeight', 'bold'));

        %-----fallpoint-----
        back_pict = struct(...
            'fn', 'Oshima_201903.jpg',...
            'img', [],...
            'pos', [-830, 870; -907, 750]);
        marker = struct(...
            'color', [1, 1, 1; 1, 0, 0],...
            'size', 20,...
            'shape', "o",...
            'mfc', 'flat');

        %-----kml-----
        kml = struct('Width', 15, 'Color', [1 1 1]);
        kml_str = struct(...
            'str1', ["<?xml version=""1.0"" encoding=""utf-8""?>";
                "<kml xmlns=""http://www.opengis.net/kml/2.2"">";
                "<Document>"],...
            'str2', "<LineStyle>",...
            'str3', ["</LineStyle>";
                "<ColorStyle>"],...
            'str4', ["</ColorStyle>";
                "<Placemark>";
                "<description> </description>";
                "<MultiGeometry>"],...
            'str5',["<LineString>";
                "<altitudeMode>relativeToGround</altitudeMode>";
                "<coordinates>"],...
            'str_multi',["</coordinates>";
                "</LineString>"],...
            'str6', ["</coordinates>";
                "</LineString>";
                "</MultiGeometry>";
                "</Placemark>";
                "</Document>";
                "</kml>"]);
    end

    methods
        function obj = DisplayFigure(gs, cc)

            % GeneralSetting2 クラスのプロパティを代入
            gs_list = properties(gs);
            df_list = properties(obj);
            list = ismember(df_list, gs_list);
            for i = find(list)'
                obj.(df_list{i}) = gs.(df_list{i});
            end

            % Calculation2 クラスのプロパティを代入（res など）
            cc_list = properties(cc);
            list = ismember(df_list, cc_list);
            for i = find(list)'
                obj.(df_list{i}) = cc.(df_list{i});
            end

            % 軸ラベルを view_azm に応じて切替
            % 内部計算は True E/N 系で統一しているため、
            %   view_azm='True'    → そのまま "True East/North"
            %   view_azm='Magnetic'→ "Magnetic East/North"（出力時に座標を mgd で回転）
            if strcmpi(obj.view_azm, 'Magnetic')
                obj.ax.path.label  = ["Magnetic East [m]"; "Magnetic North [m]"; "Altitude [m]"];
                obj.ax.point.label = ["Magnetic East [m]"; "Magnetic North [m]"];
            else
                obj.ax.path.label  = ["True East [m]";     "True North [m]";     "Altitude [m]"];
                obj.ax.point.label = ["True East [m]";     "True North [m]"];
            end

            % 各種図の出力
            path_tf   = ismember(["FlightPath"; "KML of FlightPath"], obj.list_fig);
            point_tf  = ismember(["FallPoint";  "KML of FallPoint"],  obj.list_fig);
            mp4_tf    = ismember("Attitude MP4", obj.list_fig);
            wind_tf   = ismember(["Wind Graph"; "Wind CSV"], obj.list_fig);

            if sum(path_tf) > 0
                disp("OutPutting FlightPath Figures...")
                obj.output_path();
            end
            if sum(point_tf) > 0
                disp("OutPutting FallPoint Figures...")
                obj.output_point();
            end
            if mp4_tf
                disp("OutPutting Attitude MP4...")
                obj.output_attitude_mp4();
            end
            if sum(wind_tf) > 0
                disp("OutPutting Wind Profile...")
                obj.output_wind();
            end
        end

        %------------------------------------------------------------------
        function output_path(obj)   % 飛行経路図・KML出力（モード別）
            ax_set  = obj.ax.path;
            lgd_set = obj.lgd.path;

            str_color = DisplayFigure.kml_color(obj.kml.Color);

            modes = fieldnames(obj.res);
            for iMode = 1:numel(modes)
                cur_mode = modes{iMode};
                res_mode = obj.res.(cur_mode);

                [ne, nv, nw, np] = size(res_mode);

                for jElev = 1:ne
                    for jV = 1:nv
                        % 新階層: <paramN>/<Mode>/FlightPath/elev<E>deg/Vw0<V>ms/
                        vw_dir = obj.ensure_dir(fullfile( ...
                            obj.get_output_base(), char(cur_mode), 'FlightPath', ...
                            char(Calculation2.elev_token(obj.elev(jElev))), ...
                            char(Calculation2.vw_token(obj.Vw0(jV)))));

                        for jPsi = 1:nw
                            cond_name = strcat("FlightPath_", ...
                                Calculation2.angle_token("Wpsi", obj.Wpsi(jPsi)));

                            fig_opened = false;
                            kml_opened = false;
                            f = -1;

                            for iStage = 1:np
                                ms_res = res_mode(jElev, jV, jPsi, iStage);
                                if isempty(ms_res.xs), continue; end
                                stage_str = DisplayFigure.stage_label(iStage);
                                pos = ms_res.xs(1:3, :)';

                                % 表示用に view_azm='Magnetic' なら水平面を mgd 回転
                                pos_view = pos;
                                if strcmpi(obj.view_azm, 'Magnetic')
                                    R = [ cosd(obj.mgd)  sind(obj.mgd);
                                         -sind(obj.mgd)  cosd(obj.mgd)];
                                    pos_view(:,1:2) = (R * pos(:,1:2).').';
                                end

                                % -------- JPG --------
                                if ismember("FlightPath", obj.list_fig)
                                    plot3(pos_view(:,1), pos_view(:,2), pos_view(:,3), ...
                                        'DisplayName', strcat("Ns=", num2str(iStage)))
                                    hold on; grid on;
                                    if ~fig_opened
                                        fig = gcf;
                                        fig.Name = cond_name;
                                        fig.Position = obj.fig_size.path;
                                        fig_opened = true;
                                    end
                                    if iStage == np
                                        tmp_ax = gca;
                                        xlabel(ax_set.label(1), 'FontSize', ax_set.FontSize)
                                        ylabel(ax_set.label(2), 'FontSize', ax_set.FontSize)
                                        zlabel(ax_set.label(3), 'FontSize', ax_set.FontSize)
                                        tmp_ax.FontSize   = ax_set.FontSize;
                                        tmp_ax.XColor     = ax_set.Color;
                                        tmp_ax.YColor     = ax_set.Color;
                                        tmp_ax.FontWeight = ax_set.FontWeight;
                                        tmp_lgd = legend;
                                        tmp_lgd.Position   = lgd_set.pos;
                                        tmp_lgd.FontSize   = lgd_set.FontSize;
                                        tmp_lgd.TextColor  = lgd_set.TextColor;
                                        tmp_lgd.FontWeight = lgd_set.FontWeight;
                                    end
                                end

                                % -------- KML --------
                                if ismember("KML of FlightPath", obj.list_fig) && ~isempty(obj.ll)
                                    [x_geo, ~] = obj.ll.Vincenty_direct(pos(:,1:2));
                                    x_geo = [x_geo(:,2), x_geo(:,1), pos(:,3)];
                                    if ~kml_opened
                                        kml_fn = fullfile(vw_dir, strcat(cond_name, ".kml"));
                                        f = fopen(kml_fn, 'w');
                                        write_str = [obj.kml_str.str1;
                                            strcat("<name>", cond_name, "</name>");
                                            obj.kml_str.str2;
                                            num2str(obj.kml.Width);
                                            obj.kml_str.str3;
                                            str_color;
                                            obj.kml_str.str4];
                                        fprintf(f, '%s\n', write_str);
                                        fclose(f);
                                        f = fopen(kml_fn, 'a');
                                        kml_opened = true;
                                    else
                                        fprintf(f, '%s\n', obj.kml_str.str_multi);
                                    end
                                    write_str = [strcat("<name>", stage_str, "</name>");
                                        obj.kml_str.str5];
                                    fprintf(f, '%s\n', write_str);
                                    fprintf(f, '%.12f,%.12f,%.12f\n', x_geo');
                                end
                            end

                            if ismember("FlightPath", obj.list_fig) && fig_opened
                                hold off
                                saveas(fig, fullfile(vw_dir, strcat(cond_name, '.jpg')))
                                close(fig)
                            end
                            if ismember("KML of FlightPath", obj.list_fig) && kml_opened
                                fprintf(f, '%s\n', obj.kml_str.str6);
                                fclose(f);
                            end
                        end
                    end
                end
            end
        end

        %------------------------------------------------------------------
        function output_point(obj)  % 落下分散図・KML出力（モード別）
            ax_set     = obj.ax.point;
            lgd_set    = obj.lgd.point;
            back_set   = obj.back_pict;
            marker_set = struct(...
                'color', [1, 1, 1; 1, 0, 0],...
                'size', 20,...
                'shape', "o",...
                'mfc', 'flat');

            str_color = DisplayFigure.kml_color(obj.kml.Color);

            modes = fieldnames(obj.res);
            for iMode = 1:numel(modes)
                cur_mode = modes{iMode};
                res_mode = obj.res.(cur_mode);
                [ne, nv, nw, np] = size(res_mode);

                % 新階層: <paramN>/<Mode>/FallPoint/Ns<n>/
                base_dir = fullfile(obj.get_output_base(), char(cur_mode), 'FallPoint');
                obj.ensure_dir(base_dir);
                dir_name = strings(np, 1);
                for i = 1:np
                    dir_name(i) = string(obj.ensure_dir( ...
                        fullfile(base_dir, strcat("Ns", num2str(i)))));
                end

                for jElev = 1:ne
                    for iStage = 1:np
                        stage_str = DisplayFigure.stage_label(iStage);
                        cond_name = strcat("FallPoint_", ...
                            Calculation2.elev_token(obj.elev(jElev)));

                        if ismember("FallPoint", obj.list_fig)
                            fig_name = strcat('FallPoint_', cur_mode, ...
                                '(elev=', num2str(obj.elev(jElev)), ',Ns=', num2str(iStage), ')');
                            fig = figure('Name', fig_name, 'Position', obj.fig_size.point);
                            axis(ax_set.range)
                            hold on
                            if ~isempty(back_set.img)
                                image(back_set.pos(1,:), back_set.pos(2,:), back_set.img)
                            end
                        end

                        kml_opened = false;
                        f = -1;

                        for jV = 1:nv
                            % べき法則風 + Vw0=0 では jPsi=1 のみが意図的に計算されている
                            ms0 = res_mode(jElev, jV, 1, iStage);
                            is_zero_wind = isprop(ms0, 'wind_model') ...
                                && string(ms0.wind_model) == "PowerLaw" ...
                                && isprop(ms0, 'Vw0') && ms0.Vw0 == 0;
                            if is_zero_wind
                                nw_eff = 1;
                            else
                                nw_eff = nw;
                            end
                            % 計算済み風向の落下点（E,N）を収集（True E/N 系）
                            fp = zeros(nw_eff, 2);
                            skip_vw = false;
                            for jPsi = 1:nw_eff
                                tmp_xs = res_mode(jElev, jV, jPsi, iStage).xs;
                                if isempty(tmp_xs), skip_vw = true; break; end
                                fp(jPsi, :) = tmp_xs(1:2, end)';
                            end
                            if skip_vw, continue; end

                            % 表示用に view_azm='Magnetic' なら原点周りを mgd 回転
                            % （fp は True E/N。KML/Vincenty には回転前の True を渡すため別変数を用意）
                            fp_view = fp;
                            if strcmpi(obj.view_azm, 'Magnetic')
                                R = [ cosd(obj.mgd)  sind(obj.mgd);
                                     -sind(obj.mgd)  cosd(obj.mgd)];
                                fp_view = (R * fp.').';
                            end

                            if ismember("FallPoint", obj.list_fig)
                                % Vw0 に応じてマーカー色を線形補間（最小風速なら白、最大風速なら赤）
                                % interp1 は length(X) == size(V,1) を要求するため、
                                % 色テーブルの行数に合わせて X 軸を作る（行数が2でなくても破綻しない）。
                                ncol = size(marker_set.color, 1);
                                if nv > 1 && ncol >= 2
                                    color = interp1([1,nv], marker_set.color, jV, 'linear', 'extrap');
                                else
                                    color = marker_set.color(1, :);   % 風速1条件 or 単色なら先頭色
                                end
                                scatter(fp(:,1), fp(:,2), marker_set.size,...
                                    color, marker_set.shape,...
                                    'LineWidth',1.5,...
                                    'MarkerFaceColor',marker_set.mfc,...
                                    'DisplayName',strcat(num2str(obj.Vw0(jV)),'m/s'));
                            end

                            % 一意な落下点が2点以上ある場合のみ KML ラインを出力する。
                            % Vw0=0 等で落下点が1点しかない場合、LineString が無効となり
                            % 0,0 に配置されてしまうため除外する。
                            if ismember("KML of FallPoint", obj.list_fig) && ~isempty(obj.ll) ...
                                    && size(unique(fp, 'rows'), 1) >= 2
                                [x_geo, ~] = obj.ll.Vincenty_direct(fp);
                                x_geo = [x_geo(:,2), x_geo(:,1)];
                                if ~kml_opened
                                    kml_fn = fullfile(char(dir_name(iStage)), ...
                                        strcat(cond_name, ".kml"));
                                    f = fopen(kml_fn, 'w');
                                    write_str = [obj.kml_str.str1;
                                        strcat("<name>", cond_name, "</name>");
                                        obj.kml_str.str2;
                                        num2str(obj.kml.Width);
                                        obj.kml_str.str3;
                                        str_color;
                                        obj.kml_str.str4];
                                    fprintf(f, '%s\n', write_str);
                                    fclose(f);
                                    f = fopen(kml_fn, 'a');
                                    kml_opened = true;
                                else
                                    fprintf(f, '%s\n', obj.kml_str.str_multi);
                                end
                                write_str = [strcat("<name>", num2str(obj.Vw0(jV)), "m/s</name>");
                                    obj.kml_str.str5];
                                fprintf(f, '%s\n', write_str);
                                % 落下分散範囲を閉じる：風向が3点以上あれば先頭点を末尾に追加し、
                                % 最初の風向と最後の風向を結んでリングを閉じる
                                if size(x_geo, 1) >= 3
                                    x_geo = [x_geo; x_geo(1, :)];
                                end
                                fprintf(f, '%.12f,%.12f\n', x_geo');
                            end
                        end

                        if ismember("FallPoint", obj.list_fig)
                            tmp_ax = gca;
                            xlabel(ax_set.label(1), 'FontSize', ax_set.FontSize)
                            ylabel(ax_set.label(2), 'FontSize', ax_set.FontSize)
                            tmp_ax.FontSize   = ax_set.FontSize;
                            tmp_ax.XColor     = ax_set.Color;
                            tmp_ax.YColor     = ax_set.Color;
                            tmp_ax.FontWeight = ax_set.FontWeight;
                            tmp_lgd = legend('boxoff');
                            tmp_lgd.Position   = lgd_set.pos;
                            tmp_lgd.FontSize   = lgd_set.FontSize;
                            tmp_lgd.TextColor  = lgd_set.TextColor;
                            tmp_lgd.FontWeight = lgd_set.FontWeight;
                            hold off
                            saveas(fig, fullfile(char(dir_name(iStage)), strcat(cond_name, '.jpg')))
                            close(fig)
                        end

                        if ismember("KML of FallPoint", obj.list_fig) && kml_opened
                            fprintf(f, '%s\n', obj.kml_str.str6);
                            fclose(f);
                        end
                    end
                end
            end
        end

        %------------------------------------------------------------------
        function output_attitude_mp4(obj)
            % Hard モード（なければ最初のモード）の最初の条件
            % (jElev=1, jV=1, jPsi=1, iStage=1) の姿勢変化を MP4 出力
            %
            % 地上座標系に固定されたカメラから見た姿勢変化を描画する。
            % q_DCM(q) は ground→body の DCM を返すため、
            % body→ground 変換には転置 R' を使用する。
            %
            % Data/ に STL ファイルがあればそれを使用し、
            % なければプロシージャルモデルで描画する。

            modes = fieldnames(obj.res);
            if isempty(modes)
                warning('res が空です。Attitude MP4 をスキップします。');
                return;
            end
            if ismember('Hard', modes)
                target_mode = 'Hard';
            else
                target_mode = modes{1};
            end
            ms_res = obj.res.(target_mode)(1, 1, 1, 1);

            if isempty(ms_res.xs)
                warning('output_attitude: xs が空のため Attitude MP4 をスキップします。');
                return;
            end

            ts = ms_res.ts;           % 1 × N
            qs = ms_res.xs(7:10, :); % [w;x;y;z] × N

            % 新階層: <paramN>/<Mode>/Attitude/AttitudeAnimation_<cond>.mp4 （§2.3, §3-3）
            att_dir = obj.ensure_dir(fullfile( ...
                obj.get_output_base(), char(target_mode), 'Attitude'));
            % 代表条件 (jElev=1, jV=1, jPsi=1, iStage=1) — 名前に条件を明示
            cond_tag = strcat( ...
                Calculation2.elev_token(obj.elev(1)), '_', ...
                Calculation2.vw_token(obj.Vw0(1)),    '_', ...
                Calculation2.angle_token("Wpsi", obj.Wpsi(1)), '_Ns1');
            mp4_fn = fullfile(att_dir, char(strcat('AttitudeAnimation_', cond_tag, '.mp4')));

            % アニメーション用時系列（fps=30 に間引き）
            fps = 30;
            t_anim = ts(1) : 1/fps : ts(end);
            q_anim = interp1(ts', qs', t_anim', 'linear')';  % 4 × N_frames

            % ======== モデル読み込み ========
            stl_path = fullfile(char(obj.dir.data), 'シミュレーションモデル.stl');
            use_stl = isfile(stl_path);

            if use_stl
                [V_body, F, face_colors, lim] = ...
                    DisplayFigure.load_stl_model(stl_path);
                disp(['STL model loaded: ', stl_path]);
            else
                [V_body, F, face_colors, lim] = ...
                    DisplayFigure.build_procedural_model();
                disp('STL not found. Using procedural model.');
            end

            % ======== VideoWriter ========
            vw = VideoWriter(mp4_fn, 'MPEG-4');
            vw.FrameRate = fps;
            open(vw);

            fig = figure('Visible','off', 'Color','w', 'Position',[100,100,720,540]);
            ax = axes(fig, 'Color','w', ...
                'XColor',[0.15,0.15,0.15], 'YColor',[0.15,0.15,0.15], 'ZColor',[0.15,0.15,0.15]);
            axis(ax, 'equal'); grid(ax, 'on');
            ax.GridColor = [0.75, 0.75, 0.75];
            xlabel(ax, 'East',  'Color',[0.15,0.15,0.15]);
            ylabel(ax, 'North', 'Color',[0.15,0.15,0.15]);
            zlabel(ax, 'Up',    'Color',[0.15,0.15,0.15]);
            xlim(ax, [-lim, lim]);
            ylim(ax, [-lim, lim]);
            zlim(ax, [-lim, lim]);
            view(ax, 135, 25);

            fprintf('Attitude MP4: %d frames (%d faces)...\n', ...
                numel(t_anim), size(F,1));

            % ======== 初期描画（patch・ライト・タイトルを一度だけ作成） ========
            q0 = q_anim(:, 1);
            Rbg0 = quaternion.q_DCM(q0)';
            V_gnd = (Rbg0 * V_body')';
            hp = patch(ax, 'Faces', F, 'Vertices', V_gnd, ...
                'FaceVertexCData', face_colors, ...
                'FaceColor', 'interp', ...
                'EdgeColor', 'none', ...
                'FaceLighting', 'gouraud', ...
                'AmbientStrength', 0.4, ...
                'BackFaceLighting', 'reverselit');
            hold(ax, 'on');
            camlight(ax, 'headlight');
            camlight(ax, 'left');
            ht = title(ax, sprintf('t = %.2f s', t_anim(1)), ...
                'Color',[0.1,0.1,0.1], 'FontSize', 11);

            % ======== アニメーションループ（頂点とタイトルのみ更新） ========
            for k = 1:numel(t_anim)
                q = q_anim(:, k);
                Rbg = quaternion.q_DCM(q)';   % body → ground
                V_gnd = (Rbg * V_body')';     % 回転適用 → N×3
                set(hp, 'Vertices', V_gnd);
                set(ht, 'String', sprintf('t = %.2f s', t_anim(k)));
                drawnow;
                frame = getframe(fig);
                writeVideo(vw, frame);
            end

            close(vw);
            close(fig);
            disp(['Attitude MP4 saved: ', mp4_fn]);
        end

        %------------------------------------------------------------------
        function output_wind(obj)
            % 上空風プロファイル（高度-風速グラフ）と PowerLaw 用 CSV を出力。
            %   - PowerLaw  : (Vw0, Wpsi) の組ごとに 1 枚 / 1 CSV
            %   - MSM, csv  : 1 シミュレーションで 1 枚（CSV は対象外）
            % 出力先: <paramN>/Wind/

            do_graph = ismember("Wind Graph", obj.list_fig);
            do_csv   = ismember("Wind CSV",   obj.list_fig);
            if ~do_graph && ~do_csv, return; end

            modes = fieldnames(obj.res);
            if isempty(modes), return; end
            ms0 = obj.res.(modes{1})(1,1,1,1);
            wm = string(ms0.wind_model);

            wind_dir = obj.ensure_dir(fullfile(obj.get_output_base(), 'Wind'));

            switch wm
                case "PowerLaw"
                    if ~do_graph && ~do_csv, return; end
                    Vw0_list  = obj.Vw0(:);
                    Wpsi_list = obj.Wpsi(:);
                    for iV = 1:numel(Vw0_list)
                        Vw0_v = Vw0_list(iV);
                        z_lim = obj.max_z_for(iV);
                        if z_lim <= 0, z_lim = 1000; end
                        for iW = 1:numel(Wpsi_list)
                            % PowerLaw + Vw0=0 では Wpsi 依存性が無いため 1 ケースのみ
                            if Vw0_v == 0 && iW > 1, continue; end
                            Wpsi_v = Wpsi_list(iW);
                            if Vw0_v == 0, Wpsi_v = 0; end

                            suffix = strcat( ...
                                Calculation2.vw_token(Vw0_v), "_", ...
                                Calculation2.angle_token('Wpsi', Wpsi_v));

                            if do_graph
                                z_grid = linspace(0, z_lim, 200)';
                                vel = (z_grid / ms0.Z0).^(1/ms0.n) * Vw0_v;
                                fig = figure('Name', char(suffix), 'Visible', 'off');
                                plot(vel, z_grid + ms0.alt_st, 'b-', 'LineWidth', 1.5);
                                xlabel('Wind Speed [m/s]')
                                ylabel('Altitude [m]')
                                title(sprintf('Wind Profile (Vw0=%g m/s, Wpsi=%g deg)', ...
                                    Vw0_v, Wpsi_v))
                                grid on
                                set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on');
                                grid minor
                                saveas(fig, fullfile(wind_dir, ...
                                    char(strcat("WindProfile_", suffix, ".jpg"))));
                                close(fig);
                            end

                            if do_csv
                                % 高度グリッド: 地上高(AGL) 0〜3000 m を 1 m 間隔で記録。
                                % 機体到達高度によらず固定。CSV には射点標高を加えた
                                % 絶対高度（alt_st 〜 alt_st+3000 m）を書き込む。
                                agl_csv = (0:1:3000)';
                                alt_csv = agl_csv + ms0.alt_st;
                                % PowerLaw の風速分布は地上高(AGL)基準で計算する。
                                vel_csv = (agl_csv / ms0.Z0).^(1/ms0.n) * Vw0_v;
                                u_csv = -cosd(Wpsi_v) * vel_csv;
                                v_csv = -sind(Wpsi_v) * vel_csv;
                                % dir: wind が吹いてくる方位（北=0, CW）。
                                % wind_example.csv と同じ atan2d(-u,-v) 規約で算出。
                                if Vw0_v == 0
                                    dir_csv = zeros(size(vel_csv));
                                else
                                    dir_csv = mod(atan2d(-u_csv, -v_csv), 360);
                                end
                                csv_fn = fullfile(wind_dir, ...
                                    char(strcat("WindModel_", suffix, ".csv")));
                                fid = fopen(csv_fn, 'w', 'n', 'UTF-8');
                                fprintf(fid, ...
                                    'alt(高度),u(東向き),v(北向き),vel(速度),dir(風向)\n');
                                fclose(fid);
                                writematrix([alt_csv, u_csv, v_csv, vel_csv, dir_csv], ...
                                    csv_fn, 'WriteMode', 'append');
                            end
                        end
                    end

                case "MSM"
                    if ~do_graph, return; end
                    if isempty(ms0.MSM_lon) || isempty(ms0.MSM_z)
                        warning('output_wind: MSM data not loaded; skipping wind graph.');
                        return;
                    end
                    lon_num  = interp1(ms0.MSM_lon, 1:numel(ms0.MSM_lon),  ms0.lon,  'nearest');
                    lat_num  = interp1(ms0.MSM_lat, 1:numel(ms0.MSM_lat),  ms0.lat,  'nearest');
                    time_num = interp1(ms0.MSM_time,1:numel(ms0.MSM_time), ms0.tl,   'nearest');
                    z_prof = squeeze(ms0.MSM_z(lon_num, lat_num, :, time_num));
                    u_prof = squeeze(ms0.MSM_u(lon_num, lat_num, :, time_num));
                    v_prof = squeeze(ms0.MSM_v(lon_num, lat_num, :, time_num));
                    vel_prof = sqrt(u_prof.^2 + v_prof.^2);

                    z_lim = obj.max_z_for([]);
                    fig = figure('Name', 'WindProfile_MSM', 'Visible', 'off');
                    plot(vel_prof, z_prof, 'b-o', 'LineWidth', 1.2, 'MarkerSize', 4);
                    xlabel('Wind Speed [m/s]')
                    ylabel('Altitude [m]')
                    title('Wind Profile (MSM)')
                    grid on
                    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on');
                    grid minor
                    if z_lim > 0, ylim([min(z_prof), max(z_lim, max(z_prof))]); end
                    saveas(fig, fullfile(wind_dir, 'WindProfile_MSM.jpg'));
                    close(fig);

                case "csv"
                    if ~do_graph, return; end
                    if isempty(ms0.csv_z)
                        warning('output_wind: csv wind data not loaded; skipping wind graph.');
                        return;
                    end
                    vel_prof = sqrt(ms0.csv_u.^2 + ms0.csv_v.^2);
                    fig = figure('Name', 'WindProfile_CSV', 'Visible', 'off');
                    plot(vel_prof, ms0.csv_z, 'b-o', 'LineWidth', 1.2, 'MarkerSize', 4);
                    xlabel('Wind Speed [m/s]')
                    ylabel('Altitude [m]')
                    title('Wind Profile (CSV)')
                    grid on
                    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on');
                    grid minor
                    saveas(fig, fullfile(wind_dir, 'WindProfile_CSV.jpg'));
                    close(fig);
            end
        end

        function z_lim = max_z_for(obj, iV)
            % 風プロファイル図の高度上限。iV を渡せばその Vw0 条件、空なら全条件の max。
            % obj.res 内の MainSolver 配列の z_max を走査する。
            z_lim = 0;
            modes_local = fieldnames(obj.res);
            for iMode_l = 1:numel(modes_local)
                res_mode = obj.res.(modes_local{iMode_l});
                [ne, nv, nw, np] = size(res_mode);
                for jE = 1:ne
                    for jV = 1:nv
                        if ~isempty(iV) && jV ~= iV, continue; end
                        for jW = 1:nw
                            for jP = 1:np
                                ms_res = res_mode(jE, jV, jW, jP);
                                if isempty(ms_res.xs), continue; end
                                z_lim = max(z_lim, ms_res.z_max);
                            end
                        end
                    end
                end
            end
        end

        function show_summary(obj, tbl)
            % 各条件の特徴値テーブルを uifigure + uitable で表示する。
            % §3-5: 出力先フォルダ・総ファイル数・開くボタンを併設する。
            if nargin < 2 || isempty(tbl) || height(tbl) == 0
                msgbox('No feature values to display.', 'Calculation Finished');
                return
            end

            f = uifigure('Name', 'Calculation Finished — Feature Values', ...
                         'Position', [120, 80, 1200, 560]);
            gl = uigridlayout(f, [3, 1]);
            gl.RowHeight = {'1x', 24, 32};
            gl.ColumnWidth = {'1x'};

            t = uitable(gl, 'Data', tbl);
            t.ColumnSortable = true;
            % 数値列の桁を整える
            numericVars = varfun(@isnumeric, tbl, 'OutputFormat', 'uniform');
            fmt = cell(1, width(tbl));
            for k = 1:width(tbl)
                if numericVars(k), fmt{k} = 'short'; else, fmt{k} = 'char'; end
            end
            t.ColumnFormat = fmt;
            % ヘッダ表示は「日本語（略記）」に上書き（テーブル本体の変数名は不変）
            t.ColumnName = DisplayFigure.featureColumnLabels(tbl.Properties.VariableNames);

            base_dir = obj.get_output_base();
            n_files  = DisplayFigure.count_files_recursive(base_dir);
            info_txt = sprintf('Output: %s   |   files: %d', base_dir, n_files);
            uilabel(gl, 'Text', info_txt, 'FontSize', 11);

            btnRow = uigridlayout(gl, [1, 4]);
            btnRow.ColumnWidth = {'1x', 130, 160, 100};
            btnRow.Padding = [0 0 0 0];
            uilabel(btnRow, 'Text', sprintf('%d 条件 / %d 列', height(tbl), width(tbl)));
            uibutton(btnRow, 'Text', '出力フォルダを開く', ...
                'ButtonPushedFcn', @(~,~) DisplayFigure.open_folder(base_dir));
            uibutton(btnRow, 'Text', 'CSV エクスポート…', ...
                'ButtonPushedFcn', @(~,~) DisplayFigure.exportTableDialog(tbl, base_dir));
            uibutton(btnRow, 'Text', '閉じる', 'ButtonPushedFcn', @(~,~) close(f));
        end

        function base = get_output_base(obj)
            % Calculation2 で確定した paramN を優先し、未設定なら dir.res にフォールバック
            if ~isempty(obj.output_dir) && strlength(string(obj.output_dir)) > 0
                base = char(obj.output_dir);
            else
                base = char(obj.dir.res);
            end
        end

        function p = ensure_dir(~, p)
            % フォルダが無ければ再帰的に作成する小ヘルパ
            if ~isfolder(p), mkdir(p); end
        end
    end

    methods (Static)
        function n = count_files_recursive(p)
            % p 配下のファイル数を再帰的にカウントする（フォルダは除外）。
            n = 0;
            if isempty(p) || ~isfolder(p), return; end
            d = dir(fullfile(p, '**', '*'));
            n = sum(~[d.isdir]);
        end

        function open_folder(p)
            % プラットフォーム別にフォルダを既定アプリで開く。
            if isempty(p) || ~isfolder(p)
                warning('open_folder: %s is not a folder', p); return;
            end
            try
                if ispc
                    winopen(p);
                elseif ismac
                    system(['open "', p, '"']);
                else
                    system(['xdg-open "', p, '" &']);
                end
            catch ME
                warning(ME.identifier, 'open_folder failed: %s', ME.message);
            end
        end

        function labels = featureColumnLabels(varNames)
            % 特徴値テーブルの列名（英語識別子）を「日本語（略記）」形式に変換する。
            % 未知の列はそのまま返す。
            map = containers.Map( ...
                { 'Mode', 'Stage', ...
                  'Elev_deg', 'Vw0_mps', 'Wpsi_deg', ...
                  'z_max_m', 'Vn_lc_mps', 'Van_max_mps', 'Mach_max', ...
                  't_top_s', 'Van_top_mps', 'Va_para_mps', ...
                  'alpha_max_deg', 'beta_max_deg', 'AngleAccel_max', ...
                  'FallDist_m', 'FallE_m', 'FallN_m', 'FallLat_deg', 'FallLon_deg' }, ...
                { '降下モード（Mode）', '段（Stage）', ...
                  '射角 [deg]（Elev）', '基準風速 [m/s]（Vw0）', '風向 [deg]（Wpsi）', ...
                  '最高高度 [m]（z_max）', 'ランチクリア速度 [m/s]（Vn_lc）', ...
                  '最大対気速度 [m/s]（Van_max）', '最大マッハ数（Mach_max）', ...
                  '頂点到達時刻 [s]（t_top）', '頂点対気速度 [m/s]（Van_top）', ...
                  '開傘時対気速度 [m/s]（Va_para）', ...
                  '最大迎え角 [deg]（alpha_max）', '最大横滑り角 [deg]（beta_max）', ...
                  '最大角加速度 [rad/s^2]（AngleAccel_max）', ...
                  '落下点距離 [m]（FallDist）', '落下点東座標 [m]（FallE）', ...
                  '落下点北座標 [m]（FallN）', ...
                  '落下点緯度 [deg]（FallLat）', '落下点経度 [deg]（FallLon）' });
            labels = cell(1, numel(varNames));
            for k = 1:numel(varNames)
                key = varNames{k};
                if isKey(map, key)
                    labels{k} = map(key);
                else
                    labels{k} = key;
                end
            end
        end

        function exportTableDialog(tbl, default_dir)
            % CSV エクスポートダイアログ。show_summary のボタンから呼ぶ。
            if isempty(default_dir) || ~isfolder(default_dir)
                default_dir = pwd;
            end
            [fn, pth] = uiputfile({'*.csv','CSV (*.csv)'; '*.xlsx','Excel (*.xlsx)'}, ...
                                  'Export Feature Values', ...
                                  fullfile(default_dir, 'FeatureValues.csv'));
            if isequal(fn, 0), return; end
            try
                writetable(tbl, fullfile(pth, fn));
            catch ME
                errordlg(sprintf('Export failed: %s', ME.message), 'Export Error');
            end
        end

        function str = stage_label(n)
            % ステージ番号を "1st stage" 形式に変換
            s = num2str(n);
            switch s(end)
                case '1', str = strcat(s, 'st stage');
                case '2', str = strcat(s, 'nd stage');
                case '3', str = strcat(s, 'rd stage');
                otherwise, str = strcat(s, 'th stage');
            end
        end

        function str_color = kml_color(rgb)
            % RGB [0-1] → KML の ABGR 16進文字列
            str_color = "ff";
            for i = 3:-1:1  % KML は ABGR 順のため B,G,R の順で結合
                tmp = dec2base(round(rgb(i) * 255), 16);
                if numel(tmp) < 2, tmp = ['0', tmp]; end
                str_color = strcat(str_color, lower(tmp));
            end
        end

        function [V, F, fc, lim] = load_stl_model(stl_path)
            % STL ファイルを読み込み、機体座標系（x = 機首方向）に変換する。
            %   V  : N×3  頂点座標（body frame）
            %   F  : M×3  面インデックス
            %   fc : N×3  頂点ごとの RGB カラー
            %   lim: スカラー ビュー範囲

            TR = stlread(stl_path);
            V  = TR.Points;
            F  = TR.ConnectivityList;

            % 重心を原点に移動
            V = V - mean(V, 1);

            % 最長軸を body x 軸に割り当て
            extents = max(V) - min(V);
            [~, long_ax] = max(extents);
            other_ax = setdiff(1:3, long_ax);
            V = V(:, [long_ax, other_ax]);

            % ノーズ判定：断面積が小さい側を +x（機首）にする
            x_mid = 0;
            upper = V(V(:,1) > x_mid, 2:3);
            lower = V(V(:,1) <= x_mid, 2:3);
            if ~isempty(upper) && ~isempty(lower)
                if mean(std(upper)) > mean(std(lower))
                    % +x 側の断面が大きい → テール側 → 反転
                    V(:,1) = -V(:,1);
                    F = F(:, [1, 3, 2]);   % 面の巻き方向を補正
                end
            end

            % スケーリング（全長 ≈ 4 ユニットに正規化）
            model_len = max(V(:,1)) - min(V(:,1));
            sc = 4.0 / model_len;
            V = V * sc;

            % 頂点カラー（x 位置で ノーズ=青 / 胴体=灰 / テール=赤 に着色）
            xn = min(V(:,1));  xx = max(V(:,1));
            t = (V(:,1) - xn) / (xx - xn);        % 0 (tail) ~ 1 (nose)
            fc = repmat([0.65 0.65 0.65], size(V,1), 1);       % default: gray
            fc(t > 0.75, :) = repmat([0.25 0.45 0.90], sum(t > 0.75), 1);   % nose
            fc(t < 0.15, :) = repmat([0.85 0.15 0.10], sum(t < 0.15), 1);   % tail

            lim = max(abs(V(:))) * 1.2;
        end

        function [V, F, fc, lim] = build_procedural_model()
            % STL が無い場合のフォールバック用プロシージャルモデル。
            % patch() 用の頂点 / 面 / カラーを返す。

            r  = 0.5;  Lb = 3.0;  Ln = 1.2;
            Lf = 0.9;  rf = 1.0;
            n_th = 36;  n_ax = 12;  n_nose = 12;
            th = linspace(0, 2*pi, n_th)';

            V_all = zeros(0, 3);
            F_all = zeros(0, 3);
            fc_all = zeros(0, 3);

            % --- 胴体 (三角メッシュ) ---
            bx = linspace(-Lb/2, Lb/2, n_ax);
            for i = 1:n_ax-1
                for j = 1:n_th-1
                    p1 = [bx(i),   r*cos(th(j)),   r*sin(th(j))];
                    p2 = [bx(i),   r*cos(th(j+1)), r*sin(th(j+1))];
                    p3 = [bx(i+1), r*cos(th(j+1)), r*sin(th(j+1))];
                    p4 = [bx(i+1), r*cos(th(j)),   r*sin(th(j))];
                    base = size(V_all,1);
                    V_all = [V_all; p1; p2; p3; p4];
                    F_all = [F_all; base+[1 2 3]; base+[1 3 4]];
                    fc_all = [fc_all; repmat([0.65 0.65 0.65], 4, 1)];
                end
            end

            % --- ノーズコーン ---
            nx = linspace(Lb/2, Lb/2+Ln, n_nose);
            nr = r * (1 - ((nx - Lb/2)/Ln).^2);
            for i = 1:n_nose-1
                for j = 1:n_th-1
                    p1 = [nx(i),   nr(i)*cos(th(j)),     nr(i)*sin(th(j))];
                    p2 = [nx(i),   nr(i)*cos(th(j+1)),   nr(i)*sin(th(j+1))];
                    p3 = [nx(i+1), nr(i+1)*cos(th(j+1)), nr(i+1)*sin(th(j+1))];
                    p4 = [nx(i+1), nr(i+1)*cos(th(j)),   nr(i+1)*sin(th(j))];
                    base = size(V_all,1);
                    V_all = [V_all; p1; p2; p3; p4];
                    F_all = [F_all; base+[1 2 3]; base+[1 3 4]];
                    fc_all = [fc_all; repmat([0.25 0.45 0.90], 4, 1)];
                end
            end

            % --- フィン (4 枚、台形) ---
            fin_xv = [-Lb/2, -Lb/2, -Lb/2+Lf*0.6, -Lb/2+Lf];
            fin_zv = [r, r+rf, r+rf, r];
            for fi = 0:3
                a = fi * pi/2;
                ca = cos(a); sa = sin(a);
                Rf = [1 0 0; 0 ca -sa; 0 sa ca];
                pts = Rf * [fin_xv; zeros(1,4); fin_zv];
                base = size(V_all,1);
                V_all = [V_all; pts'];
                F_all = [F_all; base+[1 2 3]; base+[1 3 4]];
                fc_all = [fc_all; repmat([0.85 0.15 0.1], 4, 1)];
            end

            V = V_all;  F = F_all;  fc = fc_all;
            lim = (Lb/2 + Ln + rf) * 1.2;
        end
    end
end
