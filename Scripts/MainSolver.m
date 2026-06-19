%Spica
%ロケットのパラメータ設定及び計算用クラス
%-------------------------------------------------------------------------%
classdef MainSolver
    properties
        %初期化
        debug

        general_setting;

        %-------------------Parameters of Rocket---------------------------


        %-----structure-----
        L = 0;                  %機体全長
        Xs = 0;                 %構造重心位置
        Ms = 0;                 %構造質量
        d = 0;                  %機体外径
        Xl1 = 0;                %上部ランチラグ位置
        Xl2 = 0;                %下部ランチラグ位置
        Xl = 0;                 %最上部残存ランチラグ
        lug_error = 0;          %ランチラグ位相ズレによるランチャに対する傾き
        c_ail = 0;
        b_ail = 0;

        Ix = 0;                 %構造慣性モーメント(x軸)
        Iy = 0;                 %構造慣性モーメント(y軸)
        Iz = 0;                 %構造慣性モーメント(z軸)
        py_st = 'p';            %pitch/yaw対称性

        Xcg = 0;                %全機重心位置
        M = 0;                  %全機質量
        I = zeros(3)            %全機慣性テンソル@重心

        %-----aerodynamics-----
        Xcp_a = 0;              %圧力中心(対迎え角)
        Xcp_b = 0;              %圧力中心(対横滑り角)
        Xcp_a_fn = '';          %圧力中心位置データファイル名(対迎え角)
        Xcp_b_fn = '';          %圧力中心位置データファイル名(対横滑り角)
        Xac_a = 0;              %空力中心位置(対迎え角)
        Xac_b = 0;              %空力中心位置(対横滑り角)
        P_Fa = 'p';             %空力作用点
        Cx_a = 0;               %接線分力係数(対迎え角)
        Cx_b = 0;               %接線分力係数(対横滑り角)
        Cz_a = 0;                 %法線分力微係数
        Cy_b = 0;                 %横方向分力微係数
        Cac_p = 0;              %ピッチモーメント係数@空力中心
        Cac_y = 0;              %ヨーモーメント係数@空力中心
        Cl0 = 0;
        Clda = 2.25;
        Cmq = 0;                %ピッチ減衰モーメント係数
        Clp = 0;                %ロール減衰モーメント係数
        Cnr = 0;                %ヨー減衰モーメント係数
        Cmad = 0;
        Cmad0 = 0;

        %-----recovery-----
        pn = 1;                 %パラシュートの段数
        n_para = 1;             %n段目
        Vz_para = 0;            %パラ降下速度
        delay = 0;              %頂点からの開傘遅れ時間
        h_para = 0;             %開傘高度
        Cd_para = 0;            %パラ抗力係数
        S_para = 0;             %パラ投影面積
        D_para = zeros(3,1);    %パラ抗力
        l_cord = 1;             %ショックコード長

        %-----engine-----
        Xta = 0;                %タンク重心位置
        Xox = 0;                %酸化剤重心位置
        Xf = 0;                 %燃料重心位置
        Xn = 0;                 %エンジン全長
        Lf = 0;                 %グレイン長さ
        Ln = 0.03;              %ノズル長さ
        df = 0;                 %燃料外径
        Mf0 = 0;                %燃料質量
        Mf1 = 0;                %燃焼後燃料質量
        rho_f = 0;              %燃料密度
        dox = 0;                %酸化剤円柱直径
        Lox = 0;                %酸化剤高さ
        Mta = 0;                %タンク質量
        Mox0 = 0;               %酸化剤質量
        rho_ox = 0;             %酸化剤密度
        tb = 0;                 %エンジン燃焼時間
        Mox_d = 0;              %酸化剤質量流量
        Mf_d = 0;               %燃料質量流量

        Thrust = [];            %推力データ
        Thrust_t = 0;                 %推力データサイズ
        T = zeros(3,1);         %推力ベクトル
        T_set = 'Yes';          %推力履歴の読込の有無
        T_euler = zeros(3,1);   %エンジンのミスアラインメント(機体座標系に対するオイラー角表示)

        %-----multi-stage-----
        N = 1;                  %全段数
        Ns = 1;                 %ステージ番号
        type = 'r';             %ステージ種類
        mode_burn = 't';        %点火条件
        h_burn = 0;             %点火高度
        t_burn = 0;             %点火時刻
        mode_sep = 't';         %次ステージ分離条件
        Mn = 0;                 %次ステージ質量
        h_sep = 0;              %上段分離高度
        t_sep = 0;              %上段分離時刻

        %-----wind model-----
        tmp = 0;                %気温
        Pa = 0;                 %大気圧
        rho_a = 0;              %大気密度
        wind_model = 'PowerLaw';   %風速モデル選択
        Z0 = 1;                 %風向風速測定高度
        n = 1;                  %風速分布係数
        tl = 0;                 %打上時刻

        %-----MSM(NetCDF形式)関連-----
        MSM = '';            %MSMデータファイル名
        MSM_lon = [];           %経度
        MSM_lat = [];           %緯度
        MSM_p = [];             %気圧
        MSM_time = [];          %時刻
        MSM_z = [];             %ジオポテンシャル高度
    	MSM_u = [];             %xE方向風速
        MSM_v = [];             %yE方向風速
        MSM_temp = [];          %気温

        %-----launch site-----
        L_l = 0;                %ランチャ長
        z_l = 0;                %ランチャ先端高度
        L_bottom = 0;           %反射板と機体後端の距離
        h_plate = 1;            %反射板の地上からの高さ
        lat = 0;                %射点緯度
        lon = 0;                %射点経度
        g1 = 9.8;               %射場の地表面での重力加速度
        mgd = 0;                %磁気偏角（諸元表互換のため保持。内部計算は True E/N 統一のため未使用）
        land_h = 0;             %着地高度

        %-----condtion-----
        azm = 0;                    %打上方位角
        elev = 0;                   %射角
        q_l = zeros(4,1);           %ランチャ姿勢
        Vw0 = 0;                    %基準風速
        Wpsi = 0;                   %風向
        Vw_s = zeros(3,1);          %基準風速ベクトル
        wind_csv = [];
        Wind_data = [];
        csv_z = [];             %CSV z data
        csv_u = [];             %CSV u component (True-East)
        csv_v = [];             %CSV v component (True-North)
        alt_st = 0;
        alt_end = 0;

        %-----constants-----
        g0 = 9.80665;           %重力加速度
        gasR = 287.05287;       %気体定数[Nm/KgK]
        gamma = 1.403;          %空気の比熱比

        %-----geographi coordinates-----
        Re = 6378137;           %地球赤道半径
        f = 1/298.257222101;    %地球の扁平率
        e = 0;                  %楕円断面の離心率
        lat_d = 0;              %緯度1度に対応する距離
        lon_d = 0;              %経度1度に対応する距離

        %-----roll control setting-----
        rc = [];
        execute_cont = true;
        control_func = "example";
        simu_mode = "Launch";
        mode_landing = 'Hard';  % 降下モード (Hard / Descent / Both)
        rot_cond = [];
        roll_factor = "";
        Mx_csv = [];
        Mx_data = [];

        %-----aero database (動翼空力DB)-----
        aero_db = [];            % GS から受け取る {use, files(1xN struct: use,v,fn,path)}
        aero_tables = struct();  % 読込済みテーブル: 係数名ごとに struct('alpha',1xN,'delta',1xM,'v',1xK,'grid',NxMxK)
        aero_F = struct();       % 係数名ごとの griddedInterpolant（α[deg],δ[deg],V[m/s] → 値）
        has_aero_table = false;  % true: 動翼空力DBで Mx1 の Cl 項を置換 / false: 従来の諸元表方式
        aero_warn = struct('alpha', false, 'delta', false, 'v', false);  % 範囲外クランプ警告の warn-once フラグ

        %-----per-component 空力（パーツ別寄与モード, Method B）-----
        comp_aero = [];          % GS から受け取る {use, fix_delta, fn, path, delta_fixed[deg]}
        use_comp_aero = false;   % true: ピッチ/ヨーの法線力・モーメントを部品ごとに計算 / false: 従来 lumped 方式
        use_fix_delta = false;   % true: 固定舵角 δ_fixed を動翼に印加（制御関数とは独立） / false: δ_fixed=0 扱い
        delta_fixed = 0;         % 共通固定動翼角 [rad]（GS の delta_fixed[deg] から変換）
        comp = struct();         % 読込済み部品データ: name, CN_a(1xN), X_cp(1xN), movable, phi(rad), c_fixed, s_da
        Xcp_eff = 0;             % 診断用: 部品別計算から導出される実効圧力中心位置 [m]

        %-----free variables-----
        %必要な変数を使用者がその都度付け加えてください
        theta_st = 0;           %姿勢角の状態変数
        t_theta = 0;            %鉛直方向との姿勢角が30degを超える時刻
        theta_top = 0;          %頂点の姿勢角
        z_sep = 0;              %上段分離高度
        Cx2 = 0;                %接線分力係数(分離後)
        kz2 = 0;                %法線分力微係数(分離後)
        Xcp2 = 0;               %圧力中心位置(分離後)
        alpha_max = 0;          %最大迎え角
        beta_max = 0;           %最大横滑り角
        z_ns = 0;               %上段分離高度
        theta_ns = 0;           %上段分離時姿勢角
        alpha_lc = 0;           %ランチクリア時迎え角
        beta_lc = 0;            %ランチクリア時横滑り角
        AngleAccel_max = 0;     %最大角加速度(pitch,yaw成分の合計)

        %--------------------------Variables-------------------------------
        %-----times-----
        t = 0;                  %時刻
        t0 = 0;                 %初期時刻
        t_max = 100;            %計算打ち切り時刻
        freq = 200;
        dt = 0.005;        %時間刻み幅

        %-----flight status-----
        Mox_st = 0;             %酸化剤流出状態
        Mf_st = 0;              %燃料流出状態
        burn_st = 0;            %燃焼状態
        launch_clear_st = 0;    %ランチクリア状態
        top_st = 0;             %頂点到達状態
        para_st = 0;            %パラ開放状態
        sep_st = 0;             %次段分離状態
        accel_st = 0;           %加速度の初期の不連続性に対する状態変数

        %-----variables-----
        xe0 = zeros(3,1);       %初期位置@地上系
        Ve0 = zeros(3,1);       %初期速度@地上系
        q0 = zeros(4,1);        %初期姿勢(クォータニオン)
        omega0 = zeros(3,1);    %初期角速度
        Mf = 0;                 %燃料質量
        Mox = 0;                %酸化剤質量

        xe = zeros(3,1);        %位置ベクトル@地上系
        Ve = zeros(3,1);        %絶対速度ベクトル@地上系
        q = zeros(4,1);         %クォータニオン
        omega = zeros(3,1);     %角速度ベクトル

        xe_dot = zeros(3,1);
        Ve_dot = zeros(3,1);
        q_dot = zeros(4,1);
        omega_dot = zeros(3,1);
        M_dot = 0;
        I_dot = zeros(3);

        Vw = zeros(3,1);        %風速ベクトル
        Va = zeros(3,1);        %対気速度ベクトル
        Van = 0;                %対気速度の大きさ
        Vs = 0;                 %音速
        Mach = 0;               %マッハ数

        %-----aerodynamic forces-----
        Xcp = zeros(3,1);       %圧力中心位置
        a = 0;                  %圧力中心位置データ(対迎え角)
        b = 0;                  %圧力中心位置データ(対横滑り角)
        Xac = zeros(3,1);       %空力中心位置
        Cf = zeros(3,1);        %空力係数
        Cac = zeros(3,1);       %空力モーメント係数@空力中心
        Cmd = zeros(3,1);       %空力減衰モーメント係数
        Fa = 0;                 %空気力ベクトル
        Ma = 0;                 %空力モーメントベクトル
        Mj = 0;                 %ジェットダンピングモーメントベクトル

        %-----Feature Values-----
        Vn_lc = 0;              %ランチクリア速度
        t_lc = zeros(1,2);      %ランチクリア時刻
        Van_max = 0;            %最大対気速度
        Mach_max = 0;           %最大マッハ数
        Accel_max = 0;          %最大加速度
        top = zeros(3,1);       %頂点座標
        z_max = 0;              %最高高度
        t_top = 0;              %頂点到達時刻
        Van_top = 0;            %頂点対気速度
        t_para = 0;             %開傘時刻
        Va_para = 0;            %開傘時対気速度
        t_landing = 0;          %着地時刻


        para_t = 0;             %開傘時刻（dynamics内で自動設定）

        %-----------------------------Solver-------------------------------
        %-----flags-----
        %ソルバー制御
        ode_flag = [1 1];
        Corrector2 = true;

        %-----ode_adamsの出力-----
        ts = [];
        xs = [];
        ys = [];
        fs = [];

       num = 0;

    end

    methods
        function obj = MainSolver(gs, stage)    %各種パラメータファイル読込, 初期値・定数設定
            %GSクラスのプロパティを代入
            gs_list = properties(gs);
            ms_list = properties(obj);
            list = ismember(ms_list,gs_list);
            list_true = ms_list(list==1);
            for i = 1:size(list_true,1)
                obj.(list_true{i,:}) = gs.(list_true{i,:});
                if size(obj.(list_true{i,:}),1) > 1
                    obj.(list_true{i,:}) = obj.(list_true{i,:})(stage,:);
                end
            end

            % MSM: GS では struct('fn','path')、MS では文字列のため変換
            if isstruct(obj.MSM) && isfield(obj.MSM, 'fn')
                obj.MSM = char(obj.MSM.fn);
            end

            obj.general_setting = gs;

            % multi_stage=true when param.fn is a string/cell array per stage.
            % Select the file for the current stage if such an array is provided.
            pfn   = obj.general_setting.param.fn;
            ppath = obj.general_setting.param.path;
            if iscell(pfn),   pfn   = string(pfn);   end
            if iscell(ppath), ppath = string(ppath); end
            if isstring(pfn) && numel(pfn) > 1
                idx = min(stage, numel(pfn));
                pfn = pfn(idx);
            end
            if isstring(ppath) && numel(ppath) > 1
                idx = min(stage, numel(ppath));
                ppath = ppath(idx);
            end
            param_full = MainSolver.resolve_filepath(ppath, pfn);
            if isfile(param_full)
                param_raw = readcell(param_full,...
                    'Sheet','Spica','Range','A1:B71');
                for k = 1:size(param_raw, 1)
                    if (ischar(param_raw{k, 1})) && (param_raw{k, 1} ~= "")
                        obj.(param_raw{k, 1}) = param_raw{k, 2};
                    end
                end

                % === [暫定] ロール係数の整合オーバーライド（諸元表修正までのストップギャップ） ===
                % AVL/260610/99L_260610.ork のフィン形状（後部4枚: Cr=0.2, Ct=0.16,
                % 翼幅=0.145, LE後退=0.08, 本体半径=0.07725）から Barrowman 式で算出した値。
                % 諸元表の Clp(=-0.068) は基準長が d でなく L 系のため約235倍小さく、d² で
                % 評価する Md(ロール)では減衰不足で発散する。同一フィンから求めた整合ペアに置換する。
                % ※ 諸元表に正しい Clp(d基準) と Clda を入れたら、この4行を削除すること。
                %ロール舵効き係数 dCl/dδ [1/rad] (Barrowman, 4枚カント)
                obj.Clp  = -16.0;   %ロール減衰係数 [1/rad] (Barrowman, d基準・pd/2V無次元化)
                % === [暫定] ここまで ===

                if obj.type == 'r'
                    switch obj.py_st
                        case 'p'        %pitch 系のパラメータを使用
                            obj.Xcp = [0; obj.Xcp_a; obj.Xcp_a];
                            if strcmp(obj.P_Fa,'d')
                                cp_full = MainSolver.resolve_filepath( ...
                                    obj.general_setting.cp.path, obj.general_setting.cp.fn);
                                obj.a = readmatrix(cp_full);
                                a0 = obj.a(:,ismember(obj.a(1,:),0));
                                a1 = obj.a(:,ismember(obj.a(1,:),0)==0);
                                if isempty(a0)
                                    obj.a = [-fliplr(a1(1,:)), a1(1,:);
                                        fliplr(a1(2,:)), a1(2,:)];
                                else
                                    obj.a = [-fliplr(a1(1,:)), a0(1,:), a1(1,:);
                                        fliplr(a1(2,:)), a0(2,:), a1(2,:)];
                                end
                            else
                                obj.a = obj.Xcp;
                            end
                            obj.b = obj.a;
                            obj.Xac = [0; obj.Xac_a; obj.Xac_a];
                            obj.Cf = [obj.Cx_a; obj.Cz_a; obj.Cz_a];
                            obj.Cac = [0; obj.Cac_p; obj.Cac_p];
                            obj.Cmd = [obj.Clp; obj.Cmq; obj.Cmq];
                        case 'y'        %yaw 系
                            obj.Xcp = [0; obj.Xcp_b; obj.Xcp_b];
                            if strcmp(obj.P_Fa,'d')
                                param_dir = fileparts(param_full);
                                [obj.Xcp_b_fn, xcp_path] = uigetfile( ...
                                    {'*.xlsx;*.csv;*.txt','Xcp data'}, 'Xcp_data', param_dir);
                                obj.Xcp_b_fn = char(obj.Xcp_b_fn);
                                obj.b = readmatrix(fullfile(xcp_path, obj.Xcp_b_fn));
                                b0 = obj.b(:,ismember(obj.b(1,:),0));
                                b1 = obj.b(:,ismember(obj.b(1,:),0)==0);
                                if isempty(b0)
                                    obj.b = [-fliplr(b1(1,:)), b1(1,:);
                                        fliplr(b1(2,:)), b1(2,:)];
                                else
                                    obj.b = [-fliplr(b1(1,:)), b0(1,:), b1(1,:);
                                        fliplr(b1(2,:)), b0(2,:), b1(2,:)];
                                end
                            else
                                obj.b = obj.Xcp;
                            end
                            obj.a = obj.b;
                            obj.Xac = [0; obj.Xac_b; obj.Xac_b];
                            obj.Cf = [obj.Cx_a; obj.Cy_b; obj.Cy_b];
                            obj.Cac = [0; obj.Cac_y; obj.Cac_y];
                            obj.Cmd = [obj.Clp; obj.Cnr; obj.Cnr];
                        case 'n'        %対称性なし
                            obj.Xcp = [0; obj.Xcp_a; obj.Xcp_b];
                            obj.a = obj.Xcp;
                            obj.b = obj.a;
                            %{
                            if strcmp(obj.P_Fa,'d')
                                obj.a = readmatrix(strcat(obj.general_setting.cp.path,'\',obj.general_setting.cp.fn),'Sheet','pitch');
                                a0 = obj.a(:,ismember(obj.a(1,:),0));
                                a1 = obj.a(:,ismember(obj.a(1,:),0)==0);
                                if isempty(a0)
                                    obj.a = [-fliplr(a1(1,:)), a1(1,:);
                                        fliplr(a1(2,:)), a1(2,:)];
                                else
                                    obj.a = [-fliplr(a1(1,:)), a0(1,:), a1(1,:);
                                        fliplr(a1(2,:)), a0(2,:), a1(2,:)];
                                end
                            else
                                obj.a = obj.Xcp;
                            end
                            if strcmp(obj.P_Fa,'d')
                                obj.b = readmatrix(strcat(obj.general_setting.cp.path,'\',obj.general_setting.cp.fn),'Sheet','yaw');
                                b0 = obj.b(:,ismember(obj.b(1,:),0));
                                b1 = obj.b(:,ismember(obj.b(1,:),0)==0);
                                if isempty(b0)
                                    obj.b = [-fliplr(b1(1,:)), b1(1,:);
                                        fliplr(b1(2,:)), b1(2,:)];
                                else
                                    obj.b = [-fliplr(b1(1,:)), b0(1,:), b1(1,:);
                                        fliplr(b1(2,:)), b0(2,:), b1(2,:)];
                                end
                            else
                            end
%}
                            obj.Xac = [0; obj.Xac_a; obj.Xac_b];
                            obj.Cf = [obj.Cx_a; obj.Cy_b; obj.Cz_a];
                            obj.Cac = [0; obj.Cac_p; obj.Cac_y];
                            obj.Cmd = [obj.Clp; obj.Cmq; obj.Cnr];
                    end
                end

                obj.e = sqrt(obj.f*(2-obj.f));
                W = sqrt(1 - obj.e^2 * sind(obj.lat)^2);
                R = obj.Re * (1 - obj.e^2) / W^3;        %子午線曲率半径
                obj.lat_d = R * pi / 180;
                obj.lon_d = (obj.Re / W) * cosd(obj.lat) * pi / 180;

                % 慣性テンソル
                obj.I = readmatrix(param_full,...
                    'Sheet', 'Spica', 'Range', 'E1:G3');

                % パラシュートシート
                para_raw = readcell(param_full,...
                    'Sheet', 'Spica', 'range', 'D5:I10');
                for k = 1:6
                    if (ischar(para_raw{k, 1})) && (para_raw{k, 1} ~= "")
                        obj.(para_raw{k, 1}) = cell2mat(para_raw(k, 2:obj.pn+1));
                    end
                end
            else
                warning('Parameter File is NOT FOUND! (%s)', param_full)
            end

            obj.land_h = obj.alt_end;   % 落下地点の海抜高度を反映
            obj.freq = 1 / obj.dt;

            switch obj.type
                case 'r'
                    obj.M = obj.Ms + obj.Mf0 + obj.Mox0 + obj.Mta;  %機体質量
                    obj.Xcg = (obj.Xs*obj.Ms + obj.Xf*obj.Mf0 + obj.Xox*obj.Mox0 + obj.Xta*obj.Mta)/obj.M;  %機体重心
                case 'p'
                    obj.M = obj.Ms;
                    obj.Xcg = obj.Xs;
            end

            %推力データ読込
            if strcmp(obj.simu_mode, "Launch")
                switch obj.type
                    case 'r'
                        if strcmp(obj.T_set, 'Yes')
                            thrust_full = MainSolver.resolve_filepath( ...
                                obj.general_setting.thrust.path, obj.general_setting.thrust.fn);
                            obj.Thrust = readmatrix(thrust_full);
                            obj.Thrust_t = obj.Thrust(size(obj.Thrust,1),1);        %推力データのサイズ
                            if obj.Ns == 1
                                obj.t_burn = 0;
                                obj.burn_st = 1;
                            end
                        end
                    case 'p'
                        obj.Thrust = 0;
                        obj.t_burn = 0;
                end
            else
                obj.burn_st = 2;
            end



            %多段式
            if obj.Ns < obj.N
                obj.sep_st = 1;
            end

            %動翼空力データベース（aero DB）の読込
            obj = obj.load_aero_db();

            %パーツ別空力寄与モード（Method B）の読込
            obj = obj.load_comp_aero();

            cd(obj.general_setting.dir.scr)
        end

        function obj = load_aero_db(obj)
            % 動翼空力データベース（α-δ-V の 3D テーブル）を読み込む。
            %   各ファイル = ひとつの解析流速 v における係数シート群（シート "Cl" 必須, "Xcp"/"Cm"/"Cz"/"Cmad" は任意）。
            %   各シートは「1行目(B1以降)=δ[deg], 1列目(A2以降)=α[deg], それ以外=係数値」の 2D グリッド。
            %   use=true のファイル（2個以上, v は互いに異なる正値）を v 軸として積み上げ、補間に使用する。
            obj.has_aero_table = false;
            obj.aero_tables = struct();
            obj.aero_F = struct();
            obj.aero_warn = struct('alpha', false, 'delta', false, 'v', false);

            adb = GeneralSetting2.normalizeAeroDb(obj.aero_db);
            obj.aero_db = adb;
            if ~adb.use || ~obj.execute_cont
                return;   % DB 未使用 or ロール制御無効 → 従来の諸元表方式（Cl0 + Clda·δa）
            end

            % --- use=true のファイルを収集 ---
            vsel = [];
            fsel = strings(0,1);
            for k = 1:numel(adb.files)
                fk = adb.files(k);
                if fk.use && strlength(string(fk.fn)) > 0
                    vsel(end+1,1) = double(fk.v); %#ok<AGROW>
                    fsel(end+1,1) = string(MainSolver.resolve_filepath(fk.path, fk.fn)); %#ok<AGROW>
                end
            end
            if numel(vsel) < 2
                error('MainSolver:aeroDB', ...
                    '動翼空力DBを使用するには「使用」にしたファイルが2個以上必要です（解析流速 v の補間のため）。現在 %d 個です。', numel(vsel));
            end
            if any(~isfinite(vsel)) || any(vsel <= 0)
                error('MainSolver:aeroDB', '動翼空力DBの解析流速 v は 0 より大きい有限値である必要があります。');
            end
            [vsorted, ord] = sort(vsel(:).');
            if any(diff(vsorted) <= 0)
                error('MainSolver:aeroDB', '動翼空力DBの解析流速 v は互いに異なる値である必要があります（指定値: %s）。', mat2str(vsorted));
            end
            fsorted = fsel(ord);
            K = numel(vsorted);
            for s = 1:K
                if ~isfile(fsorted(s))
                    error('MainSolver:aeroDB', '動翼空力DBファイルが見つかりません: %s', fsorted(s));
                end
            end

            % --- 係数シートを読み込む ---
            coeffNames = {'Cl', 'Xcp', 'Cm', 'Cz', 'Cmad'};
            T = struct();
            F = struct();
            for c = 1:numel(coeffNames)
                nm = coeffNames{c};
                haveAll = true;
                for s = 1:K
                    if ~ismember(string(nm), string(sheetnames(fsorted(s))))
                        haveAll = false;
                        break;
                    end
                end
                if ~haveAll
                    if strcmp(nm, 'Cl')
                        error('MainSolver:aeroDB', '動翼空力DBファイルにシート "Cl" が必要ですが見つかりません: %s', fsorted(s));
                    end
                    continue;   % 任意係数シート → 無ければスキップ
                end
                alpha0 = []; delta0 = []; G = [];
                for s = 1:K
                    raw = readmatrix(fsorted(s), 'Sheet', nm);
                    if size(raw,1) < 3 || size(raw,2) < 3
                        error('MainSolver:aeroDB', ...
                            '動翼空力DB シート "%s" (%s) の形式が不正です（1行目=δ[deg], 1列目=α[deg], それ以外=値, 各2点以上必要）。', nm, fsorted(s));
                    end
                    delta = raw(1, 2:end);
                    alpha = raw(2:end, 1).';
                    block = raw(2:end, 2:end);
                    if any(isnan(delta)) || any(isnan(alpha)) || any(isnan(block(:)))
                        error('MainSolver:aeroDB', '動翼空力DB シート "%s" (%s) に NaN/空セルが含まれています。', nm, fsorted(s));
                    end
                    if numel(alpha) < 2 || numel(delta) < 2
                        error('MainSolver:aeroDB', '動翼空力DB シート "%s" は α 軸・δ 軸ともに2点以上必要です。', nm);
                    end
                    if any(diff(alpha) <= 0) || any(diff(delta) <= 0)
                        error('MainSolver:aeroDB', '動翼空力DB シート "%s" の α 軸・δ 軸は単調増加（重複なし）である必要があります。', nm);
                    end
                    if s == 1
                        alpha0 = alpha; delta0 = delta;
                        G = zeros(numel(alpha), numel(delta), K);
                    else
                        tol_a = 1e-9 * max(1, max(abs(alpha0)));
                        tol_d = 1e-9 * max(1, max(abs(delta0)));
                        if ~isequal(size(block), [numel(alpha0), numel(delta0)]) || ...
                           numel(alpha) ~= numel(alpha0) || numel(delta) ~= numel(delta0) || ...
                           max(abs(alpha - alpha0)) > tol_a || max(abs(delta - delta0)) > tol_d
                            error('MainSolver:aeroDB', ...
                                '動翼空力DB シート "%s": ファイル間で α/δ 格子が一致していません（%s）。', nm, fsorted(s));
                        end
                    end
                    G(:,:,s) = block;
                end
                T.(nm) = struct('alpha', alpha0, 'delta', delta0, 'v', vsorted, 'grid', G);
                % 端点クランプは aero_lookup 側で行うため、'nearest' 外挿（範囲外でも NaN を返さない安全策）
                F.(nm) = griddedInterpolant({alpha0(:).', delta0(:).', vsorted(:).'}, G, 'linear', 'nearest');
            end

            obj.aero_tables = T;
            obj.aero_F = F;
            obj.has_aero_table = isfield(T, 'Cl');
            if obj.has_aero_table
                fprintf('動翼空力DB を読み込みました: %d ファイル, V = [%s] m/s, 係数 = {%s}\n', ...
                    K, strjoin(string(vsorted), ', '), strjoin(string(fieldnames(T)).', ', '));
            end
        end

        function [val, obj] = aero_lookup(obj, name, alpha_deg, delta_deg, v)
            % 動翼空力DB から係数 name を (α[deg], δ[deg], V[m/s]) で線形補間して返す。
            % テーブル範囲外は端点クランプ（外挿しない）し、各軸につき初回のみ警告する。
            tbl = obj.aero_tables.(name);
            [a,  obj.aero_warn.alpha] = MainSolver.clamp_warn(alpha_deg, tbl.alpha, '迎角 alpha [deg]', obj.aero_warn.alpha);
            [d,  obj.aero_warn.delta] = MainSolver.clamp_warn(delta_deg, tbl.delta, '舵角 delta [deg]', obj.aero_warn.delta);
            [vc, obj.aero_warn.v]     = MainSolver.clamp_warn(v,         tbl.v,     '流速 V [m/s]',     obj.aero_warn.v);
            Fi = obj.aero_F.(name);
            val = Fi(a, d, vc);
        end

        function obj = load_comp_aero(obj)
            % パーツ別空力寄与モード（Method B）の部品データを読み込む。
            %   Excel の "Components" シート（1行目=ヘッダ）から各部品の
            %   CN_a[/rad], X_cp[m], movable(0/1), phi_deg[deg], c_fixed(-1/0/1), s_da(-1/0/1) を読む。
            %   use=false なら従来 lumped 方式（Cz_a/Xcp）を使用する。
            obj.use_comp_aero = false;
            obj.comp = struct();
            ca = GeneralSetting2.normalizeCompAero(obj.comp_aero);
            obj.comp_aero = ca;
            obj.use_fix_delta = logical(ca.fix_delta);             % 固定舵角の印加 ON/OFF
            obj.delta_fixed = double(ca.delta_fixed) * pi/180;     % deg -> rad
            if ~ca.use
                return;   % パーツ別モード未使用 → 従来 lumped 方式
            end

            fpath = MainSolver.resolve_filepath(ca.path, ca.fn);
            if ~isfile(fpath)
                error('MainSolver:compAero', 'パーツ別空力ファイルが見つかりません: %s', fpath);
            end
            if ~ismember("Components", string(sheetnames(fpath)))
                error('MainSolver:compAero', 'パーツ別空力ファイルにシート "Components" が必要です: %s', fpath);
            end

            raw = readcell(fpath, 'Sheet', 'Components');
            if size(raw,1) < 2 || size(raw,2) < 4
                error('MainSolver:compAero', ...
                    'Components シートの形式が不正です（ヘッダ＋1行以上, 列: name, CN_a, X_cp, movable, phi_deg, c_fixed, s_da）。');
            end
            hdr = lower(strtrim(string(raw(1,:))));
            col = @(nm) find(hdr == lower(string(nm)), 1);
            ci_name = col("name"); ci_cn = col("CN_a"); ci_xcp = col("X_cp");
            ci_mov = col("movable"); ci_phi = col("phi_deg");
            ci_c = col("c_fixed"); ci_s = col("s_da");
            if isempty(ci_cn) || isempty(ci_xcp) || isempty(ci_mov)
                error('MainSolver:compAero', 'Components シートに必須列 CN_a, X_cp, movable が見つかりません。');
            end

            body = raw(2:end,:);
            % CN_a が数値変換できる行のみ有効（末尾の空行などを除去）
            nrow = size(body,1);
            keep = false(nrow,1);
            for r = 1:nrow
                keep(r) = isfinite(MainSolver.cell2num(body{r,ci_cn}));
            end
            body = body(keep,:);
            n = size(body,1);
            if n < 1
                error('MainSolver:compAero', 'Components シートに有効な部品行がありません。');
            end

            names = strings(1,n);
            CN_a = zeros(1,n); X_cp = zeros(1,n);
            movable = false(1,n); phi = zeros(1,n);
            c_fixed = zeros(1,n); s_da = zeros(1,n);
            for r = 1:n
                if ~isempty(ci_name); names(r) = string(body{r,ci_name}); end
                CN_a(r) = MainSolver.cell2num(body{r,ci_cn});
                X_cp(r) = MainSolver.cell2num(body{r,ci_xcp});
                movable(r) = MainSolver.cell2num(body{r,ci_mov}) ~= 0;
                if movable(r)
                    if isempty(ci_phi) || isempty(ci_c) || isempty(ci_s)
                        error('MainSolver:compAero', ...
                            '可動フィン行（movable=1）には phi_deg, c_fixed, s_da 列が必要です。');
                    end
                    phi(r)     = MainSolver.cell2num(body{r,ci_phi}) * pi/180;
                    c_fixed(r) = MainSolver.cell2num(body{r,ci_c});
                    s_da(r)    = MainSolver.cell2num(body{r,ci_s});
                end
            end
            if any(~isfinite(CN_a)) || any(~isfinite(X_cp))
                error('MainSolver:compAero', 'CN_a / X_cp に数値変換できない値があります。');
            end
            bad = movable & (~ismember(c_fixed,[-1 0 1]) | ~ismember(s_da,[-1 0 1]));
            if any(bad)
                error('MainSolver:compAero', '可動フィンの c_fixed, s_da は -1 / 0 / +1 のいずれかである必要があります。');
            end

            obj.comp = struct('name',names, 'CN_a',CN_a, 'X_cp',X_cp, ...
                'movable',movable, 'phi',phi, 'c_fixed',c_fixed, 's_da',s_da);
            obj.use_comp_aero = true;

            % 整合性チェック: Σ CN_a が諸元表 Cz_a と乖離していないか
            if isnumeric(obj.Cz_a) && obj.Cz_a > 0
                rel = abs(sum(CN_a) - obj.Cz_a) / obj.Cz_a;
                if rel > 0.05
                    warning('MainSolver:compAero', ...
                        'Σ CN_a (=%.3f /rad) が諸元表 Cz_a (=%.3f /rad) と %.1f%% 乖離しています。部品データを確認してください。', ...
                        sum(CN_a), obj.Cz_a, rel*100);
                end
            end
            if obj.use_fix_delta
                fdstr = sprintf('固定舵角 ON (delta_fixed=%.2f deg)', double(ca.delta_fixed));
            else
                fdstr = '固定舵角 OFF';
            end
            fprintf('パーツ別空力モードを読み込みました: %d 部品, %s, ΣCN_a=%.3f /rad\n', ...
                n, fdstr, sum(CN_a));
        end

        function [Fab, Mfa, obj] = comp_aero_forces(obj, alpha, beta, S)
            % パーツ別空力寄与: 機体軸の空気合力 Fab=[Fx;Fy;Fz] と
            % 空力モーメント Mfa=[0; M_pitch; M_yaw] を部品ごとに計算する。
            %   各部品 i:  非可動 → 軸対称（α/β 直依存）
            %              可動フィン → 取付角 φ_i と実効迎角 α_eff,i=λ_i+δ_i で個別計算
            %   座標規約は従来 lumped 式と厳密に整合（β=0,δ=0 で一致）。ロールは別途 Mx1 で扱う。
            q = 0.5 * obj.rho_a * obj.Van^2;

            % 前ステップのロール舵角 δ_a（同一ステップ内の代数ループ回避のため da_pre を使用）
            if obj.execute_cont && ~isempty(obj.rc)
                da = obj.rc.da_pre;
            else
                da = 0;
            end
            % 固定舵角 δ_fixed の印加（OFF なら 0）。制御舵角 δ_a とは独立に重畳する。
            if obj.use_fix_delta
                dfix = obj.delta_fixed;
            else
                dfix = 0;
            end

            c = obj.comp;
            Fy = 0; Fz = 0; Mp = 0; My = 0; SFzx = 0;
            for i = 1:numel(c.CN_a)
                if c.movable(i)
                    delta_i = c.c_fixed(i)*dfix + c.s_da(i)*da;
                    cphi = cos(c.phi(i));
                    sphi = sin(c.phi(i));
                    aeff = alpha*cphi - beta*sphi + delta_i;          % 実効迎角
                    Fz_i = -q*S*c.CN_a(i)*aeff*cphi;
                    Fy_i =  q*S*c.CN_a(i)*aeff*sphi;
                else
                    Fz_i = -q*S*c.CN_a(i)*alpha;
                    Fy_i = -q*S*c.CN_a(i)*beta;
                end
                Fy = Fy + Fy_i;
                Fz = Fz + Fz_i;
                Mp = Mp + (c.X_cp(i) - obj.Xcg)*Fz_i;   % ピッチ（= 既存 -(Xcg-Xcp)*Fz の部品別和）
                My = My + (obj.Xcg - c.X_cp(i))*Fy_i;   % ヨー
                SFzx = SFzx + c.X_cp(i)*Fz_i;
            end

            Fx = -q*S*obj.Cx_a;            % 軸方向（従来通り、δ=15°補正済み Cx_a を使用）
            Fab = [Fx; Fy; Fz];
            Mfa = [0; Mp; My];
            if abs(Fz) > eps
                obj.Xcp_eff = SFzx / Fz;   % 診断用 実効圧力中心
            end
        end

        function obj = simulation(obj,Xin)  %シミュレーションのメイン関数
            % 内部計算は True E/N 系で統一。磁気偏角に関する地表座標回転は行わない。

            switch obj.wind_model
                case 'PowerLaw'
                    obj.Vw_s = -[obj.Vw0*cosd(obj.Wpsi); obj.Vw0*sind(obj.Wpsi); 0];
                case 'MSM'
                    %MSMデータの読込
                    %京都大学生存圏研究所のデータベース(以下のURL)からデータを予め取得
                    %http://database.rish.kyoto-u.ac.jp/arch/jmadata/gpv-netcdf.html
                    obj.MSM = MainSolver.resolve_filepath( ...
                        obj.general_setting.MSM.path, obj.MSM);
                    MSM_name = {'lon','lat','p','time','z','u','v','temp'};
                    for k = 1:size(MSM_name,2)
                        obj.(strcat('MSM_',MSM_name{k})) = ncread(obj.MSM, MSM_name{k});
                    end
                case 'csv'
                    % Fixed CSV format: col1=z[m AGL], col2=u[m/s True-East], col3=v[m/s True-North]
                    wind_csv_full = MainSolver.resolve_filepath( ...
                        obj.wind_csv.path, obj.wind_csv.fn);
                    data = readmatrix(wind_csv_full);
                    if size(data,2) < 3
                        error("CSV format error: need at least 3 columns (z,u,v).");
                    end
                    data = data(:,1:3);
                    good = all(isfinite(data),2);
                    data = data(good,:);
                    if isempty(data)
                        error("CSV has no valid numeric rows for (z,u,v).");
                    end
                    % Sort by AGL altitude, remove duplicates
                    [z_sorted, idx] = sort(data(:,1), 'ascend');
                    u_sorted = data(idx,2);
                    v_sorted = data(idx,3);
                    [obj.csv_z, uniq] = unique(z_sorted, 'stable');
                    obj.csv_u = u_sorted(uniq);
                    obj.csv_v = v_sorted(uniq);
                otherwise
                    warning('wind_model is NOT SELECTED!')
            end

            %初期化
            %-----フラグ-----
            obj.ode_flag = [1 1];
            %ode_flag(1)≠0の間ode_adamsを演算(t=t0+t_maxでリミット)
            %ode_flag(2)≠0でAdams法の次数kをリセット

            %-----状態変数-----
            %微分方程式が不連続になるときなどに状態をインクリメントする
            %質量
            if strcmp(obj.simu_mode, "Launch")
                obj.Mox_st = 0;
                obj.Mf_st = 0;
            else
                obj.Mox_st = 1;
                obj.Mf_st = 1;
            end
            %パラ開傘状態
            obj.para_st = 0;

            %-----初期状態-----
            %高度（1段目のみ射点高度に設定。多段式では前段の分離高度を継承する）
            if obj.Ns == 1
                Xin(3) = obj.alt_st;
            end

            %時刻
            obj.t0 = Xin(14);

            %状態変数
            if strcmp(obj.simu_mode, "Launch")
                obj.launch_clear_st = 0;    %ランチクリア状態
            else
                obj.launch_clear_st = 1;
            end
            obj.Xl = obj.Xl1;           %ランチラグ位置
            obj.top_st = 0;             %頂点到達状態

            %打上条件
            obj.elev = -abs(obj.elev);      %エラー回避のため強制的に負に上書き
            if obj.Ns == 1            %ランチクリア高度
                obj.z_l = obj.alt_st + obj.L_l * sind(-obj.elev) + obj.h_plate;
            else
                obj.L_l = obj.L - obj.Xl1 + obj.h_plate;
            end

            %姿勢
            if obj.Ns == 1
                %ランチャ姿勢
                obj.q_l = [cosd(obj.elev/2)*cosd(obj.azm/2);
                           -sind(obj.elev/2)*sind(obj.azm/2);
                           sind(obj.elev/2)*cosd(obj.azm/2);
                           cosd(obj.elev/2)*sind(obj.azm/2)];

                %初期機体姿勢
                obj.q0 = [cosd(obj.lug_error/2)*cosd(obj.elev/2)*cosd(obj.azm/2)+sind(obj.lug_error/2)*sind(obj.elev/2)*sind(obj.azm/2);
                          sind(obj.lug_error/2)*cosd(obj.elev/2)*cosd(obj.azm/2)-cosd(obj.lug_error/2)*sind(obj.elev/2)*sind(obj.azm/2);
                          cosd(obj.lug_error/2)*sind(obj.elev/2)*cosd(obj.azm/2)+sind(obj.lug_error/2)*cosd(obj.elev/2)*sind(obj.azm/2);
                          cosd(obj.lug_error/2)*cosd(obj.elev/2)*sind(obj.azm/2)-sind(obj.lug_error/2)*sind(obj.elev/2)*cosd(obj.azm/2)];

            else
                obj.q0 = Xin(7:10);
            end

            %位置
            l = obj.L - obj.Xcg + obj.L_bottom;             %反射板と機体重心の距離
            obj.xe0 = quaternion.q_rot([l;0;0],obj.q0)+Xin(1:3)+[0;0;obj.h_plate];

            %推力偏向
            obj.T_euler = [0; 0; 0];

            %ロール制御
            if obj.execute_cont
                obj.rc = Roll_control(obj);
            end
            if strcmp(obj.roll_factor, "Moment")
                Mx_full = MainSolver.resolve_filepath( ...
                    obj.Mx_csv.path, obj.Mx_csv.fn);
                obj.Mx_data = readmatrix(Mx_full);
                obj.general_setting.Cl0 = 0;
            end


            %-----緯度・経度関連-----

            %速度,角速度
            obj.Ve0 = Xin(4:6);
            obj.omega0 = Xin(11:13);

            %特徴値
            obj.Vn_lc = 0;          %ランチクリア速度
            obj.t_lc = zeros(1,2);  %ランチクリア時刻
            obj.Van_max = 0;        %最大対気速度
            obj.Mach_max = 0;       %最大マッハ数
            obj.Accel_max = 0;      %最大加速度
            obj.top = zeros(3,1);   %頂点座標
            obj.t_top = 0;          %頂点到達時刻
            obj.Van_top = 0;        %頂点対気速度
            obj.Va_para = 0;        %開傘時対気速度

            %自由変数記述欄
            obj.theta_st = 0;
            obj.z_sep = 0;
            obj.Cx2 = 1.23738;
            obj.kz2 = 8.40665;
            obj.Xcp2 = 1.51571;
            obj.alpha_max = 0;
            obj.beta_max = 0;
            obj.AngleAccel_max = 0;

            if strcmp(obj.simu_mode, "Launch")
                switch obj.type
                    case 'r'
                        X0 = [obj.xe0; obj.Ve0; obj.q0; obj.omega0; obj.Mox0; obj.Mf0];
                    case 'p'
                        X0 = [obj.xe0; obj.Ve0; obj.q0; obj.omega0; 0; 0];
                end
            else
                obj.Ve0 = quaternion.q_rot([obj.rot_cond.Va;0;0], obj.q0);
                X0 = [obj.xe0; obj.Ve0; obj.q0; obj.omega0; obj.Mox0; obj.Mf0];
            end


            [t_tmp, x_tmp, y_tmp, f_tmp, obj] = ode_adams(obj, X0, obj.t0, obj.t_max, obj.dt);
            obj.ts = t_tmp;
            obj.xs = x_tmp;
            obj.ys = y_tmp;
            obj.fs = f_tmp;

        end

        function [dx, x, y, ode_flag, obj] = dynamics(obj, t, X, Corrector2)
            %-----変数------
            obj.t = t;
            obj.xe = X(1:3);
            obj.Ve = X(4:6);
            obj.q = X(7:10);
            obj.omega = X(11:13);
            obj.Mox = X(14);
            obj.Mf = X(15);
            obj.Corrector2 = Corrector2;

            %-----環境情報-----
            if strcmp(obj.simu_mode, "Launch")
                if obj.xe(3)-obj.land_h > 0
                    z = obj.xe(3);
                else
                   z = 0;
                end
            else
                z = obj.rot_cond.z;
            end

            [obj.tmp, obj.Vs, obj.Pa, obj.rho_a] = atmos(z);
            g = obj.g0 * (obj.Re/(obj.Re + z))^2;            %高度zでの重力加速度

            switch obj.wind_model
                case 'PowerLaw'
                    z_agl = max(0, z - obj.alt_st);
                    obj.Vw = (z_agl/obj.Z0)^(1/obj.n) * obj.Vw_s;
                case 'MSM'
                    lon_num = interp1(obj.MSM_lon, 1:size(obj.MSM_lon,1), obj.lon, 'nearest');
                    %obj.longitudeに対応する列ベクトルNetCDF_lonのインデックスを得る
                    lat_num = interp1(obj.MSM_lat, 1:size(obj.MSM_lat,1), obj.lat, 'nearest');
                    %obj.latitudeに対応する列ベクトルNetCDF_latのインデックスを得る
                    time_num = interp1(obj.MSM_time, 1:size(obj.MSM_time,1), obj.tl, 'nearest');
                    %obj.launch_timeに対応する列ベクトルNetCDF_timeのインデックスを得る

                    MSM_z_tmp = obj.MSM_z(lon_num, lat_num, :, time_num);
                    MSM_z_tmp = MSM_z_tmp(:);
                    MSM_u_tmp = obj.MSM_u(lon_num, lat_num, :, time_num);
                    MSM_u_tmp = MSM_u_tmp(:);
                    MSM_v_tmp = obj.MSM_v(lon_num, lat_num, :, time_num);
                    MSM_v_tmp = MSM_v_tmp(:);
                    MSM_tmp = obj.MSM_temp(lon_num, lat_num, :, time_num);
                    MSM_tmp = MSM_tmp(:);

                    p_num = interp1(MSM_z_tmp, 1:size(MSM_z_tmp,1), z, 'linear', 'extrap');     %高度Zとジオポテンシャル高度NetCDF_zは別では？
                        %zに対応する列ベクトルMSM_pのインデックスを得る
                        %zの引数は(lon, lat, p, time)に対応する番号だから
                    Pa_tmp = interp1(1:size(obj.MSM_p,1), obj.MSM_p, p_num, 'linear', 'extrap') * 100; %[hPa]→[Pa]に変換
                    u = interp1(1:size(MSM_u_tmp,1), MSM_u_tmp, p_num, 'linear', 'extrap');
                    v = interp1(1:size(MSM_v_tmp,1), MSM_v_tmp, p_num, 'linear', 'extrap');
                    obj.tmp = interp1(1:size(MSM_tmp,1), MSM_tmp, p_num, 'linear', 'extrap');

                    obj.Vw = [u; v; 0];

                    obj.Vs = sqrt( obj.tmp * obj.gamma * obj.gasR );
                    obj.rho_a = Pa_tmp / obj.gasR / obj.tmp;
                case 'csv'
                    % Horizontal wind at current z [m] (True-East/North in ground frame)
                    u = interp1(obj.csv_z, obj.csv_u, z, 'linear', 'extrap');
                    v = interp1(obj.csv_z, obj.csv_v, z, 'linear', 'extrap');
                    obj.Vw = [u; v; 0];
            end

            obj.ode_flag = [1 0];        %ソルバー制御フラグの初期化

            %-----姿勢-----
            obj.q = obj.q/norm(obj.q);
            q_inv = quaternion.q_inv(obj.q);
            body = quaternion.q_rot([1;0;0], obj.q);
            theta = acosd(dot(body,[0;0;1]));
            if obj.theta_st == 0
                if abs(theta) < 30
                    obj.t_theta = obj.t;
                else
                    obj.theta_st = 1;
                end
            end

            %-----質量-----
            %酸化剤質量変化
            if obj.Mox_st == 0
                if obj.Mox - obj.Mox_d*obj.dt <= 0
                    obj.ode_flag(2) = 1;
                    obj.Mox_st = 1;
                end
            else
                obj.Mox_d = 0;
                obj.Mox = 0;
            end

            %燃料質量変化
            if obj.Mf_st == 0
               if obj.Mf - obj.Mf_d*obj.dt <= obj.Mf1
                   obj.ode_flag(2) = 1;
                   obj.Mf_st = 1;
               end
            else
               obj.Mf_d = 0;
               obj.Mf = obj.Mf1;
            end

            %多段式-分離
            if obj.sep_st == 1
                switch obj.mode_sep
                    case 't'
                        if obj.t >= obj.t_sep
                            obj.Ms = obj.Ms - obj.Mn;
                            obj.z_ns = z;
                            obj.theta_ns = theta;
                            %obj.Cf = [obj.Cx2; obj.kz2; obj.kz2];
                            %obj.Xcp = [0; obj.Xcp2; obj.Xcp2];
                            obj.ode_flag(2) = 1;
                        end
                    case 'a'
                        if obj.xe(3) >= obj.h_sep
                            obj.Ms = obj.Ms - obj.Mn;
                            obj.ode_flag(2) = 1;
                        end
                end
            end

            obj.M_dot = -(obj.Mox_d + obj.Mf_d);
            obj.M = obj.Ms + obj.Mta + obj.Mox + obj.Mf;

            %-----重心-----
            if obj.dox > 0
                lox_d = -obj.Mox_d/(obj.rho_ox*pi*obj.dox^2/4);     %酸化剤高さ
                Xox_d = lox_d/2;                                    %酸化剤重心
                obj.Xox = obj.Xox - Xox_d*obj.dt;              %酸化剤重心位置
            else
                obj.Xox = 0;
                Xox_d = 0;
            end

            %全機重心位置
            obj.Xcg = (obj.Xox*obj.Mox + obj.Xta*obj.Mta + obj.Xf*obj.Mf + obj.Xs*obj.Ms)/obj.M;
            %重心位置変化
            Xcg_dot = ((obj.Mf_d*obj.Xf+obj.Mox_d*obj.Xox+obj.Mox*Xox_d)-obj.Xcg*obj.M_dot)/obj.M;

            %-----慣性テンソル-----
            %燃料慣性モーメント
            di2 = obj.df^2 - 4*obj.Mf/(obj.rho_f*pi*obj.Lf);
            If = obj.Mf/12 * (3/4*(obj.df^2 + max(0, di2)) + obj.Lf^2) + obj.Mf * (obj.Xf - obj.Xcg)^2;
            If_dot = -obj.Mf_d*((obj.df^2 + max(0, di2))/16 + obj.Lf^2/12 + (obj.Xf-obj.Xcg)^2) ...
                   + obj.Mf*obj.Mf_d/(4*obj.rho_f*pi*obj.Lf) ...
                   - 2*obj.Mf*(obj.Xf-obj.Xcg)*Xcg_dot;

            %酸化剤慣性モーメント
            if obj.dox ~=0
                obj.Lox = 4 * obj.Mox / (obj.rho_ox * pi * obj.dox^2);
                Iox = obj.Mox * (obj.Lox^2/12 + obj.dox^2/16) + obj.Mox * (obj.Xox - obj.Xcg)^2;
                Iox_dot = -obj.Mox_d*(obj.Lox^2/4 + obj.dox^2/16 + (obj.Xox-obj.Xcg)^2) ...
                        + 2*obj.Mox*(obj.Xox-obj.Xcg)*(Xox_d - Xcg_dot);
            else
                Iox = 0;
                Iox_dot = 0;
            end

            %全機慣性テンソル
            obj.I = [obj.Ix, 0, 0;
                0, obj.Iy+If+Iox, 0;
                0, 0, obj.Iz+If+Iox];

            %慣性テンソル変化
            obj.I_dot = [0, 0, 0;
                0, If_dot+Iox_dot, 0;
                0, 0, If_dot+Iox_dot];

            %-----推力-----
            if strcmp(obj.simu_mode, "Launch")
                switch obj.type
                    case 'r'
                        if obj.burn_st == 0
                            if strcmp(obj.mode_burn, 'h')
                                if z > obj.h_burn
                                    obj.t_burn = obj.t;
                                    obj.burn_st = 1;
                                end
                            else
                                obj.burn_st = 1;
                            end
                        end


                        if obj.t <= obj.Thrust_t + obj.t_burn
                            Tn = interp1(obj.Thrust(:,1), obj.Thrust(:,2), obj.t - obj.t_burn,...
                                         'linear','extrap');
                            Tb = [Tn; 0; 0];
                            Tb = quaternion.q_rot(Tb, quaternion.euler_q(obj.T_euler));
                        else
                            Tb = zeros(3,1);
                        end
                    case 'p'
                        Tb = zeros(3,1);
                end
            else
                Tb = zeros(3,1);
            end

            %推力@地上系
            obj.T = quaternion.q_rot(Tb, obj.q);

            %-----重力-----
            Ge = [0; 0; -g];                    %重力@地上系
            Gb = quaternion.q_rot(Ge, q_inv);   %重力@機体系

            %-----空気力-----
            if strcmp(obj.simu_mode, "Launch")
                Vae = obj.Ve - obj.Vw;                                  %対気速度@地上系
                obj.Va = quaternion.q_rot(Vae, q_inv);                  %対気速度@機体系
                obj.Van = norm(obj.Va);
                obj.Mach = obj.Van/obj.Vs;                              %マッハ数
            else
                Vae = obj.Ve - obj.Vw;
                Vae = Vae .* obj.rot_cond.Va ./ norm(Vae);
                obj.Va = quaternion.q_rot(Vae, q_inv);
                obj.Ve = Vae + obj.Vw;
                obj.Van = obj.rot_cond.Va;
                obj.Mach = obj.Van/obj.Vs;
            end

            S = pi * obj.d^2/4;                                     %代表面積
            if obj.Van > 0
                alpha = atan2(obj.Va(3), obj.Va(1));                %迎え角
                beta = asin(max(-1, min(1, obj.Va(2)/obj.Van)));    %横滑り角
            else
                alpha = 0;
                beta = 0;
            end
            Mfa_comp = [];
            if obj.use_comp_aero
                % パーツ別寄与モード: 力・モーメントを部品ごとに計算（ロールは別途 Mx1）
                [Fab, Mfa_comp, obj] = obj.comp_aero_forces(alpha, beta, S);
            else
                Fab = - 1/2 * obj.rho_a * S * obj.Van^2 * obj.Cf.*[1; beta; alpha]; %空気合力@機体系
            end
            obj.Fa = quaternion.q_rot(Fab, obj.q);                  %空気合力@地上系

            %-----空力作用点-----
            r = zeros(3,1);
            if ~obj.use_comp_aero
            switch obj.P_Fa
                case 'c'        %圧力中心(一定)使用
                    r = obj.Xcp;
                    obj.Cac = zeros(3,1);
                case 'd'        %圧力中心(可変)使用
                    if obj.launch_clear_st == 0
                        r = [0;
                            interp1(obj.a(1,:), obj.a(2,:), 0,'linear','extrap');
                            interp1(obj.b(1,:), obj.b(2,:), 0,'linear','extrap')];
                    else
                        r = [0;
                            interp1(obj.a(1,:), obj.a(2,:), alpha*180/pi,'linear','extrap');
                            interp1(obj.b(1,:), obj.b(2,:), beta*180/pi,'linear','extrap')];
                    end
                    obj.Cac = zeros(3,1);
                case 'a'        %空力中心使用
                    r = obj.Xac;
                otherwise
                    warning('P_Fa="%s" is not recognized. Using Xcp as default.', obj.P_Fa);
                    r = obj.Xcp;
                    obj.Cac = zeros(3,1);
            end
            end

            %-----飛行状態-----
            if obj.Corrector2
                %着地判定
                if strcmp(obj.simu_mode, "Launch")
                    if (obj.launch_clear_st >= 2) && (obj.top_st > 0) && (obj.xe(3) <= obj.land_h)
                        obj.ode_flag(1) = 0;
                        obj.t_landing = obj.t;
                    end
                end

                %最大対気速度（頂点到達前のみ; Hard モードで降下時に上書きされるのを防ぐ）
                if obj.top_st == 0 && obj.Van_max < obj.Van
                    obj.Van_max = obj.Van;      %最大対気速度
                    obj.Mach_max = obj.Mach;    %最大マッハ数
                end

                %頂点到達判定
                if obj.top_st == 0
                    if obj.z_max <= obj.xe(3)
                        obj.top = obj.xe;           %頂点座標
                        obj.z_max = obj.xe(3);      %最高高度
                        obj.t_top = obj.t;          %頂点到達時刻
                        obj.Van_top = obj.Van;      %頂点対気速度
                        obj.theta_top = theta;      %頂点姿勢角
                    else
                        if (obj.launch_clear_st >= 2) && strcmp(obj.simu_mode, "Launch")
                            obj.top_st = 1;
                        end
                    end

                    %最大加速度
                    Aen = norm(obj.Ve_dot);
                    if Aen > obj.Accel_max
                        obj.Accel_max = Aen;
                    end

                    %最大角加速度
                    omega_dot_n = norm(obj.omega_dot(2:3));
                    if omega_dot_n > obj.AngleAccel_max
                        obj.AngleAccel_max = omega_dot_n;
                    end
                end
            end

            %-----運動方程式-----
            %並進
            if strcmp(obj.simu_mode, "Launch")
                obj.Ve_dot = Ge + (obj.T + obj.Fa)/obj.M;

                xlb = [obj.Xl-obj.Xcg; 0; 0];
                xl = quaternion.q_rot(xlb, obj.q);
                if obj.launch_clear_st <= 1         %ランチクリア状態
                    if obj.launch_clear_st == 0
                        if obj.xe(3)-xl(3) < obj.z_l
                            ql_inv = quaternion.q_inv(obj.q_l);
                            Vl_dot = quaternion.q_rot(obj.Ve_dot, ql_inv);
                            Vl_dot = [Vl_dot(1);0;0];
                            obj.Ve_dot = quaternion.q_rot(Vl_dot, obj.q_l);
                            if obj.accel_st == 0
                                if obj.Ns==1 && obj.Ve_dot(3)<0
                                    obj.Ve_dot = zeros(3,1);
                                else
                                    obj.ode_flag(2) = 1;
                                    obj.accel_st = 1;
                                end
                            end
                        else
                            obj.launch_clear_st = 1;
                            obj.Xl = obj.Xl2;
                            obj.t_lc(1,1) = obj.t;
                        end
                    else
                        if obj.xe(3)-xl(3) >= obj.z_l
                            if obj.Corrector2
                                obj.ode_flag(2) = 1;
                                obj.launch_clear_st = 2;
                                obj.Vn_lc = norm(obj.Ve);
                                obj.t_lc(1,2) = obj.t;
                                obj.alpha_lc = alpha;
                                obj.beta_lc = beta;
                            end
                        end
                    end
                end
            else
                obj.Ve_dot = zeros(3,1);
            end
            Vb_dot = quaternion.q_rot(obj.Ve_dot, q_inv);

            %回転
            if obj.use_comp_aero
                % パーツ別寄与モード: ピッチ/ヨーは部品別計算済み。δ 誘起モーメントを
                % 内包するため Cac 由来モーメントは 0 とする（二重計上防止）。
                Mfa = Mfa_comp;
                Mac = zeros(3,1);
            else
                l = [0;obj.Xcg;obj.Xcg] - r;
                Mfa = l.*Fab;
                Mfa = [Mfa(1);-Mfa(3);Mfa(2)];
                Mac = 1/2 * obj.rho_a * S * obj.Van^2 * obj.Cac * obj.L;
            end
            Md = 1/4*obj.rho_a*S*obj.Van*obj.Cmd.*[obj.d^2;obj.L^2;obj.L^2].*obj.omega;


            if obj.execute_cont
                [delta_a, reset, obj.rc] = obj.rc.calculate_da(obj, Vb_dot, obj.t, Corrector2);
                if reset
                    obj.ode_flag(2) = 1;
                end
            else
                delta_a = 0;
            end
            % 固定動翼角 δ_fixed のロール寄与（comp_aero_forces と同じ dfix）。
            % use_fix_delta=OFF なら 0。制御舵角 δa と同じ符号・同じ Clda で重畳する。
            if obj.use_fix_delta
                dfix = obj.delta_fixed;
            else
                dfix = 0;
            end
            if obj.has_aero_table
                % 動翼空力DB: ロール空力係数を Cl(α, δa+δfix, V) の表参照で取得（範囲外は端点クランプ）
                [Cl_total, obj] = obj.aero_lookup('Cl', alpha*180/pi, (delta_a + dfix)*180/pi, obj.Van);
            else
                % 従来方式: 線形 Cl(δ) = Cl0 + Clda·(δa + δfix)
                Cl_total = obj.general_setting.Cl0 + obj.Clda * (delta_a + dfix);
            end
            Mx1 = 1/2 * obj.rho_a * S * obj.Van^2 * Cl_total * obj.d;
            if strcmp(obj.roll_factor,"Moment")
                Mx2 = interp1(obj.Mx_data(:,1),obj.Mx_data(:,2),obj.t,'linear',0);
            else
                Mx2 = 0;
            end
            Mx = [Mx1+Mx2;0;0];

            obj.Ma = Mfa + Mac + Md + Mx;
                %↑空力モーメントベクトル
            re = obj.Xn - obj.Xcg;
            rt = re - obj.Ln;
            obj.Mj = obj.M_dot * (re*rt) .* obj.omega;          %-diag(obj.I)/obj.M
                %↑ジェットダンピングモーメントベクトル
            obj.Mj(1) = 0;                      %ロールは無視
            gyro = -cross(obj.omega, obj.I*obj.omega);

            if obj.launch_clear_st == 0
                obj.Ma = zeros(3,1);
                obj.Mj = zeros(3,1);
                gyro = zeros(3,1);
                obj.omega = zeros(3,1);
                Mg = zeros(3,1);
%             elseif obj.launch_clear_st == 1
%                 l_lug = [obj.Xl2 - obj.Xcg;0;0];
%                 Mg = cross(l_lug, Gb);
%                 l = [0;obj.Xl2;obj.Xl2] - r;
%                 Mfa = l.*Fab;
%                 Mfa = [Mfa(1);-Mfa(3);Mfa(2)];
%                 obj.Ma = Mfa + Mac + Md;
%                 obj.I = obj.I + obj.M * (obj.Xl2 - obj.Xcg)^2;
            else
                Mg = zeros(3,1);
            end

            obj.omega_dot = obj.I\(obj.Ma + obj.Mj + gyro - obj.I_dot * obj.omega + Mg);

            %-----パラシュート-----
            if obj.top_st == 1
               if strcmp(obj.mode_landing,'Descent')
                   if obj.para_st+1 <= obj.pn
                       if (obj.delay(obj.para_st+1) <= obj.t-obj.t_top) || (obj.h_para(obj.para_st+1) >= obj.xe(3))
                            obj.ode_flag(2) = 1;
                            obj.para_st = obj.para_st + 1;
                            obj.t_para = obj.t;
                        end
                   else
                       obj.para_st = obj.pn;
                   end

                   if obj.para_st > 0
                       switch obj.general_setting.descent_model
                           case 'Vw_model'
                               obj.Ve = obj.Vw + [0; 0; -obj.Vz_para(obj.para_st)];
                               obj.Ve_dot = zeros(3,1);
                               obj.omega = zeros(3,1);
                           case 'Dynamics'
                               obj.D_para = - 1/2 * obj.rho_a * obj.S_para(obj.para_st) * obj.Van^2 * obj.Cd_para(obj.para_st) * Vae/obj.Van;
                               obj.Ve_dot = obj.D_para/obj.M + Ge;
                               obj.omega = zeros(3,1);
                       end
                   end
               end
            end

            %-----位置・姿勢-----
            obj.xe_dot = obj.Ve;
            P = obj.omega(1);
            Q = obj.omega(2);
            R = obj.omega(3);
            obj.q_dot = 1/2 * [0, -P, -Q, -R;
                P, 0, R, -Q;
                Q, -R, 0, P;
                R, Q, -P, 0] * obj.q;

            %-----緯度・経度変換-----


            %-----多段式-----
            if obj.sep_st == 1
                switch obj.mode_sep
                    case 't'
                        if obj.t >= obj.t_sep
                            obj.sep_st = 2;
                            obj.z_sep = obj.xe(3);
                        end
                    case 'a'
                        if obj.xe(3) >= obj.h_sep
                            obj.sep_st = 2;
                        end
                end
            end

            %-----自由変数-----
            if obj.para_st == 0
                obj.Va_para = obj.Van;
            end
            % 迎角・横滑り角の最大値（ランチクリア後～頂点到達前まで追跡）
            % 旧コードは launch_clear_st==1 の遷移区間のみで更新していたため
            % 実質ほぼ 0 のままだった。
            if obj.launch_clear_st >= 1 && obj.top_st == 0
                if abs(alpha) >= obj.alpha_max
                    obj.alpha_max = abs(alpha);
                end
                if abs(beta) >= obj.beta_max
                    obj.beta_max = abs(beta);
                end
            end

            %-----付加状態量（extra / 審査書用 出力向け）-----
            Fst = (r(2) - obj.Xcg(1)) / obj.L * 100;     % 静安定（%）
            dp  = 0.5 * obj.rho_a * obj.Van^2 / 1000;    % 動圧（kPa）

            %-----出力-----
            dx = [ obj.xe_dot;
				obj.Ve_dot;
				obj.q_dot;
				obj.omega_dot;
				-obj.Mox_d;
				-obj.Mf_d];
            x = [obj.xe;
                obj.Ve;
                obj.q;
                obj.omega;
                obj.Mox;
                obj.Mf];
            y = [Vb_dot;
                obj.Va;
                obj.Van;
                alpha;
                beta;
                theta;
                obj.Vw;
                obj.D_para;
                Mg;
                r;
                delta_a;
                Mx1;
                Fst;
                dp];

            ode_flag = obj.ode_flag;

        end

        function [t, x, y, f, obj] = ode_adams(obj, x0, t0, t_max, dt)
            %予測子修正子法（Adams-Bashforth-Moulton PE(CE)2 法）のソルバー
            %
            %Corrector2について,
            %同じ時刻tにおいて, このソルバーはode_function()を複数回(3回)計算する.
            %このため, 直前に呼び出された値との比較によって極大値・極小値を求めようとしたとき, ほぼ同じ値を比較して,
            %その微妙な値の大小により, 極値をうまく求められない可能性がある.
            %Corrector2は同時刻tで最後にode_function()を計算する時にtrue,
            %その他の時はfalseをが与えられるようになっている. この情報を参考に条件分岐して極値を求めるとよい.

            %Adams法(Bashforth, Moulton)の係数
            k_max = 10;
            bashforth_coefficient = {
                flip(1.0) %オイラー法の係数
                flip([3.0; -1.0] / 2.0) %k=2
                flip([23.0; -16.0; 5.0] / 12.0)
                flip([55.0; -59.0; 37.0; -9.0] / 24.0)
                flip([1901.0; -2774.0; 2616.0; -1274.0; 251.0] / 720.0)
                flip([4277.0; -7923.0; 9982.0; -7298.0; 2877.0; -475.0] / 1440.0)
                flip([198721.0; -447288.0; 705549.0; -688256.0; 407139.0; -134472.0; 19087.0] / 60480.0)
                flip([434241.0; -1152169.0; 2183877.0; -2664477.0; 2102243.0; -1041723.0; 295767.0; -36799.0] / 120960.0)
                flip([14097247.0; -43125206.0; 95476786.0; -139855262.0; 137968480.0; -91172642.0; 38833486.0; -9664106.0; 1070017.0] / 3628800.0)
                flip([30277247.0; -104995189.0; 265932680.0; -454661776.0; 538363838.0; -444772162.0; 252618224.0; -94307320.0; 20884811.0; -2082753.0] / 7257600.0)
            };
            moulton_coefficient = {
                flip([1.0; 1.0] / 2.0) %修正オイラー法の係数
                flip([1.0; 1.0] / 2.0) %k=2
                flip([5.0; 8.0; -1.0] / 12.0)
                flip([9.0; 19.0; -5.0; 1.0] / 24.0)
                flip([251.0; 646.0; -264.0; 106.0; -19.0] / 720.0)
                flip([475.0; 1427.0; -798.0; 482.0; -173.0; 27.0] / 1440.0)
                flip([19087.0; 65112.0; -46461.0; 37504.0; -20211.0; 6312.0; -863.0] / 60480.0)
                flip([36799.0; 139849.0; -121797.0; 123133.0; -88547.0; 41499.0; -11351.0; 1375.0] / 120960.0)
                flip([1070017.0; 4467094.0; -4604594.0; 5595358.0; -5033120.0; 3146338.0; -1291214.0; 312874.0; -33953.0] / 3628800.0)
                flip([2082753.0; 9449717.0; -11271304.0; 16002320.0; -17283646.0; 13510082.0; -7394032.0; 2687864.0; -583435.0; 57281.0] / 7257600.0)
            };

            ns_max = t_max / dt; %ステップ数nsの最大値(無限ループを避けるため)

            %初期化
            ns = 1; %ステップ数ns

            x = zeros(size(x0, 1), ns_max); %変数x
            x(:,1) = x0; %xの初期値として与えられたx0を代入


            [f0, ~, y0, ~, obj] = obj.dynamics(t0, x(:,1), true); %f, yの初期化, 「~」は関数出力の無視をしている
            f = zeros(size(x0, 1), ns_max); %変数xの時間微分f
            f(:,1) = f0;

            y = zeros(size(y0, 1), ns_max); %変数y
            y(:,1) = y0;

            ode_flag_tmp = [1, 1]; %ode_flagの初期化(ループの実行, Step数kのリセット)

            while ode_flag_tmp(1) && (ns < ns_max) %ode_flag_tmp(1)≠0かつns<=ns_maxのときループを実行する
                %ステップ数ns, 時間tの更新
                ns = ns + 1;
                t = t0 + (ns-1) * dt;
                %Adams法のStep数kの決定
                if ode_flag_tmp(2) %Step数kのリセットフラグ(ode_flag_tmp(2)≠0)
                    k = 1;
                else
                    if k < k_max
                        k = k + 1;
                    end
                end

                %予測子( Adams-Bashforth 法)
                x(:,ns) = x(:,ns-1) + dt * my_product( f, bashforth_coefficient{k}, ns-1 );
                [f(:,ns), x(:,ns), ~, ~, obj] = obj.dynamics( t, x(:,ns), false );

                %修正子1( Adams-Moulton 法)
                x(:,ns) = x(:,ns-1) + dt * my_product( f, moulton_coefficient{k}, ns );
                [f(:,ns), x(:,ns), ~, ~, obj] = obj.dynamics( t, x(:,ns), false );

                %修正子2( Adams-Moulton 法)
                x(:,ns) = x(:,ns-1) + dt * my_product( f, moulton_coefficient{k}, ns );
                [f(:,ns), x(:,ns), y(:,ns), ode_flag_tmp, obj] = obj.dynamics( t, x(:,ns), true );
            end

            %ode_flag(1)=0で打ち切られたとき、後ろの余計なデータを除去する
            t = t0 + ( 0:(ns-1) ) * dt; %時間t
            x = x(:,1:ns);
            y = y(:,1:ns);
            f = f(:,1:ns);

            %%補助関数
                function an = my_product(f, coefficient, p)
                    %内積の計算(fをpからcoefficient次元の個数遡って列ベクトルを切り出して内積を計算する。
                    coefficient_dim = size(coefficient,1);
                    an = f(:, (p - coefficient_dim + 1):p) * coefficient;
                end
        end

    end

    methods (Static)
        function full_path = resolve_filepath(path_in, fn_in)
            % path_in がディレクトリの場合は fullfile(path_in, fn_in) を返す。
            % path_in がファイルのフルパス（UI の旧バグで fn 込みで保存された場合）の場合は
            % そのまま返す。どちらでも動作するように防御的に処理する。
            p = char(path_in);
            f = char(fn_in);
            if isfile(p)
                % path_in がすでにフルファイルパスを指している
                full_path = p;
            else
                % path_in をディレクトリとして扱い fn を結合
                full_path = fullfile(p, f);
            end
        end

        function x = cell2num(v)
            % readcell のセル値を double へ変換（数値/論理はそのまま、文字列は str2double、
            % 空セル(missing)等は NaN）。Components シート読込で使用。
            if isnumeric(v)
                x = double(v);
            elseif islogical(v)
                x = double(v);
            elseif ischar(v) || isstring(v)
                x = str2double(v);
            else
                x = NaN;
            end
        end

        function [xc, warned] = clamp_warn(x, axisvals, label, warned)
            % x を [axisvals(1), axisvals(end)] に端点クランプする（外挿しない）。
            % 範囲外だった場合、warned が false のときだけ警告を出し、warned を true にして返す。
            lo = axisvals(1);
            hi = axisvals(end);
            if x < lo
                xc = lo;
            elseif x > hi
                xc = hi;
            else
                xc = x;
                return;
            end
            if ~warned
                warning('MainSolver:aeroExtrap', ...
                    ['動翼空力DB: %s = %.4g がテーブル範囲 [%.4g, %.4g] の外側です。', ...
                     '端点にクランプして計算を続行します（この軸の警告は以降表示しません）。'], ...
                    label, x, lo, hi);
                warned = true;
            end
        end
    end

end
