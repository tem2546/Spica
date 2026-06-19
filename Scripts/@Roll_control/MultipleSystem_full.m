function [delta_a, reset, obj] = MultipleSystem_full(obj, omega, Ab, Pa ,q, Van, t, Corrector2)
    %UNTITLED 2制御系同時制御関数
    %{
    制御概要
        角速度とカメラの撮影方向に関する制御角ηの2つの制御系を同時に実行
        2つの制御系の出力を適当な比で合成
    　　合成比はロール角速度が大きいほど角速度に関する制御系、小さいほど
        制御角ηに関する制御系に比重が置かれる
    
    %}

    %制御関数用諸パラメーター
    para = struct(...
        "start_t", 3,...                  %制御開始時刻
        "target", 0/180*pi,...            %目標角
        "Kp1", 100,...                    %角速度制御PIDゲイン
        "Ki1", 50,...
        "Kd1", 0,...
        "Kp2", 500,...                    %制御角階制御PIDゲイン
        "Ki2", 400,...
        "Kd2", 100); 
    
    %保存ログ
    log = struct(...                       %制御パラメータログ
        "omega_x",[],...                   %ロール角度 [rad/s] 
        "eta",[],...                       %制御角η [rad]
        "theta",[],...　　　　　　　　　　　%姿勢角θ [rad]
        "Van",[],...                       %対気速度 [m/s]
        "a",[],...
        "pid1",[],...
        "pid2",[],...
        "pid",[]);             

    %プロパティ保存パラメータ
    memo = struct(...
        "step",0,...                       %制御段階
        "target_tmp", 0,...                %2段目制御用目標角
        "eta_pre",0,...                    %前ステップeta
        "diff_w",0,...                     %前ステップロール角速度偏差
        "diff_e",0,...　　　　　　　　　　　%前ステップeta偏差
        "inte1",0,...                      %ロール角度偏差積分値
        "inte2",0,...                      %eta積分値
        "st1_t",0,...                      %1段階制御終了時刻
        "st2_t",0);                        %2段階制御終了時刻


    %制御パラメータの保存
    if isempty(obj.para)
       obj.para = para; 
       obj.log = log;
    end
    %動的プロパティの作成　
    if ~isprop(obj, "memo")
       obj.addprop("memo");
       obj.memo = memo;
    end
    %初期クォータニオン生成
    if ~isprop(obj, "q_memo")
        [~, obj] = ome2qua(obj, [0,0,0], 0, q);
    end

    reset = false;
    a = 0;
    pid1 = 0;
    pid2 = 0;
    p1 = 0;
    i1 = 0;
    d1 = 0;
    p2 = 0;
    i2 = 0;
    d2 = 0;
    
    [q, obj] = ome2qua(obj, omega, Corrector2);
    [Van, obj] = acc2vel(obj, Ab, q, Corrector2);
    eta = angle_eta(q);
    theta = angle_theta(q);
    
    
    switch obj.memo.step
        case 0 %離床から燃焼終了まで待機
            delta_a = 0;                
            if Corrector2 && (para.start_t < t || Ab(1) < 0)     %制御開始条件分岐
                obj.memo.step = 1;
                reset = true;
                obj.memo.diff_w = -omega(1);
                if abs(para.target - eta) > pi                   %-piから3*piの範囲で目標角再設定
                   if para.target - eta > 0
                       obj.memo.target_tmp = para.target - 2*pi;
                   else
                       obj.memo.target_tmp = para.target + 2*pi;
                   end
                else
                    obj.memo.target_tmp = para.target;
                end
                obj.memo.diff_e = obj.memo.target_tmp - eta;
            end
            
        case 1 %制御実行
            while abs(obj.memo.eta_pre - eta) > pi                %eta範囲無限化
                if obj.memo.eta_pre - eta > 0
                    eta = eta + 2*pi;
                else
                    eta = eta - 2*pi;
                end
            end
            
            diff_w1 = obj.memo.diff_w;                            %pid各項計算
            diff_w2 = -omega(1);
            diff_e1 = obj.memo.diff_e;
            diff_e2 = obj.memo.target_tmp- eta;
            inte1 = obj.memo.inte1 + (diff_w1 + diff_w2) / 2 * obj.dt; 
            inte2 = obj.memo.inte2 + (diff_e1 + diff_e2) / 2 * obj.dt;
            if Corrector2
                obj.memo.diff_w = diff_w2;
                obj.memo.inte1 = inte1;
                obj.memo.diff_e = diff_e2;
                obj.memo.inte2 = inte2;
            end
            p1 = para.Kp1 * diff_w2;
            i1 = para.Ki1 * inte1;
            d1 = para.Kd1 * (diff_w2 - diff_w1) / obj.dt;
            p2 = para.Kp2 * diff_e2;
            i2 = para.Ki2 * inte2;
            d2 = para.Kd2 * (diff_e2 - diff_e1) / obj.dt;
            
            pid1 = (p1 + i1 + d1) / Van^2;
            pid2 = (p2 + i2 + d2) / Van^2;
            
            if abs(omega(1)) > 2*pi       %制御比重決定
                a = 1;
            else
                a = abs(omega(1)) / (2 * pi);
            end
            
            delta_a = pid1 * a + pid2 * (1 - a);
            
            
            if Corrector2 && theta > pi/2*0.99                  %特異点到達検知
                obj.memo.st1_t = t;
                obj.memo.step = 2;
                reset = true;
            end
            
        case 2 %特異点到達後制御停止
            delta_a = 0;     
    end
            
        %舵角制限
    if abs(delta_a) > obj.da_max /180*pi
       delta_a = obj.da_max /180*pi * sign(delta_a);
    end
    
        %データ保存
    if Corrector2
        obj.log.omega_x = [obj.log.omega_x, omega(1)];
        obj.log.eta = [obj.log.eta, eta];
        obj.log.theta = [obj.log.theta, theta];
        obj.log.Van = [obj.log.Van, Van];
        obj.log.a = [obj.log.a, a]; 
        obj.log.pid1 = [obj.log.pid1, pid1];
        obj.log.pid2 = [obj.log.pid2, pid2];
        obj.log.pid = [obj.log.pid, [p1;i1;d1;p2;i2;d2]];
        obj.memo.eta_pre = eta;
    end
    
    function eta = angle_eta(q)
        %制御角η算出用関数
        q0 = q(1);
        q1 = q(2);
        q2 = q(3);
        q3 = q(4);
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
        %姿勢角θ(鉛直ベクトルと機軸ベクトルの成す角)算出用関数
        V1 = [0;0;1];
        V2 = quaternion.q_rot([1;0;0],q);
        theta = acos(dot(V1,V2)/(norm(V1)*norm(V2)));
    end

    function [q, obj] = ome2qua(obj, omega,  Corrector2, q0)
        %ジャイロセンサデータからqの算出関数
        
        if ~exist('q0', 'var') q0 = []; end
        
        if ~isprop(obj, "q_memo")
            obj.addprop("q_memo");
            obj.q_memo = q0;
        end
        

        P = omega(1);
        Q = omega(2);
        R = omega(3);
        q_dot = 1/2 * [0, -P, -Q, -R;
                       P,  0,  R, -Q;
                       Q, -R,  0,  P;
                       R,  Q, -P,  0] * obj.q_memo;
        q = obj.q_memo + q_dot * obj.dt;       %オイラー積分
        
        if Corrector2
            obj.q_memo = q;
        end
    end

    function [Vbn, obj] = acc2vel(obj, Ab, q, Corrector2)
        %センサデータから対気速度の算出関数
        %6軸センサからの対気速度の算出は不可能
        %ここでは機体の対地速度を返している
        
        if ~isprop(obj, "Vb_memo")
            obj.addprop("Vb_memo");
            obj.Vb_memo = zeros(3,1);
        end
        
        Vb_dot = quaternion.q_rot(Ab, q);
        Vb = obj.Vb_memo + Vb_dot * obj.dt;
        Vbn = norm(Vb);
        
        if Corrector2
            obj.Vb_memo = Vb;
        end
        
    end

end
