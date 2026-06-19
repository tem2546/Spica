%Spica
%標準大気モデルによる大気状態の計算関数
%--------------------------------------------------------------------------%
function [T, a, P, rho] = atmos( h )
% 標準大気モデル(The U.S. Standard Atmosphere 1976)を用いた、高度による温度、音速、大気圧、空気密度の関数
% 高度は基準ジオポテンシャル高度を元にしている。
% 標準大気の各層ごとの気温減率から定義式を用いて計算している。
% Standard Atmosphere 1976　ISO 2533:1975
% 中間圏高度86kmまでの気温に対応している。それ以上は国際標準大気に当てはまらないので注意。
% cf. http://www.pdas.com/hydro.pdf
% @param h 高度[m]
% @return T 温度[K]
% @return a 音速[m/s]
% @return P 気圧[Pa]
% @return rho 空気密度[kg/m3]
% 1:	対流圏		高度0m
% 2:	対流圏界面	高度11000m
% 3:	成層圏  		高度20000m
% 4:	成層圏　 		高度32000m
% 5:	成層圏界面　	高度47000m
% 6:	中間圏　 		高度51000m
% 7:	中間圏　 		高度71000m
% 8:	中間圏界面　	高度84852m

% ----
% TBD:
% NRLMSISE-00 Atmosphere Model に変更
% https://jp.mathworks.com/matlabcentral/fileexchange/56253-nrlmsise-00-atmosphere-model
% ----

% https://github.com/ina111/MatRockSim/blob/master/environment/atmosphere_Rocket.m
% https://jp.mathworks.com/matlabcentral/fileexchange/28135-standard-atmosphere-functions
% を参考に実装

% 定数
g = 9.80655;
gamma = 1.403;
R = 287.05287;	%N-m/kg-K; value from ESDU 77022
% R = 287.0531; %N-m/kg-K; value used by MATLAB aerospace toolbox ATMOSISA & ISO 2533:1975
% height of atmospheric layer
HAL = [0 11000 20000 32000 47000 51000 71000 84852];
% Lapse Rate Kelvin per meter
LR = [-0.0065 0.0 0.001 0.0028 0 -0.0028 -0.002 0.0];
% Tempareture Kelvin
T0 = [288.15 216.65 216.65 228.65 270.65 270.65 214.65 186.95];
% Pressure Pa
P0 = [101325 22632 5474.9 868.02 110.91 66.939 3.9564 0.3734];

k = fillmissing(interp1(HAL, 1:8, h, 'previous', 'extrap'),'constant',1);

T = T0(k) + LR(k) .* (h - HAL(k));
a = sqrt( T * gamma * R);
if LR(k) ~= 0
	P = P0(k) .* (T / T0(k)) .^ (g / -LR(k) / R);
else
	P = P0(k) .* exp(g / R * (HAL(k) - h) / T0(k));
end
rho = P / R ./ T;

end