rc = Roll_control;

ts = [];

rc.dt = 0.001;  %ステップ時間
rc.t_max = 21;  %シュミレーション時間

for t = 0:rc.dt:rc.t_max
    %目標値の設定
    
    Hz = 0.5 * 2^(t/10);
    da_ref = 15/180*pi*sign(sin(Hz * 2*pi * t));
    if t > 10
        da_ref = 0;
    end
    Hz = 0.5 * 2^((t-11)/10);
    if t > 11
        da_ref = 30/180*pi * sin(Hz * 2*pi * (t-11));
    end


    %モーターシュミレーション関数の実行
    [da_out,rc] = rc.motor_simulate(da_ref,0.05,t,1);
    ts = [ts,t];
end

%グラフの表示
hold on
plot(ts, rc.m_log.da_ref(1,1:size(ts,2)))
plot(ts, rc.m_log.da_out(1,1:size(ts,2)))
xlim([0 21])