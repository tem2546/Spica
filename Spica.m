
%Spica ver2.1
%CREATE 自作シミュ
%
%ver2.1

%本体
%-------------------------------------------------------------------------%
function [cc, gs, df] = Spica(varargin)
    close all
    ver = '2.0';
    
    disp(strcat("Spica ver", ver, " booting..."))

    old = cd('Scripts');
    
    opt = string(varargin);
    
    gs = [];
    cc = [];
    df = [];
    
    if isempty(opt)
        [cc, gs, df] = simulation;
    else
        if strcmp(opt,"h")    %ヘルプ
            help_msg = [" ";
                strcat("Spica ver", ver);
                "Rocket Flight Simulator for CREATE";
                " ";
                "How to use：[cc, gs, df] = Spica('option')";
                "-----Output Argument-----";
                "cc：Calcuration and Results (Calculation class)";
                "gs：Settings (GeneralSetting class)";
                "df：Display results (DisplayFigure class)";
                "-----Options-----";
                "empty (Execute 'Spica' WITHOUT '(option)'.)：";
                "       Load and Change Last settings, then Calcurate"
                "'f'：Load Last settings, and Calcurate without Changing settings";
                "'p'：Load and Change Pre-made settings, then Calcurate";
                "'m'：Make Pre-made settings";
                "'n'：Make Pre-made settings without file-path";
                "'h'：Display Spica's Information and Helps"];
            for i = 1:size(help_msg,1)
                disp(help_msg(i,:))
            end
        elseif ismember(opt,["m","n","d"])      %事前設定を作成
            gs = GeneralSetting(opt);
        else
            [cc, gs, df] = simulation(opt);
        end
    end
    
    cd(old)
end

function [cc, gs, df] = simulation(varargin)    %シミュレーション実行関数
    str = string(varargin);
    
    %各種設定クラス読込
    if isempty(str)
        gs = GeneralSetting;
    else
        gs = GeneralSetting(str);
    end
    
    if strcmp(gs.param_fn,"")
        warning("Rocket Parameter File is NOT selected!")
        return
    elseif strcmp(gs.thrust_fn,"")
        warning("Thrust Data File is NOT selected!")
        return
    elseif isempty(gs.elev) 
        warning("Elevation is NOT set correctly!")
        return
    elseif isempty(gs.Vw0)
        warning("Vw0 is NOT set correctly!")
        return
    elseif isempty(gs.Wpsi_set(3))
        warning("Wpsi is NOT set correctly!")
        return
    end

    %並列プールを起動
    if strcmp(gs.parallel,'Yes')
        delete(gcp('nocreate'))
        parpool;
    end
    
    %実行時間計測開始
    tic

    %計算実行クラス読込
    cc = Calculation(gs);

    df = DisplayFigure(gs, cc);
    %df = [];
    
    %実行時間表示
    toc

    %並列プールをシャットダウン
    if strcmp(cc.parallel,'Yes')
        delete(gcp('nocreate'))
    end
    
    msgbox("Calculation Finished !")
end

