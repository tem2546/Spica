%Spica
%ロケットのパラメータ設定及び計算用クラス
%-------------------------------------------------------------------------%
classdef MainSolver
    properties
        %初期化
        debug
        
        %-------------------Parameters of Rocket---------------------------
        %-----parameter file-----
        param_fn = '';          %諸元表ファイル名
        param_path = '';        %諸元表インデックス
        thrust_fn = '';         %推力履歴ファイル名
        thrust_path = '';       %推力履歴インデックス
        Xcp_fn = '';            %圧力中心位置データファイル名
        dir_scr = '';           %Scriptフォルダ
        
        %-----structure-----
        L = 0;                  %機体全長
        Xs = 0;                 %構造重心位置
        Ms = 0;                 %構造質量
        d = 0;                  %機体外径
        Xl1 = 0;                %上部ランチラグ位置
        Xl2 = 0;                %下部ランチラグ位置
        Xl = 0;                 %最上部残存ランチラグ
        lug_error = 0;          %ランチラグ位相ズレによるランチャに対する傾き
        
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
        Xac_a = 0;              %空力中心位置(対迎え角)
        Xac_b = 0;              %空力中心位置(対横滑り角)
        P_Fa = 'p';             %空力作用点
        Cx_a = 0;               %接線分力係数(対迎え角)
        Cx_b = 0;               %接線分力係数(対横滑り角)
        Cz_a = 0;               %法線分力微係数
        Cy_b = 0;               %横方向分力微係数
        Cac_p = 0;              %ピッチモーメント係数@空力中心
        Cac_y = 0;              %ヨーモーメント係数@空力中心
        Cmq = 0;                %ピッチ減衰モーメント係数
        Cnr = 0;                %ヨー減衰モーメント係数
        Clp = 0;                %ロール減衰モーメント係数
        
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
        Xox0 = 0;
        
        thrust = [];            %推力データ
        Ts = 0;                 %推力データサイズ
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
        MSM_fn = '';            %MSMデータファイル名
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
        mgd = 0;                %磁気偏角
        mode_azm = 'Magnetic';  %基準方位
        Amgd = zeros(3);        %真東→磁東変換行列(西偏正)
        land_h = 0;             %着地高度
        
        %-----condtion-----
        mode_landing = 'Hard';      %降下モード
        descent_model = 'Vw_model'; %減速落下モデル
        azm = 0;                    %打上方位角
        elev = 0;                   %射角
        q_l = zeros(4,1);           %ランチャ姿勢
        Vw0 = 0;                    %基準風速
        Wpsi = 0;                   %風向
        Vw_s = zeros(3,1);          %基準風速ベクトル
        
        %-----constants-----
        g0 = 9.80655;           %重力加速度
        gasR = 287.05287;       %気体定数[Nm/KgK]
        gamma = 1.403;          %空気の比熱比
        
        %-----geographi coordinates-----
        Re = 6378137;           %地球赤道半径
        f = 1/298.257222101;    %地球の扁平率
        e = 0;                  %楕円断面の離心率
        lat_d = 0;              %緯度1度に対応する距離
        lon_d = 0;              %経度1度に対応する距離
        
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
        freq = 200;             %推力履歴のサンプリングレート
        delta_t = 0.005;        %時間刻み幅
        
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
        dp = 0;
        
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
        dp_max = 0;
        dp_max_t = 0;
        dp_max_z = 0;
        
        
        para_t = 9;
        
        %-----------------------------Solver-------------------------------
        %-----flags-----
        %ソルバー制御
        ode_flag = [1 1];
        definitive_value = true;
        
        %-----ode_adamsの出力-----
        ts = [];
        xs = [];
        ys = [];
        fs = [];
        
        log_tmp = [];
        
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
            
            %パラメータ読込
            cd(obj.param_path)
            if isfile(obj.param_fn)
                %メインの表内
                param_raw = readcell(obj.param_fn,...
                    'Sheet','Spica','Range','A1:B66');
                for k = 1:size(param_raw, 1)
                    if (ischar(param_raw{k, 1})) && (param_raw{k, 1} ~= "")
                        obj.(param_raw{k, 1}) = param_raw{k, 2};
                    end
                end
                
                if obj.type == 'r'
                    switch obj.py_st
                        case 'p'        %pitch系のパラメータを使用
                            obj.Xcp = [0; obj.Xcp_a; obj.Xcp_a];
                            if strcmp(obj.P_Fa,'d')
                                obj.a = readmatrix(obj.Xcp_fn);
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
                        case 'y'        %yaw系
                            obj.Xcp = [0; obj.Xcp_b; obj.Xcp_b];
                            if strcmp(obj.P_Fa,'d')

                                obj.b = readmatrix(obj.Xcp_fn);
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
                            if strcmp(obj.P_Fa,'d')
                                obj.a = readmatrix(obj.Xcp_fn);
                                a0 = obj.a(:,ismember(obj.a(1,:),0));
                                a1 = obj.a(:,ismember(obj.a(1,:),0)==0);
                                if isempty(a0)
                                    obj.a = [-fliplr(a1(1,:)), a1(1,:);
                                        fliplr(a1(2,:)), a1(2,:)];
                                else
                                    obj.a = [-fliplr(a1(1,:)), a0(1,:), a1(1,:);
                                        fliplr(a1(2,:)), a0(2,:), a1(2,:)];
                                end
                                obj.a = Xcp;
                            end
                            if strcmp(obj.P_Fa,'d')
                                cd(obj.param_path)
                                [obj.Xcp_fn,path] = uigetfile('*.xlsx; *.csv; *.txt','Xcp_data vs beta');
                                obj.Xcp_fn = char(obj.Xcp_fn);
                                cd(path)
                                obj.b = readmatrix(obj.Xcp_fn);
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
                                obj.b = Xcp;
                            end
                            obj.Xac = [0; obj.Xac_a; obj.Xac_b];
                            obj.Cf = [obj.Cx_a; obj.Cy_b; obj.Cz_a];
                            obj.Cac = [0; obj.Cac_p; obj.Cac_y];
                            obj.Cmd = [obj.Clp; obj.Cmq; obj.Cnr];
                    end
                end
                
                obj.e = obj.f*(2-obj.f);
                R = obj.Re*(1-obj.f)^2/(1+obj.e*cosd(obj.lat));
                obj.lat_d = R*pi/180/3600;
                obj.lon_d = R*cosd(obj.lat)*pi/180/3600;
                
                %計算領域内
                obj.I = readmatrix(obj.param_fn,...
                    'Sheet', 'Spica', 'Range', 'E1:G3');    %慣性テンソル
                
                %パラシュート
                para_raw = readcell(obj.param_fn,...
                    'Sheet', 'Spica', 'range', 'D5:I10');
                for k = 1:6
                    if (ischar(para_raw{k, 1})) && (para_raw{k, 1} ~= "")
                        obj.(para_raw{k, 1}) = cell2mat(para_raw(k, 2:obj.pn+1));
                    end
                end
            else
                warning('Parameter File is NOT FOUND!')
            end
            
            obj.delta_t = 1./obj.freq;           %計算幅
            
            switch obj.type
                case 'r'
                    obj.M = obj.Ms + obj.Mf0 + obj.Mox0 + obj.Mta;  %機体質量
                    obj.Xcg = (obj.Xs*obj.Ms + obj.Xf*obj.Mf0 + obj.Xox*obj.Mox0 + obj.Xta*obj.Mta)/obj.M;  %機体重心
                case 'p'
                    obj.M = obj.Ms;
                    obj.Xcg = obj.Xs;
            end
            
            %推力データ読込
            switch obj.type
                case 'r'
                    if strcmp(obj.T_set, 'Yes')
                        cd(obj.thrust_path)
                        obj.thrust = readmatrix(obj.thrust_fn);
                        obj.Ts = size(obj.thrust,1);         %推力データのサイズ
                        if obj.Ns == 1
                            obj.t_burn = 0;
                            obj.burn_st = 1;
                        end
                    end
                case 'p'
                    obj.thrust = 0;
                    obj.t_burn = 0;
            end
            
            %多段式
            if obj.Ns < obj.N
                obj.sep_st = 1;
            end
            cd(obj.dir_scr)
        end
        
        function obj = simulation(obj,Xin)  %シミュレーションのメイン関数
            switch obj.mode_azm
                case 'Magnetic'
                    obj.Amgd = [cosd(obj.mgd) sind(obj.mgd) 0;
                        -sind(obj.mgd) cosd(obj.mgd) 0;
                        0 0 1];
                case 'Due'
                    obj.Amgd = eye(3);
            end
            
            switch obj.wind_model
                case 'PowerLaw'
                    obj.Vw_s = -[obj.Vw0*cosd(obj.Wpsi); obj.Vw0*sind(obj.Wpsi); 0];
                case 'MSM'
                    %MSMデータの読込
                    %京都大学生存圏研究所のデータベース(以下のURL)からデータを予め取得
                    %http://database.rish.kyoto-u.ac.jp/arch/jmadata/gpv-netcdf.html
                    obj.MSM_fn = uigetfile('*.nc','MSM_data');
                    obj.MSM_fn = char(obj.MSM_fn);
                    MSM_name = {'lon','lat','p','time','z','u','v','temp'};
                    for k = 1:size(MSM_name,2)
                        obj.(strcat('MSM_',MSM_name{k})) = ncread(obj.MSM_fn, MSM_name{k});
                    end
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
            obj.Mox_st = 0;
            obj.Mf_st = 0;
            
            %パラ開傘状態
            obj.para_st = 0;
            
            %-----初期状態-----
            %時刻
            obj.t0 = Xin(14);
            
            %状態変数
            obj.launch_clear_st = 0;    %ランチクリア状態
            obj.Xl = obj.Xl1;           %ランチラグ位置
            obj.top_st = 0;             %頂点到達状態
            
            %打上条件
            obj.elev = -abs(obj.elev);      %エラー回避のため強制的に負に上書き
            if obj.Ns == 1            %ランチクリア高度
                obj.z_l = obj.L_l * sind(-obj.elev) + obj.h_plate;
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
            
            obj.Xox0 = obj.Xox;

            %位置
            l = obj.L - obj.Xcg + obj.L_bottom;             %反射板と機体重心の距離
            obj.xe0 = quaternion.q_rot([l;0;0],obj.q0)+Xin(1:3)+[0;0;obj.h_plate];
            
            %推力偏向
            obj.T_euler = [0; 0; 0];
            
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
            
            switch obj.type
                case 'r'
                    X0 = [obj.xe0; obj.Ve0; obj.q0; obj.omega0; obj.Mox0; obj.Mf0];
                case 'p'
                    X0 = [obj.xe0; obj.Ve0; obj.q0; obj.omega0; 0; 0];
            end
            
            [ts, xs, ys, fs, obj] = ode_adams(obj, X0, obj.t0, obj.t_max, obj.delta_t);
            obj.ts = ts;
            obj.xs = xs;
            obj.ys = ys;
            obj.fs = fs;
            
        end
        
        function [dx x y ode_flag, obj] = dynamics(obj, t, X, definitive_value)
            %-----変数------
            obj.t = t;
            obj.xe = X(1:3);
            obj.Ve = X(4:6);
            obj.q = X(7:10);
            obj.omega = X(11:13);
            obj.Mox = X(14);
            obj.Mf = X(15);
            obj.definitive_value = definitive_value;

            %-----環境情報-----
            if obj.xe(3)-obj.land_h > 0
                z = obj.xe(3);
            else
               z = 0;
            end

            [obj.tmp, obj.Vs, obj.Pa, obj.rho_a] = atmos(z);
            g = obj.g0 * (obj.Re/(obj.Re + z))^2;         %高度zでの重力加速度

            switch obj.wind_model
                case 'PowerLaw'
                    obj.Vw = (z/obj.Z0)^(1/obj.n) * obj.Vw_s;
                case 'MSM'
                    lon_num = interp1(obj.MSM_lon, 1:size(obj.MSM_lon,1), obj.lon, 'nearest');
                    %obj.longitudeに対応する列ベクトルNetCDF_lonのインデックスを得る
                    lat_num = interp1(obj.MSM_lat, 1:size(obj.MSM_lat,1), obj.lat, 'nearest');
                    %obj.latitudeに対応する列ベクトルNetCDF_latのインデックスを得る
                    time_num = interp1(obj.MSM_time, 1:size(obj.MSM_time,1), obj.tl, 'nearest');
                    %obj.launch_timeに対応する列ベクトルNetCDF_timeのインデックスを得る

                    MSM_z = obj.MSM_z(lon_num, lat_num, :, time_num);
                    MSM_z = MSM_z(:);
                    MSM_u = obj.MSM_u(lon_num, lat_num, :, time_num);
                    MSM_u = MSM_u(:);
                    MSM_v = obj.MSM_v(lon_num, lat_num, :, time_num);
                    MSM_v = MSM_v(:);
                    MSM_temp = obj.MSM_temp(lon_num, lat_num, :, time_num);
                    MSM_temp = MSM_temp(:);

                    p_num = interp1(MSM_z, 1:size(MSM_z,1), z, 'spline');     %高度Zとジオポテンシャル高度NetCDF_zは別では？
                        %zに対応する列ベクトルMSM_pのインデックスを得る
                        %zの引数は(lon, lat, p, time)に対応する番号だから
                    Pa = interp1(1:size(obj.MSM_p,1), obj.MSM_p, p_num, 'spline') * 100; %[hPa]→[Pa]に変換
                    u = interp1(1:size(MSM_u,1), MSM_u, p_num, 'spline');
                    v = interp1(1:size(MSM_v,1), MSM_v, p_num, 'spline');
                    obj.tmp = interp1(1:size(MSM_temp,1), MSM_temp, p_num, 'spline');

                    obj.Vw= obj.Amgd * [u; v; 0];

                    obj.Vs = sqrt( obj.tmp * obj.gamma * obj.gasR );
                    obj.rho_a = Pa / obj.gasR / obj.tmp;
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
                if obj.Mox - obj.Mox_d*obj.delta_t <= 0
                    obj.ode_flag(2) = 1;
                    obj.Mox_st = 1;
                end
            else
                obj.Mox_d = 0;
                obj.Mox = 0;
            end
            
            %燃料質量変化
            if obj.Mf_st == 0
               if obj.Mf - obj.Mf_d*obj.delta_t <= obj.Mf1
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
            if obj.dox ~= 0
