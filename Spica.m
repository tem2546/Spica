
%Spica rollcontrol ver3.1
%CREATE ����V�~��
%

%�I�v�V���������iSpica�̉ǐ�����̂��߁j
%���[������V�~���@�\����i�����s�\���j

%ver1.0 2019/01/24
%ver2.0_beta 2020/06/03
%rollcontrol ver3.1 2025/10

%�{��
%-------------------------------------------------------------------------%
function [cc, gs, df] = Spica(varargin)
    close all
    ver = '3.1';
    
    disp(strcat("Spica ver", ver, " booting..."))

    %old�ɃJ�����g�f�B���N�g���̃p�X����
    old = pwd;

    %Scripts�t�H���_�m�F
    if ~isfolder('Scripts')
        disp("Unable to browse to ""Scripts"" folder")
    end

    %�J�����g�f�B���N�g����Scripts�t�H���_�ɕύX
    cd('Scripts');

    %����version��Spica�ł́A���s���̈����ɂ��I�v�V�����̐ݒ�͕s��
    if ~isempty(varargin)
        cd(old);
        disp("Option is not available in this version")
        return;
    end
    
    [cc, gs, df] = simulation;
    
    cd(old);
end

function [cc, gs, df] = simulation(varargin)    %�V�~�����[�V�������s�֐�
    
    cc = [];
    df = [];

    %�e��ݒ�N���X�Ǎ�
    gs = GeneralSetting2();

    gs = gs.setting();

    if gs.end_flag == 1
        disp("Exit Processing")
        return;
    end
    
    pfn_chk = string(gs.param.fn);
    if isempty(pfn_chk) || any(strlength(pfn_chk) == 0)
        warning("Rocket Parameter File is NOT selected!")
        return
    elseif strcmp(gs.thrust.fn,"")
        warning("Thrust Data File is NOT selected!")
        return
    elseif isempty(gs.elev) 
        warning("Elevation is NOT set correctly!")
        return
    elseif isempty(gs.Vw0)
        warning("Vw0 is NOT set correctly!")
        return
    elseif isempty(gs.Wpsi)
        warning("Wpsi is NOT set correctly!")
        return
    end

    %����v�[�����N��
    if strcmp(gs.parallel,'Yes')
        delete(gcp('nocreate'))
        parpool;
    end
    
    %���s���Ԍv���J�n
    tic

    %�v�Z���s�N���X�Ǎ�
    cc = Calculation2(gs);

    df = DisplayFigure(gs, cc);

    %���s���ԕ\��
    toc

    %����v�[�����V���b�g�_�E��
    if strcmp(gs.parallel,'Yes')
        delete(gcp('nocreate'))
    end

    % �������ʂ̓����l���W�񂵁A�K�v�ȂƂ��̓t�@�C���o�͂��s��
    feat_tbl = cc.featureTable();
    cc.exportFeatureTable(feat_tbl);
    df.show_summary(feat_tbl);
end

