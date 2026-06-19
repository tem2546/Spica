classdef Roll_control < dynamicprops
    %ROLL_CONTROL ロール制御シュミレーション用クラス
    
    properties
        %-------direct setting---------
        da_max = 20               %物理的舵角角度制限(deg)
        
        %-------Main Solver----------
        %Main Solverからの継承
        dt = 0.001;
        t_max = 20;
        d = 0;
        c_ail = 0;
        b_ail = 0;
        Cmad = 0;
        Cmad0 = 0;
        %-----------------------------
        
        da_pre = 0;
        log = [];
        steps = [];              %総ステップ数
        para = [];               %制御関数パラメーター
        method_list = [];        %制御関数メソッドリスト
        
    end
    
    methods (Hidden = true)
        function obj = Roll_control(varargin)
            %コンストラクターメソッド
            
            if isempty(varargin)    %制御関数メソッド取得
                list_tmp = methods(obj, '-full');
                list_tmp = list_tmp(contains(list_tmp, 'varargout'));
                list_tmp = erase(list_tmp, 'varargout ');
                list_tmp = erase(list_tmp, '(varargin)');
                obj.method_list = list_tmp;
            else
                %msのプロパティ呼び出し
                ms = varargin{1,1};
                ms_list = properties(ms);
                rc_list = properties(obj);
                list = ismember(rc_list,ms_list);
                list_true = rc_list(list==1);
                for i = 1:size(list_true,1)
                    obj.(list_true{i,:}) = ms.(list_true{i,:});
                    if size(obj.(list_true{i,:}),1) > 1
                        obj.(list_true{i,:}) = obj.(list_true{i,:});
                    end
                end 
            end
            %motor_simulate用プロパティ設定
            obj.steps = obj.t_max / obj.dt + 1;
            field_name = fieldnames(obj.m_log);
            for i = 1:size(field_name,1)
                obj.m_log.(field_name{i,1}) = zeros(1,obj.steps);
            end
        end
    
        function [delta_a, reset, obj] = calculate_da(obj, ms, Ab, t, Corrector2)
            %動翼舵角シミュレーション関数
            %{
            センサ値再現→制御関数実行→動翼駆動モーメント計算→モーターシミュレーション
            →バックラッシ再現→ハード舵角制限
            %}
            
            omega = ms.omega;
            Pa = ms.Pa;
            q = ms.q;
            Van = ms.Van;
            rho = ms.rho_a;
            
            [omega, Ab, Pa, obj] = obj.senser_val(omega, Ab, Pa);
            [da_ref, reset, obj] = obj.(ms.control_func)(omega, Ab, Pa ,q, Van, t, Corrector2);
            Mad = obj.calc_mad(obj.da_pre, omega(1), Van, rho);
            [da_out, obj] = obj.motor_simulate(da_ref, Mad, t, Corrector2);
            %[da_out ,obj] = obj.set_backlash(da_out);
            if abs(da_out) > obj.da_max /180*pi
                da_out = obj.da_max /180*pi * sign(da_out);
            end
            
            delta_a = da_out;
            
            if Corrector2
                obj.da_pre = delta_a;
            end
        end
    end
    
    
    properties
        %モーターシミュレーション関数用プロパティ
        m_log = struct(...
            "theta",[],...         %モーターの角度
            "theta_d",[],...       %モーターの角速度
            "theta_dd",[],...      %モーターの角加速度
            "da_out",[],...        %舵角
            "da_d",[],...          %舵角の微係数
            "da_ref",[],...        %舵角の目標値
            "e_a",[],...           %電機子電圧
            "i_a",[],...           %モーター電流
            "tau_m",[],...         %モーターのトルク[]
            "tau_d",[]);           %動翼シャフト周りのモーメント
        m_inte = 0;                %制御用積分値
            
    end
    
    methods
        function [da_out, obj] = motor_simulate(obj, da_ref, Mad, t, Corrector2)
            %モーターシミュレーション関数
            %制御関数が出した制御値に対して，実際の動翼の舵角を算出する
            
            %da_ref     舵角目標角
            %Ma_a       動翼シャフト周りモーメント
            %t          現在時刻
            %Corrector2 修正子2計算
            
            R_a = 5.53;                       %モータ抵抗
            L_a = 0.000363;                   %インダクタンス
            J_m = 4.36*10^(-7);               %モータの慣性モーメント
            J_g = 0.4*10^(-7);                %ギアの慣性モーメント
            J_f = (3.672*2+2.31)*10^(-6);     %フィン-傘歯車の慣性モーメント
            %B = 0.0001;                      %粘性摩擦係数 てきとう 今のプログラムでは不使用
            K_t = 10.9*0.001;                 %トルク定数
            w_0 = 10200/60*2*pi;              %無負荷回転数?
            i_0 = 0.0458;                     %無負荷電流?
            rho = 20;                          %ギア比
            eta = 0.98;                       %ギア効率
            e_max = 12;                       %最大電圧
          
            Kp = 100;                         %PD制御のPゲイン(てきとう)
            Ki = 0.05;
            Kd = 1.5;                         %PD制御のDゲイン(てきとう)
            
            st = min(int64(t / obj.dt + 1), int64(obj.steps));

            %プロパティから必要値の呼び出し
            theta = obj.m_log.theta(1,st);
            theta_d = obj.m_log.theta_d(1,st);
            da_out = obj.m_log.da_out(1,st);
            da_d = theta_d / rho;

            %PID制御でモータに与える電圧決定
            diff = da_ref - da_out;
            if Corrector2
                obj.m_inte = obj.m_inte + diff;
            end

            p = Kp * diff;
            i = Ki * obj.m_inte;
            d = -Kd * da_d;
            e_a = p + i + d;
            if abs(e_a) > e_max
                e_a = e_max * sign(e_a);
            end
            %トルクの算出
            i_a = (e_a - K_t * theta_d) / R_a;
            tau_m = K_t * i_a - K_t * i_0 / w_0 * theta_d;
            tau_d = Mad;
            %オイラー積分
            theta_dd = (tau_m - tau_d / (eta * rho)) / (J_m + J_g + J_f / (eta * rho));
            theta_d_n = theta_d + theta_dd * obj.dt;
            theta_n = theta + theta_d * obj.dt;
            da_out_n = theta_n / rho;

            %ログの保存（配列範囲内のみ書き込み）
            if st < obj.steps
                obj.m_log.theta(1,st+1) = theta_n;
                obj.m_log.theta_d(1,st+1) = theta_d_n;
                obj.m_log.da_out(1,st+1) = da_out_n;
            end
            obj.m_log.theta_dd(1,st) = theta_dd;
            obj.m_log.da_d(1,st) = da_d;
            obj.m_log.da_ref(1,st) = da_ref;
            obj.m_log.e_a(1,st) = e_a;
            obj.m_log.i_a(1,st) = i_a;
            obj.m_log.tau_m(1,st) = tau_m;
            obj.m_log.tau_d(1,st) = tau_d;
        end
        
        function Mad = calc_mad(obj, da_pre, omega_x, Van, rho)
            if Van <= 0
                Mad = 0;
                return;
            end
            loc_alp = da_pre - (omega_x * obj.b_ail/2) / Van;
            S = pi * (obj.d)^2 / 4;
            Mad = 1/2 * (obj.Cmad * loc_alp + obj.Cmad0 * sign(loc_alp)) * S * obj.c_ail * rho * Van^2;
        end
        
    end
    
    properties
        %senser_val関数用プロパティ
        
        hz_omega = 1000;
        hz_Ab = 1000;
        hz_Pa = 60;
        
        
        
        
    end
    
    methods
        function [omega, Ab, Pa, obj] = senser_val(obj, omega, Ab, Pa)
            % 各センサのロギング周波数及びノイズ再現用関数

            % 現在のステップ数
            st = int64(length(obj.log) + 1);

            % --- 角速度センサ (ジャイロ) ---
            if mod(st, round(1/(obj.dt*obj.hz_omega))) == 0
                % ノイズ付加 (例: 標準偏差0.01 rad/s)
                omega = omega + 0.01 * randn(size(omega));
            end

            % --- 加速度センサ ---
            if mod(st, round(1/(obj.dt*obj.hz_Ab))) == 0
                % ノイズ付加 (例: 標準偏差0.1 m/s^2)
                Ab = Ab + 0.1 * randn(size(Ab));
            end

            % --- 圧力センサ ---
            if mod(st, round(1/(obj.dt*obj.hz_Pa))) == 0
                % ノイズ付加 (例: 標準偏差5 Pa)
                Pa = Pa + 5 * randn(size(Pa));
            end

            % ログ保存（必要なら）
            obj.log(end+1).omega = omega;
            obj.log(end).Ab = Ab;
            obj.log(end).Pa = Pa;
        end
        
        function [real_da ,obj] = set_backlash(obj,da_out)
            %バックラッシ再現関数
            
            %未実装
            
            
        end
    end
    
end