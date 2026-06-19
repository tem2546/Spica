function [delta_a, reset, obj] = PIControl(obj, omega, Ab, Pa, q, Van, t, Corrector2)
    %PICONTROL 燃焼終了後PI制御によるロール角制御関数
    %{
    制御概要
        燃焼終了まで待機（機軸方向加速度 Ab(1) < 0 で判定）。
        終了後、目標ロール角との偏差 d に対して PI 制御を行い、
        現在の動翼舵角に補正量を加算して指令値とする。
          da_ref = da_current + Kp * d + Ki * ∫d dt

    パラメータ (para)
        target : 目標ロール角 [rad]  (default 0)
        Kp     : 比例ゲイン          (default 0.1)
        Ki     : 積分ゲイン          (default 0.01)
    %}

    % 制御パラメータ
    para = struct(...
        "target", 0, ...              % 目標ロール角 [rad]
        "Kp", 0.1, ...               % 比例ゲイン
        "Ki", 0.01, ...              % 積分ゲイン
        "da_max", 20);               % 舵角最大値 [deg]

    % 保存ログ
    log = struct(...
        "eta", [], ...               % ロール角 [rad]
        "d", [], ...                 % 偏差 [rad]
        "da_ref", [], ...            % 舵角指令値 [rad]
        "theta", []);                % 姿勢角θ [rad]

    % ステップ間保存用
    memo = struct(...
        "step", 0, ...               % 制御段階 (0:待機, 1:制御中)
        "target_tmp", 0, ...         % ラッピング補正後の目標角
        "eta_pre", 0, ...            % 前ステップのロール角
        "d_pre", 0, ...              % 前ステップの偏差
        "inte", 0);                  % 偏差の積分値

    % 初期化
    if isempty(obj.para)
        obj.para = para;
        obj.log = log;
    end
    if ~isprop(obj, "memo")
        obj.addprop("memo");
        obj.memo = memo;
    end

    reset = false;
    eta = angle_eta(q);
    theta = angle_theta(q);
    d_val = 0;

    switch obj.memo.step
        case 0 % 燃焼終了まで待機
            delta_a = 0;
            if Corrector2 && Ab(1) < 0        % 機軸加速度が負 → 燃焼終了
                obj.memo.step = 1;
                reset = true;
                % 目標角のラッピング補正
                if abs(para.target - eta) > pi
                    if para.target - eta > 0
                        obj.memo.target_tmp = para.target - 2*pi;
                    else
                        obj.memo.target_tmp = para.target + 2*pi;
                    end
                else
                    obj.memo.target_tmp = para.target;
                end
                obj.memo.eta_pre = eta;
                obj.memo.d_pre = obj.memo.target_tmp - eta;
            end

        case 1 % PI制御実行
            % ロール角のラッピング処理（前ステップとの不連続を解消）
            while abs(obj.memo.eta_pre - eta) > pi
                if obj.memo.eta_pre - eta > 0
                    eta = eta + 2*pi;
                else
                    eta = eta - 2*pi;
                end
            end

            % 偏差
            d_val = obj.memo.target_tmp - eta;

            % 積分値更新（台形則）
            inte = obj.memo.inte + (obj.memo.d_pre + d_val) / 2 * obj.dt;
            if Corrector2
                obj.memo.d_pre = d_val;
                obj.memo.inte = inte;
                obj.memo.eta_pre = eta;
            end

            % PI制御: 現在の舵角 + Kp * d + Ki * ∫d dt
            delta_a = obj.da_pre + para.Kp * d_val + para.Ki * inte;
    end

    % 舵角制限
    da_limit = para.da_max / 180 * pi;
    if abs(delta_a) > da_limit
        delta_a = da_limit * sign(delta_a);
    end

    % データ保存
    if Corrector2
        obj.log.eta = [obj.log.eta, eta];
        obj.log.d = [obj.log.d, d_val];
        obj.log.da_ref = [obj.log.da_ref, delta_a];
        obj.log.theta = [obj.log.theta, theta];
    end


    function eta = angle_eta(q)
        % ロール角算出用関数
        q0 = q(1); q1 = q(2); q2 = q(3); q3 = q(4);
        V1 = [1;0;0];
        V2 = [2*(q1*q2-q0*q3); q0^2-q1^2+q2^2-q3^2; 0];
        eta = acos(dot(V1,V2) / (norm(V1)*norm(V2)));
        if isequal(V2, [-1;0;0])
            eta = pi;
        end
        if V2(2) < 0
            eta = 2 * pi - eta;
        end
    end

    function theta = angle_theta(q)
        % 姿勢角θ（鉛直ベクトルと機軸ベクトルの成す角）算出用関数
        V1 = [0;0;1];
        V2 = quaternion.q_rot([1;0;0], q);
        theta = acos(dot(V1,V2) / (norm(V1)*norm(V2)));
    end

end