%                 lox_d = -obj.Mox_d/(obj.rho_ox*pi*obj.dox^2/4);     %酸化剤高さ
%                 Xox_d = lox_d/2;                                    %酸化剤重心
                if t < 2.88
                    Xox_d = 0.380/2/2.88;
                else
                    Xox_d = 0;
                end
                obj.Xox = obj.Xox0 + Xox_d*t;              %酸化剤重心位置
            else
                obj.Xox = 0;
                Xox_d = 0;
            end
            
            %全機重心位置
            obj.Xcg = (obj.Xox*obj.Mox + obj.Xta*obj.Mta + obj.Xf*obj.Mf + obj.Xs*obj.Ms)/obj.M;
            %重心位置変化
            Xcg_dot = ((obj.Mf_d*obj.Xf+obj.Mox_d*obj.Xox+obj.Mox*Xox_d))/obj.M;
            
            %-----慣性テンソル-----
            %燃料慣性モーメント
            If = obj.Mf/24 * (2*obj.Lf^2 + 3*(1-2*obj.Mf/(obj.rho_f*pi*obj.Lf^2)) + 24*(obj.Xf-obj.Xcg)^2);
            If_dot = obj.Mf*(obj.Mf_d/(2*pi*obj.rho_f*obj.Lf)+2*(obj.Xf-obj.Xcg)*(-Xcg_dot))-obj.Mf_d*((2*obj.Lf^2+3)/24+(obj.Xf-obj.Xcg)^2);
            
            %酸化剤慣性モーメント
            if obj.dox ~=0
                Iox = obj.Mox/48 * (64+(obj.Mox/obj.rho_ox*pi*obj.dox^2)^2 + 3*obj.dox^2 + 48*(obj.Xox-obj.Xcg)^2);
                Iox_dot = 2*obj.Mox*((obj.Xox-obj.Xcg)*(Xox_d-Xcg_dot)-2*obj.Mox_d/(obj.rho_ox*pi*obj.dox^2)^2)-obj.Mox_d*(obj.dox^2/16+(obj.Xox-obj.Xcg)^2);
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
            switch obj.type
                case 'r'
                    if obj.burn_st == 0
                        if strcmp(obj.mode_burn, 'h') && (z > obj.h_burn)
                            obj.t_burn = obj.t;
                        else
                            obj.burn_st = 1;
                        end
                    end
                        
                    thrust_num = round((obj.t - obj.t_burn)*obj.freq + 1);
                    if (thrust_num > 0) && (thrust_num <= obj.Ts)
                        Tb = [obj.thrust(thrust_num); 0; 0];
                        Tb = quaternion.q_rot(Tb, quaternion.euler_q(obj.T_euler));
                    else
                        Tb = zeros(3,1);
                    end
                case 'p'
                    Tb = zeros(3,1);
            end

            %推力@地上系
            obj.T = quaternion.q_rot(Tb, obj.q);

            %-----重力-----
            Ge = [0; 0; -g];                    %重力@地上系
            Gb = quaternion.q_rot(Ge, q_inv);   %重力@機体系
            
            %-----空気力-----
            Vae = obj.Ve - obj.Vw;                                  %対気速度@地上系
            obj.Va = quaternion.q_rot(Vae, q_inv);                  %対気速度@機体系
            obj.Van = norm(obj.Va);
            obj.Mach = obj.Van/obj.Vs;                              %マッハ数
            S = pi * obj.d^2/4;                                     %代表面積
            if obj.Van > 0
                alpha = atan2(obj.Va(3), obj.Va(1));                %迎え角
                beta = asin(obj.Va(2)/obj.Van);                     %横滑り角
            else
                alpha = 0;
                beta = 0;
            end
            Fab = - 1/2 * obj.rho_a * S * obj.Van^2 * obj.Cf.*[1; beta; alpha]; %空気合力@機体系
            obj.Fa = quaternion.q_rot(Fab, obj.q);                  %空気合力@地上系
            
            %-----空力作用点-----
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
            end
            
            %-----飛行状態-----
            if obj.definitive_value
                %着地判定
                if (obj.launch_clear_st >= 2) && (obj.top_st > 0) && (obj.xe(3) <= obj.land_h)
                    obj.ode_flag(1) = 0;
                    obj.t_landing = obj.t;
                end
                
                %最大対気速度
                if obj.Van_max < obj.Van
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
                        obj.top_st = 1;
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
            obj.Ve_dot = Ge + (obj.T + obj.Fa)/obj.M;
            Vb_dot = quaternion.q_rot(obj.Ve_dot, q_inv);
            
            xlb = [obj.Xl-obj.Xcg; 0; 0];
            xl = quaternion.q_rot(xlb, obj.q);
            if obj.launch_clear_st <= 1         %ランチクリア状態
                if obj.launch_clear_st == 0
                    if obj.xe(3)-xl < obj.z_l
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
                    if obj.xe(3)-xl >= obj.z_l
                        if obj.definitive_value
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
            
            %回転
            l = [0;obj.Xcg;obj.Xcg] - r;
            Mfa = l.*Fab;
            Mfa = [Mfa(1);-Mfa(3);Mfa(2)];
            Mac = 1/2 * obj.rho_a * S * obj.Van^2 * obj.Cac * obj.L;
            Md = 1/4*obj.rho_a*S*obj.Van*obj.Cmd.*[obj.d^2;obj.L^2;obj.L^2].*obj.omega;
                %↑空力減衰モーメントベクトル
            obj.Ma = Mfa + Mac + Md;
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
                       switch obj.descent_model
                           case 'Vw_model'
                               obj.Ve = obj.Vw + [0; 0; -obj.Vz_para(obj.para_st)];
                           case 'Dynamics'
                               obj.D_para = - 1/2 * obj.rho_a * obj.S_para * obj.Van^2 * obj.Cd_para * Vae/obj.Van;
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
            if obj.launch_clear_st == 1
                if abs(alpha) >= obj.alpha_max
                    obj.alpha_max = abs(alpha);
                end
                if abs(beta) >= obj.beta_max
                    obj.beta_max = abs(beta);
                end
            end

            Fst = (r(2)-obj.Xcg(1))/obj.L*100;
            dp = 1/2*obj.rho_a*obj.Van^2/10^3;
            extra = [Fst; dp];
           if definitive_value
               if dp > obj.dp_max && obj.top_st == 0
                   obj.dp_max = dp;
                   obj.dp_max_t = t;
                   obj.dp_max_z = obj.xe(3);
               end
           end
            
            
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
                extra];
            
            ode_flag = obj.ode_flag;
            
        end
    
        function [t, x, y, f, obj] = ode_adams(obj, x0, t0, t_max, delta_t)
            %予測子修正子法（Adams-Bashforth-Moulton PE(CE)2 法）のソルバー
            %
            %definitive_valueについて, 
            %同じ時刻tにおいて, このソルバーはode_function()を複数回(3回)計算する. 
            %このため, 直前に呼び出された値との比較によって極大値・極小値を求めようとしたとき, ほぼ同じ値を比較して, 
            %その微妙な値の大小により, 極値をうまく求められない可能性がある. 
            %definitive_valueは同時刻tで最後にode_function()を計算する時にtrue,
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

            ns_max = t_max / delta_t; %ステップ数nsの最大値(無限ループを避けるため)

            %初期化
            ns = 1; %ステップ数ns

            x = zeros(size(x0, 1), ns_max); %変数x
            x(:,1) = x0; %xの初期値として与えられたx0を代入

            [f0, ~, y0, ~, obj] = obj.dynamics(t0, x(:,1), true); %f, yの初期化, 「~」は関数出力の無視をしている
            f = zeros(size(x0, 1), ns_max); %変数xの時間微分f
            f(:,1) = f0;

            y = zeros(size(y0, 1), ns_max); %変数y
            y(:,1) = y0;

            ode_flag = [1, 1]; %ode_flagの初期化(ループの実行, Step数kのリセット)

            while ode_flag(1) && (ns < ns_max) %ode_flag(1)≠0かつns<=ns_maxのときループを実行する
                %ステップ数ns, 時間tの更新
                ns = ns + 1;
                t = t0 + (ns-1) * delta_t;
                %Adams法のStep数kの決定
                if ode_flag(2) %Step数kのリセットフラグ(ode_flag(2)≠0)
                    k = 1;
                else
                    if k < k_max
                        k = k + 1;
                    end
                end

                %予測子( Adams-Bashforth 法)
                x(:,ns) = x(:,ns-1) + delta_t * my_product( f, bashforth_coefficient{k}, ns-1 );
                [f(:,ns), x(:,ns), ~, ~, obj] = obj.dynamics( t, x(:,ns), false );

                %修正子1( Adams-Moulton 法)
                x(:,ns) = x(:,ns-1) + delta_t * my_product( f, moulton_coefficient{k}, ns );
                [f(:,ns), x(:,ns), ~, ~, obj] = obj.dynamics( t, x(:,ns), false );

                %修正子2( Adams-Moulton 法)
                x(:,ns) = x(:,ns-1) + delta_t * my_product( f, moulton_coefficient{k}, ns );
                [f(:,ns), x(:,ns), y(:,ns), ode_flag, obj] = obj.dynamics( t, x(:,ns), true );
            end

            %ode_flag(1)=0で打ち切られたとき、後ろの余計なデータを除去する
            t = t0 + ( 0:(ns-1) ) * delta_t; %時間t
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

end

