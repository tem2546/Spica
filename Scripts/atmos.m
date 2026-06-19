%Spica
%�W����C���f���ɂ���C��Ԃ̌v�Z�֐�
%--------------------------------------------------------------------------%
function [T, a, P, rho] = atmos( h )
% �W����C���f��(The U.S. Standard Atmosphere 1976)��p�����A���x�ɂ�鉷�x�A�����A��C���A��C���x�̊֐�
% ���x�͊�W�I�|�e���V�������x�����ɂ��Ă���B
% �W����C�̊e�w���Ƃ̋C�����������`����p���Čv�Z���Ă���B
% Standard Atmosphere 1976�@ISO 2533:1975
% ���Ԍ����x86km�܂ł̋C���ɑΉ����Ă���B����ȏ�͍��ەW����C�ɓ��Ă͂܂�Ȃ��̂Œ��ӁB
% cf. http://www.pdas.com/hydro.pdf
% @param h ���x[m]
% @return T ���x[K]
% @return a ����[m/s]
% @return P �C��[Pa]
% @return rho ��C���x[kg/m3]
% 1:	�Η���		���x0m
% 2:	�Η����E��	���x11000m
% 3:	���w��  		���x20000m
% 4:	���w���@ 		���x32000m
% 5:	���w���E�ʁ@	���x47000m
% 6:	���Ԍ��@ 		���x51000m
% 7:	���Ԍ��@ 		���x71000m
% 8:	���Ԍ��E�ʁ@	���x84852m

% ----
% TBD:
% NRLMSISE-00 Atmosphere Model �ɕύX
% https://jp.mathworks.com/matlabcentral/fileexchange/56253-nrlmsise-00-atmosphere-model
% ----

% https://github.com/ina111/MatRockSim/blob/master/environment/atmosphere_Rocket.m
% https://jp.mathworks.com/matlabcentral/fileexchange/28135-standard-atmosphere-functions
% ���Q�l�Ɏ���

% �萔
g = 9.80665;
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