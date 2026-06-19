%Spica
% クォータニオン計算用クラス
%
% http://www.mss.co.jp/technology/report/pdf/19-08.pdf
% MATLABによるクォータニオン数値計算
%
% https://github.com/ina111/6DoF2Map/tree/master/coordinate
% 上のコードをMATLABに起こしたもの
%
% https://qiita.com/Soonki/items/7c2ad2a44b85ea79dcc3
% MATLABでクォータニオンを使う
%-------------------------------------------------------------------------%
classdef quaternion %< handle

properties
end

methods(Static)
    function rc = q_times(p, q)     %クォータニオンの乗算
        p_vec = [p(2);p(3);p(4)];
        q_vec = [q(2);q(3);q(4)];
        rc = [p(1)*q(1)-dot(p_vec, q_vec);
        p(1)*q_vec+q(1)*p_vec+cross(p_vec, q_vec)];
    end

    function r = q_inv(q)
        qn = q(1)^2+q(2)^2+q(3)^2+q(4)^2;
        q_vec = [q(2);q(3);q(4)];
        r = [q(1);-q_vec]./qn;
    end

    function v = q_rot(u, q)
    %3次元ベクトルuをクォータニオンqに従って回転したベクトルvを計算
        uq = [0;u];
        q_inv = quaternion.q_inv(q);
        vt = quaternion.q_times(q, uq);
        vq = quaternion.q_times(vt, q_inv);
        v = [vq(2);vq(3);vq(4)];
    end
    
    function R = q_DCM(q)           %クォータニオン→方向余弦行列
        p = q.^2;
        R = [p(1)+p(2)-p(3)-p(4), 2*(q(2)*q(3)+q(1)*q(4)), 2*(q(2)*q(4)-q(1)*q(3));
            2*(q(2)*q(3)-q(1)*q(4)), p(1)-p(2)+p(3)-p(4), 2*(q(3)*q(4)+q(1)*q(2));
            2*(q(2)*q(4)+q(1)*q(3)), 2*(q(3)*q(4)-q(1)*q(2)), p(1)-p(2)-p(3)+p(4)];
    end
    
    function euler = q_euler(q)     %クォータニオン→オイラー角
        q2 = q.^2;
        phi = atan2(2*(q(3)*q(4)+q(1)*q(2)),q2(1)-q2(2)-q(3)+q(4));
        theta = asin(2*(q(1)*q(3)-q(2)*q(4)));
        psi = atan2(2*(q(2)*q(3)+q(1)*q(4)),q2(1)+q2(2)-q(3)-q(4));
        euler = [phi; theta; psi];
    end
    
    function q = euler_q(E)         %オイラー角→クォータニオン
        %E = [phi; theta; psi]
        phi2 = E(1)/2; theta2= E(2)/2; psi2 = E(3)/2;
        q = [cosd(phi2) * cosd(theta2) * cosd(psi2) + sind(phi2) * sind(theta2) * sind(psi2);
            sind(phi2) * cosd(theta2) * cosd(psi2) - cosd(phi2) * sind(theta2) * sind(psi2);
            cosd(phi2) * sind(theta2) * cosd(psi2) + sind(phi2) * cosd(theta2) * sind(psi2);
            cosd(phi2) * cosd(theta2) * sind(psi2) + sind(phi2) * sind(theta2) * cosd(psi2)];
    end
end

end