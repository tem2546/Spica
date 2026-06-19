function [delta_a, reset, obj] = Example(obj, omega, Ab, Pa ,q, Van, t, Corrector2)
    %EXAMPLE ����֐�������

    %{       
    ����֐��쐬�ɂ���
        �߂�l�C�����͈ȉ��̒ʂ�Ɏw��
        [delta_a, reset, obj] = ...
            function_name(obj, omega, Ab, Pa, q, Van, t, Corrector2)
        �쐬�����֐���@Roll_control�t�H���_�ɕۑ����邱�Ƃ�Roll_control��
        ���\�b�h�Ƃ��ċ@�\����B

    �e�����ɂ���
            omega = 3�~1 double [wx;wy;wz]
                    �@�̍��W�n�ɂ�����p���x[rad/s^2]�@ 
                    �@���i�s������x���C�����`���O������z���̉E����W�n

               Ab = 3�~1 double [ax;ay;az] 
                    �@�̍��W�n�ɂ���������x[m/s^2]
                    ���W�n��omega���l

               Pa = 1�~1 double
                    �C��[Pa]

                q = 4�~1 double [q0;q1;q2;q3] 
                    �@�̍��W�n���n����W�n�ϊ��N�H�[�^�j�I��
                    �n����W�n�́C�^��x���C�^�ky���̉E����W�n
                    q0���X�J���[
                    �ł��グ���Z���T�[������̒��ڎZ�o�͕s��

              Van = 1�~1 double
                    �΋C���x[m/s]
                    �ł��グ���Z���T�[������̒��ڎZ�o�͕s��

                t = 1�~1 double
                    �ł��グ����̌o�ߎ�����[s]

       Corrector2 = 1�~1 logical
                    �V�~�����[�V��������p
                    �C���q2���v�Z���C�l�� 1 �ƂȂ�
                    ���̑��� 0

    �߂�l�ɂ���
          delta_a = 1�~1 double
                    �ڕW�Ƃ��铮���̑Ǌp[rad]
                    ���̃��[�����[�����g����������������ƒ�`

            reset = 1�~1 logical
                    �V�~�����[�V��������p
                    delta_a�̒l���s�A���ɂȂ�Ƃ���ture��Ԃ��Ȃ���΂Ȃ�Ȃ��B
                    ���̑��̏ꍇ��false�B
                    ���[�^�[�V�~�����[�V�����֐��őǊp���A���ɂȂ邽�߁C�����炭���false�ŗǂ��B

    �X�e�b�v�Ԃ̒l�̎Q��
        Roll_control�N���X��dybamicprops�p���N���X�ɂ��C���I�Ƀv���p�e�B���쐬�\
        'obj.addprop("A")'��'A'�Ƃ����v���p�e�B�����������B
        ���X�e�b�v�Ŏg�p�������l�́C�v���p�e�B�𓮓I�ɍ쐬���C�����ɕۑ�����Ηǂ�
        ���䃍�O�����v���p�e�B�ɕۑ����邱�ƂŁC�v�Z�I����Q�Ɖ\
        �O���[�o���ϐ��ł��ꉞ�\�����C�ϐ����̏d��������邽�ߔ񐄏�

    ���ӎ���
        ��������t�ɂ����Đ���֐���3��Ăяo����C
        3��ڂ̌v�Z���ʂ𐔒l�v�Z�̉��Ƃ��Ă���B
        ����ɂ��C�ӂ̃v���p�e�BA�ɂ��āC����֐����ɖ�������
        obj.A = function(obj.A);
        �̗l�ȋL�q�͕s�K���B
        �܂��C���̃X�e�b�v�v�Z�p�ɒl���v���p�e�B�ɕۑ�����ۂ͏C���q2���v�Z���C
        �܂�C�ȉ��̂悤��Corrector2 == 1�𖞂������̂݃v���p�e�B�ɕۑ����邱��
        if Corrector2
            obj.val_memo = val;
        end
        �ő�l�ŏ��l���̎Z�o�ɂ��Ă����l�B
    %}

    %{
    ����T�v
        �R�ďI���܂őҋ@�B�I�����i��ڂƂ��ă��[���p���x�����������鐧��B
        �ڕW�l(omega_switch)�ȉ��ɂȂ�ƁC�ڕW�p(target)�ɃJ�����������悤�ɐ���B
        ���ٓ_���B��C����I���B2�i�K�ڂ̐���Ŏg�p���鐧��p�ł́C�J�����̖@���x�N
        �g���̐����ʂւ̎ˉe�x�N�g���Ɛ^���x�N�g���̐����p�B
        ����̓J�����̖@���x�N�g�����@�̍��W�ny���ƈ�v����Ƃ��Czxy�I�C���[�p�̃�+��/2
        �Ɠ��l�Cz���ƈ�v����Ƃ��Czxz�܂���zyz�I�C���[�p�̃�+�΂Ɠ��l�B
        �@���������ɂȂ����������ٓ_�B
        �{�֐��̓J������y�������������Ă�Ɛݒ�B
    %}

    %����p�����[�^
    para = struct(...
        "start_t", 3,...                  %����J�n����
        "target", 0/180*pi,...            %�ڕW�p
        "omega_sw", 5/180*pi,...          %����n�ύX�p���x
        "Kp1", 100,...                    %��1�i�K����PID�Q�C��
        "Ki1", 50,...
        "Kd1", 0,...
        "Kp2", 500,...                    %��2�i�K����PID�Q�C��
        "Ki2", 400,...
        "Kd2", 100); 
    
    %�ۑ����O
    log = struct(...
        "omega_x",[],...                   %���[���p�x [rad/s] 
        "eta",[],...                       %����p�� [rad]
        "theta",[],...�@�@�@�@�@�@�@�@�@�@�@%�p���p�� [rad]
        "Van",[],...                       %�΋C���x [m/s]
        "pid",[]);                 %����p�����[�^

    %�v���p�e�B�ۑ��p�����[�^
    memo = struct(...
        "step",0,...                       %����i�K
        "target_tmp", 0,...                %2�i�ڐ���p�ڕW�p
        "eta_pre",0,...                    %�O�X�e�b�veta
        "diff_w",0,...                     %�O�X�e�b�v���[���p���x�΍�
        "diff_e",0,...�@�@�@�@�@�@�@�@�@�@�@%�O�X�e�b�veta�΍�
        "inte1",0,...                      %���[���p�x�΍��ϕ��l
        "inte2",0,...                      %eta�ϕ��l
        "st1_t",0,...                      %1�i�K����I������
        "st2_t",0);                        %2�i�K����I������


    %����p�����[�^�̕ۑ�
    if isempty(obj.para)
       obj.para = para; 
       obj.log = log;
    end
    %���I�v���p�e�B�̍쐬�@
    if ~isprop(obj, "memo")
       obj.addprop("memo");
       obj.memo = memo;
    end


    reset = false;
    eta = angle_eta(q);
    theta = angle_theta(q);
    p = 0;
    i = 0;
    d = 0;

    switch obj.memo.step
        case 0 %��������R�ďI���܂őҋ@
            delta_a = 0;                
            if Corrector2 && (para.start_t < t)               %�ݒ莞�Ԍo�ߌ㐧��J�n
                obj.memo.step = 1;
                reset = true;
                obj.memo.diff_w = -omega(1);
            end

        case 1 %�p���x�����p����
            diff_w1 = obj.memo.diff_w;
            diff_w2 = -omega(1);
            inte1 = obj.memo.inte1 + (diff_w1 + diff_w2) / 2 * obj.dt; 
            if Corrector2
                obj.memo.diff_w = diff_w2;
                obj.memo.inte1 = inte1;
            end

            p = para.Kp1 * diff_w2;
            i = para.Ki1 * inte1;
            d = para.Kd1 * (diff_w2 - diff_w1) / obj.dt;
            Van_safe = max(Van, 1.0);
            delta_a = (p + i + d) / Van_safe^2;                       %��C���x�ɂ�郂�[�����g�̑������l��

            if Corrector2 && (abs(omega(1)) < para.omega_sw)     %�؂�ւ��p���x���m
                obj.memo.st1_t = t;
                if abs(para.target - eta) > pi                   %-pi����3*pi�͈̔͂ŖڕW�p�Đݒ�
                   if para.target - eta > 0
                       obj.memo.target_tmp = para.target - 2*pi;
                   else
                       obj.memo.target_tmp = para.target + 2*pi;
                   end
                end
                obj.memo.diff_e = obj.memo.target_tmp - eta;
                obj.memo.step = 2;
            end

        case 2 %�ڕW�p���ڗp����
            while abs(obj.memo.eta_pre - eta) > pi                %eta�͈͖�����
                if obj.memo.eta_pre - eta > 0
                    eta = eta + 2*pi;
                else
                    eta = eta - 2*pi;
                end
            end
            
            diff_e1 = obj.memo.diff_e;                           %pid�e���v�Z
            diff_e2 = obj.memo.target_tmp- eta;
            inte2 = obj.memo.inte2 + (diff_e1 + diff_e2) / 2 * obj.dt;
            if Corrector2
                obj.memo.diff_e = diff_e2;
                obj.memo.inte2 = inte2;
            end
            p = para.Kp2 * diff_e2;
            i = para.Ki2 * inte2;
            d = para.Kd2 * (diff_e2 - diff_e1) / obj.dt;
            Van_safe = max(Van, 1.0);
            delta_a = (p + i + d) / Van_safe^2;

            if Corrector2 && theta > pi/2*0.99                  %���ٓ_���B���m
                obj.memo.st2_t = t;
                obj.memo.step = 3;
                reset = true;
            end

        case 3 %���ٓ_���B�㐧���~
            delta_a = 0;
    end

    %�Ǌp����
    if abs(delta_a) > obj.da_max /180*pi
       delta_a = obj.da_max /180*pi * sign(delta_a);
    end

    %�f�[�^�ۑ�
    if Corrector2
        obj.log.omega_x = [obj.log.omega_x, omega(1)];
        obj.log.eta = [obj.log.eta, eta];
        obj.log.theta = [obj.log.theta, theta];
        obj.log.Van = [obj.log.Van, Van];
        obj.log.pid = [obj.log.pid, [p;i;d]];
        obj.memo.eta_pre = eta;
    end


    function eta = angle_eta(q)
        %����p�ŎZ�o�p�֐�
        q0 = q(1);
        q1 = q(2);
        q2 = q(3);
        q3 = q(4);
        V1 = [1;0;0];
        V2 = [2*(q1*q2-q0*q3); q0^2-q1^2+q2^2-q3^2; 0];
        cosval = dot(V1,V2) / (norm(V1)*norm(V2));
        eta = acos(max(-1, min(1, cosval)));
        if isequal(V2, [-1;0;0])
            eta = pi;
        end
        if V2(2) < 0
            eta = 2 * pi - eta;
        end
    end

    function theta = angle_theta(q)
        %�p���p��(�����x�N�g���Ƌ@���x�N�g���̐����p)�Z�o�p�֐�
        V1 = [0;0;1];
        V2 = quaternion.q_rot([1;0;0],q);
        cosval = dot(V1,V2)/(norm(V1)*norm(V2));
        theta = acos(max(-1, min(1, cosval)));
    end


    function [q, obj] = ome2qua(obj, omega,  Corrector2, q0)
        %�W���C���Z���T�f�[�^����q�̎Z�o�֐�(���g�p)
        
        if ~exist('q', 'var') q0 = []; end
        
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
        q = obj.q_memo + q_dot * obj.dt;       %�I�C���[�ϕ�
        
        if Corrector2
            obj.q_memo = q;
        end
    end

    function [Van, obj] = acc2vel(obj, Ab)
        %�Z���T�f�[�^����΋C���x�̎Z�o�֐�(���g�p)
        
        %������
    end
end