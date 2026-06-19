%Spica
%各種設定用クラス
%-------------------------------------------------------------------------%
classdef GeneralSetting
    properties
        %-----directory-----
        dir_home = "";              %ホームディレクトリ(Spicaフォルダ)
        dir_res = "";               %Resultフォルダ
        dir_scr = "";               %Scriptフォルダ
        dir_form = "";              %Formatsフォルダ
        dir_param = "";             %ParameterFilesフォルダ
        dir_thrust = "";            %ThrustDataフォルダ
        dir_ls = "";                %LaunchSiteフォルダ
        
        %-----general setting-----
        param_fn = "";              %諸元表ファイル名
        param_path = "";            %諸元表インデックス
        param_n = 1;                %全段数
        thrust_fn = "";             %推力履歴ファイル名
        thrust_path = "";           %推力履歴インデックス
        Xcp_fn = "";
        mode_export = 'Default';    %結果ファイルの出力先設定
        
        %-----variable-----
        output = "";                %出力データ設定
        log_list = ["xe";"Ve";"Ab";"q";"omega";"Va";"extra"];	%ログ記録変数名リスト
        log = ["xs(1:3,:)";"xs(4:6,:)";"ys(1:3,:)";
            "xs(7:10,:)";"xs(11:13,:)";"ys(4:7,:)";"ys(23:24,:)"];    %ログ記録変数リスト
        log_str = ["-----Logging Variables-----";
            "位置座標@地上固定系(xe)";
            "絶対速度@地上固定系(Ve)";
            "加速度@機体座標系(Ab)";
            "姿勢(クォータニオン)(q)";
            "角速度@機体座標系(omega)"];                 %ログ記録変数名リスト(表示用)
        feat_list = ["Vlc";"Va_max";"Mach_max";"Altitude";"Va_top";"t_top";"Va_para";
            "alpha_max";"beta_max";"AngleAccel_max";"dp_max";"dp_max_t";"dp_max_z";"t_landing";"FP"];     %特徴値名リスト
        feat = ["Vn_lc";"Van_max";"Mach_max";"z_max";"Van_top";"t_top";"Va_para";
            "alpha_max";"beta_max";"AngleAccel_max";"dp_max";"dp_max_t";"dp_max_z"];               %特徴値リスト
        feat_str = ["-----Feature Variables-----";
            "ランチクリア速度(Vlc)";
            "最大対気速度(Va_max)";
            "最大マッハ数(Mach_max)";
            "到達高度(Altitude)";
            "頂点対気速度(Va_top)";
            "頂点到達時刻(t_top)";
            "開傘時対気速度(Va_para)";
            "飛翔時間(t_Hard,t_Descent)";
            "落下分散表(FP_Hard,FP_Descent)"];                   %特徴値名リスト(表示用)
        
        %-----calculating condition-----
        base_azm = 'ME';            %基準方位 M:Magnetic T:True, E:East N:North ...
        mode_angle = 'CCW';         %方位角の正方向 CW:ClockWise, CCW:CounterClockWise
        view_azm = 'Magnetic';      %落下分散図の基準方位種類
        mode_calc = 'Single';       %計算モード  Single, Multiple
        mode_landing = 'Hard';      %降下モード  Hard, Descent, Both
        descent_model = 'Vw_model'; %減速降下モデル    Vw_model, Dynamics
        wind_model = 'PowerLaw';    %風速モデル
        MSM_fn = '';                %MSMデータファイル名(.nc形式)
        wind_fn = '';               %風速実データファイル名(.csv形式)
        t_max = 100;                %計算打切り時間
        freq = 200;                 %計算レート
        elev_set = zeros(1,3);      %射角設定
        Vw0_set = zeros(1,3);       %基準風速設定
        Wpsi_set = zeros(1,3);      %風向設定
        mgd = 0;                    %射点磁気偏角(西偏=正)
        
        %-----calculating-----
        elev = [];                  %射角リスト
        Vw0 = [];                   %風速リスト
        Wpsi = [];                  %風向リスト
        Wpsi_res = [];              %風向リスト(結果用)
        elev_n = 0;                 %射角条件数
        Vw0_n = 0;                  %風速条件数
        Wpsi_n = 0;                 %風向条件数
        
        %-----option-----
        auto_judge = 'No';              %風向風速制限の自動判定機能
        limit_area = struct(...
            'fn',"",...
            'path',"",...
            'coord',"geo",...
            'type', "TN",...
            'rot', "CW",...
            'origin',[40.138633, 139.4209],...
            'circle', struct(...
                'geo', [],...
                'dist', []),...
            'polygon', struct(...
                'geo', [],...
                'dist', []));           %落下制限区域
        ll = [];                        %経緯度変換用クラス(lon_latクラス)
        Ab_log = 'No';                  %ランチクリア前後の加速度ログの出力機能
        t_Ab_log = 0;                   %加速度ログの記録時間
        parallel= 'No';                 %CPU並列計算機能
        tipoff_model = 'Do not';        %チップオフモード
        lug_error = 0;                  %ランチラグ位相誤差によるランチャに対する機体の初期姿勢角
        
        %-----display-----
        list_fig = "";                      %出力する図のリスト
        fig_size = struct(...
            'path',[100, 50, 800, 700],...
            'point',[100, 50, 800, 700]);   %図のサイズ
        ax = struct(...
            'path',struct(...
                'label', ["Magnetic East [m]";
                        "Magnetic North [m]";
                        "Altitude [m]"],...
                'FontSize', 10,...
                'Color', [0, 0, 0],...
                'FontWeight', 'normal'),...
            'point',struct(...
                'range', [-840, 880, -910, 750],...
                'label', ["Magnetic East[m]";"Magnetic North[m]"],...
                'FontSize', 10,...
                'Color', [0, 0, 0],...
                'FontWeight', 'normal'));   %軸関連
        lgd = struct(...
            'path', struct(...
                'pos', [0.8, 0.8, 0.1 ,0.1],...
                'FontSize', 10,...
                'TextColor', [0, 0, 0],...
                'FontWeight', 'bold'),...
            'point', struct(...
                'pos', [0.8, 0.8, 0.1 ,0.1],...
                'FontSize', 10,...
                'TextColor', [1, 0.9999, 0.9999],...
                'FontWeight', 'bold'));     %凡例関連
        kml = struct(...
            'path', struct(...
                'Width',15,...
                'Color', [1 1 1]),...
            'point', struct(...
                'Width',15,...
                'Color', [1 1 1]));         %GoogleEarth用kmlファイル関連
        
        %flightpath
        event = struct(...
            'LaunchClear',struct(...
                'disp',"Yes",...
                'ref',"t_lc",...
                'stage',1,...
                'mode_land',"Both"),...
             'Top',struct(...
                'disp',"Yes",...
                'ref',"t_top",...
                'stage',1,...
                'mode_land',"Both"),...
             'ParaOpen',struct(...
                'disp',"Yes",...
                'ref',"t_para",...
                'stage',1,...
                'mode_land',"Descent"));    %飛行イベント
        line = struct(...
            'Color', [0 0.4470 0.7410;
                    0.8500 0.3250 0.0980],...
            'Width',0.5)                    %ライン関連
        
        %fallpoint
        back_pict = struct(...
            'fn', 'Oshima_201903.jpg',...
            'img', [],...
            'pos', [-830, 870; -907, 750]); %背景図関連
        marker = struct(...
            'mode', 'shape',...
            'color', [1, 1, 1; 1, 0, 0],...
            'size', 50,...
            'shape', "o",...
            'mfc', 'flat');                 %マーカー関連
        
        %-----MATLAB Addons-----
        add_list = "";              %インストール済みのアドオンリスト
        
    end
    
    methods
        function obj = GeneralSetting(varargin)     %コンストラクタメソッド　以前の設定の読込・表示
            opt = string(varargin);
            if isempty(opt)
                opt = "a";
            end
            
            if isfolder('PreSettings')==0
                mkdir PreSettings
            end
            
            if strcmp(opt,"d")
                disp('All settings are Initialized...')
            else
                %設定ファイル名取得
                if ismember(opt, ["a","f"])
                    tmp_dir = cd;
                    disp('"LastSetting.mat" is read for pre-setting file,')
                    sf = 'LastSetting.mat';
                    dir_sf = strcat(tmp_dir, '/PreSettings/', sf);
                elseif ismember(opt,["p","m","n"])
                    if strcmp(opt,"p")
                        tl = 'pre-setting';
                    else
                        tl = 'Base';
                    end
                    dir_scr = cd('PreSettings');
                    [sf, path] = uigetfile('.mat',...
                        strcat('Select ', tl, ' file'),'LastSetting.mat');
                    dir_sf = strcat(path, sf);
                    cd(dir_scr)
                end

                %設定ファイルの読込
                if isfile(dir_sf)
                    preset = load(dir_sf);
                    pre_list = properties(preset.obj);
                    cur_list = properties(obj);
                    list = ismember(cur_list,pre_list);
                    list_true = cur_list(list==1);
                    for i = 1:size(list_true,1)
                        obj.(list_true{i,:}) = preset.obj.(list_true{i,:});
                    end
                    if strcmp(obj.dir_home,"")
                        obj = obj.path_init;
                    end
                else
                    warning(strcat('The file "', sf, '" is NOT found!'))
                    obj = obj.path_init;
                end

                %インストール済みのアドオンを取得
                add = matlab.addons.installedAddons;
                obj.add_list = add.Name;
                if ismember("Parallel Computing Toolbox",obj.add_list)==0
                    warning('CANNOT use Parallel Computing! \n (MATLAB Addon "Parallel Computing Toolbox" is NOT installed.)','')
                    obj.parallel = 'No';
                end

                %設定変更
                if strcmp(opt, "f")==0
                    obj = obj.setting;
                end

                if strcmp(obj.wind_model,'PowerLaw')==0
                    obj.mode_calc = 'Single';
                    warning(strcat("'mode_calc' is changed to 'Single'! \n ('",obj.wind_model,"' is selected as 'wind_model'.)"),"")
                end

                %ファイルパス削除
                if strcmp(opt, "n")
                    obj.dir_home = "";
                    obj.dir_res = "";
                    obj.dir_scr = "";
                    obj.dir_form = "";
                    obj.dir_param = "";
                    obj.dir_thrust = "";
                    obj.dir_ls = "";
                    obj.param_fn = "";
                    obj.param_path = "";
                    obj.thrust_fn = "";
                    obj.thrust_path = "";
                    obj.limit_area.fn = "";
                    obj.limit_area.path="";
                end
            end
            
            %変数保存
            if ismember(opt, ["m","n"])
                cd('PreSettings')
                [fn, path] = uiputfile('.mat','Select Save File','LastSetting.mat');
                fn = strcat(path, fn);
                save(fn, 'obj')
            else
                if strcmp(obj.dir_scr,"")
                    fn = 'PreSettings/LastSetting.mat';
                else
                    fn = strcat(obj.dir_scr,'/PreSettings/LastSetting.mat');
                end
                save(fn,'obj')
            end
        end
        
        function obj = path_init(obj)       %ファイルパス初期化関数
            disp('File paths are Initialized...')
            %各フォルダの場所を指定
            obj.dir_scr =  cd('../');
            home = cd;
            obj.dir_home = home;
            obj.dir_res = strcat(home,"/Result");
            obj.dir_form = strcat(home,"/Formats");
            obj.dir_param = strcat(home,"/ParameterFiles");
            obj.dir_thrust = strcat(home,"/ThrustData");
            obj.dir_ls = strcat(home,"/LaunchSite");
            cd(obj.dir_scr)
            
        end
        
        function disp_set(obj,kind)     %コマンドライン表示用関数
            switch kind
                case 'set_model'      %一般設定表示
                    if strcmp(obj.param_fn,'')==0
                        for i = 1:size(obj.param_fn,1)  %諸元表及び推力履歴ファイル名
                            param_str(2*i-1,:) = strcat("ParameterFile",num2str(i),"：",obj.param_fn(i,:));
                            param_str(2*i,:) = strcat("ThrustData",num2str(i),"：",obj.thrust_fn(i,:));
                        end
                    else
                        param_str = "ParameterFile：Not Selected";
                    end
                    str = ["-----Model Settings-----";
                           param_str;
                           strcat("Descent landing model：",obj.descent_model);
                           strcat("Tip-off model：",obj.tipoff_model)
                           strcat("Launch-lug error：",num2str(obj.lug_error)," [deg]")];
               case 'set_cond'      %計算条件設定
                    str = ["-----Calculating Condition-----";
                           strcat("Mode calclation：",obj.mode_calc);
                           strcat("Mode landing：",obj.mode_landing);
                           strcat("Wind model：",num2str(obj.wind_model))
                           strcat("Base azimuth：",obj.base_azm);
                           strcat("Azimuth direction：",obj.mode_angle);
                           strcat("Max time of calc：",num2str(obj.t_max)," [s]");
                           strcat("Calclation rate：",num2str(obj.freq)," [Hz]")];
                    if strcmp(obj.wind_model, 'PowerLaw')
                        if strcmp(obj.mode_calc,'Single')
                            cond_str = [strcat("Elevation：",num2str(obj.elev)," [deg]");
                                        strcat("Vw0：",num2str(obj.Vw0)," [m/s]");
                                        strcat("Wpsi：",num2str(obj.Wpsi)," [deg]")];
                        else
                            cond_str = [strcat("Elevation：min=",num2str(obj.elev_set(1)),...
                                ",max=",num2str(obj.elev_set(2)),...
                                ",step=",num2str(obj.elev_set(3))," [deg]");
                                strcat("Vw0：min=",num2str(obj.Vw0_set(1)),...
                                ",max=",num2str(obj.Vw0_set(2)),...
                                ",step=",num2str(obj.Vw0_set(3))," [m/s]");
                                strcat("Wpsi：min=",num2str(obj.Wpsi_set(1)),...
                                ",max=",num2str(obj.Wpsi_set(2)),...
                                ",step=",num2str(obj.Wpsi_set(3))," [deg]")];
                        end
                        str = [str;cond_str];
                    else
                        str = [str;
                            strcat("Elevation：",num2str(obj.elev)," [deg]")];
                        switch obj.wind_model
                            case 'MSM'
                                str = [str;
                                    strcat("MSM file name：",obj.MSM_fn)];
                            case 'csv_data'
                                str = [str;
                                    strcat("Wind data name：",obj.wind_fn)];
                        end
                    end
                case 'set_output'
                    if size(obj.output,1)==2
                        output_str = strcat(obj.output(1,:),", ",obj.output(2,:));
                    else
                        output_str = obj.output;
                    end
                    str = ["-----Output Setting-----";
                           strcat("Mode export：",obj.mode_export);
                           strcat("Output files：",output_str);
                           strcat("Accel-log：",obj.Ab_log)];
                    if strcmp(obj.Ab_log,'Yes')
                        str = [str;
                            strcat('Accel-log time：',num2str(obj.t_Ab_log))];
                    end
                case 'set_log'      %ログ記録変数設定
                    str = obj.log_str;
                case 'set_feat'     %記録特徴値設定
                    str = obj.feat_str;
                case 'set_opt'
                    if strcmp(obj.limit_area.fn,"")
                        str_limit = "Not Selected";
                    else
                        str_limit = obj.limit_area.fn;
                    end
                    str = ["-----Option Function-----";
                           strcat("Auto judge function：",obj.auto_judge);
                           strcat("Limited area data file：",str_limit);
                           strcat("Parallel computing：",obj.parallel)];
                case 'set_disp'
                    str = ["-----Display FIgure-----";
                           strcat("Output figure：",obj.list_fig(1,:))];
                       if size(obj.list_fig,1) > 1
                        str = [str;
                           strcat("               ",obj.list_fig(2:size(obj.list_fig,1),:))];
                       end
                case 'set_path'
                    eve_name = string(fieldnames(obj.event));
                    str = strcat("Flight event：",eve_name(1,:));
                    if size(eve_name,1) > 1
                        str = [str;
                            strcat("             ",eve_name(2:size(eve_name,1),:))];
                    end
                case 'set_point'
                    if strcmp(obj.back_pict.fn,"")
                        str_back = "Not Selected";
                    else
                        str_back = obj.back_pict.fn;
                    end
                    str = ["-----Fall Point-----";
                           strcat("Background picture：",str_back);
                           strcat("Azimuth of figure's x-axis：",obj.view_azm,"East")];
            end
            for i = 1:size(str,1)
                disp(str(i))
            end
        end
        
        function obj = setting(obj)   %設定変更


            list = ["Model Setting","Calculating Condition","Output Setting",...
                "Option Setting","Figure Setting","All Complete"];
            set_cmp = 0;
            while ~set_cmp
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    if sum(change==1) > 0
                        obj = obj.set_model;
                    end
                    if sum(change==2) > 0
                        obj = obj.set_cond;
                    end
                    if sum(change==3) > 0
                        obj = obj.set_output;
                    end
                    if sum(change==4) > 0
                        obj = obj.set_option;
                    end
                    if sum(change==5) > 0
                        obj = obj.set_disp;
                    end
                    if sum(change==6) > 0
                        set_cmp = 1;
                    end
                else
                    set_cmp = 1;
                end
            end
        end
        
        function obj = set_model(obj)     %モデル設定
            obj.disp_set('set_model')
            list = ["Parameter file","Thrust data","CP data","Descent model",...
                "Tip-off","Lug error","Complete"];
            set = 0;
            while ~set
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    if sum(change==1) > 0
                        cd(obj.dir_param);
                        [fn,path] = uigetfile('*.xlsx','1st Stage Parameter File');
                        obj.param_fn = string(fn);
                        obj.param_path = string(path);
                        param_tab = readcell(strcat(obj.param_path,obj.param_fn),...
                            'Sheet','Spica');
                        gs_list = properties(obj);
                        for k = 1:size(param_tab, 1)
                            if ismember(param_tab{k, 1}, gs_list) && ...
                                    (ischar(param_tab{k, 1})) && (param_tab{k, 1} ~= "")
                                obj.(param_tab{k, 1}) = param_tab{k, 2};
                            end
                        end
                        
                       
                        
                        for i = 2:obj.param_n
                            str = num2str(i);
                            switch str(1,size(str,2))
                                case '1'
                                    stage_str = strcat(str,'st');
                                case '2'
                                    stage_str = strcat(str,'nd');
                                case '3'
                                    stage_str = strcat(str,'rd');
                                otherwise
                                    stage_str = strcat(num2str(i),'th');
                            end
                            [fn,path] = uigetfile('*.xlsx',...
                                strcat(stage_str,' Stage Parameter File'));
                            obj.param_fn(i,:)= string(fn);
                            obj.param_path(i,:) = string(path);
                        end
                        cd(obj.dir_scr)
                    end
                    if sum(change==2) > 0
                        cd(obj.dir_thrust);
                        for i = 1:obj.param_n
                            str = num2str(i);
                            switch str(1,size(str,2))
                                case '1'
                                    stage_str = strcat(str,'st');
                                case '2'
                                    stage_str = strcat(str,'nd');
                                case '3'
                                    stage_str = strcat(str,'rd');
                                otherwise
                                    stage_str = strcat(num2str(i),'th');
                            end
                            [fn,path] = uigetfile('*.xlsx; *.csv; *.txt',...
                                strcat(stage_str,' Stage ThrustData File'));
                            obj.thrust_fn(i,:) = string(fn);
                            obj.thrust_path(i,:) = string(path);
                        end
                        cd(obj.dir_scr)
                    end
                    if sum(change==3) > 0
                        cd(obj.dir_param);
                        [obj.Xcp_fn,~] = uigetfile('*.xlsx; *.csv; *.txt','Xcp_data');
                        obj.Xcp_fn = char(obj.Xcp_fn);
                        cd(obj.dir_scr);
                    end
                    if sum(change==4) > 0      %減速降下モデル設定
                        input = questdlg('Descent model?','descent_model',...
                            'Vw_model','Dynamics',obj.descent_model);
                        obj.descent_model = char(input);
                    end
                    if sum(change==5) > 0
                        input = questdlg('Apply tip-off model?','tipoff_model',...
                            'Apply','Do not',obj.tipoff_model);
                        obj.tipoff_model = char(input);
                    end
                    if sum(change==6) > 0
                        input = inputdlg('Launch-lug error?[deg]',...
                            'lug_error',[1,40],cellstr(num2str(obj.lug_error)));
                        obj.lug_error = str2double(input);
                    end
                    if sum(change==7) > 0
                        set = 1;
                    end
                else
                    set = 1;
                end
            end
            obj.disp_set('set_model')
        end
        
        function obj = set_cond(obj)   %計算条件設定用関数
            obj.disp_set('set_cond')
            list = ["Mode calc","Mode landing","Wind model",...
                "Base azm","Mode angle","t_max","delta_t","Calc condition","Comlete"];
            set = 'Yes';
            set_cond = 'Yes';
            while strcmp(set,'Yes')    %計算条件入力
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    if sum(change==1) > 0      %計算モード設定
                        input = questdlg('Mode calculation?','mode_calc',...
                            'Single','Multiple',obj.mode_calc);
                        obj.mode_calc = char(input);
                        change = [change,10];
                    end
                    if sum(change==2) > 0      %降下モード設定
                        input = questdlg('Mode landing?','mode_landing',...
                            'Hard','Descent','Both',obj.mode_landing);
                        obj.mode_landing = string(input);
                    end
                    if sum(change==3) > 0
                        input = questdlg('Wind model?','wind_model',...
                            'PowerLaw','MSM','csv_data',obj.wind_model);
                        obj.wind_model = char(input);
                        if strcmp(obj.wind_model, 'MSM')
                            input = uigetfile('*.nc','MSM_data');
                            obj.MSM_fn = char(input);
                        elseif strcmp(obj.wind_model, 'csv_data')
                            input = uigetfile('*.csv','wind_data');
                            obj.wind_fn = char(input);
                        end
                    end
                    if sum(change==4) > 0      %基準方位設定
                        input = inputdlg('Base azimuth?(M,T + N,E,S,W)',...
                            'base_azm',[1,40],{obj.base_azm});
                        obj.base_azm = char(input);
                    end
                    if sum(change==5) > 0      %方位順方向設定
                        input = questdlg('Azimuth direction?','mode_angle',...
                            'CW','CCW',obj.mode_angle);
                        obj.mode_angle = char(input);
                    end
                    if sum(change==6) > 0
                        input = inputdlg('Max time of calc?[s]','t_max',...
                            [1,40],{num2str(obj.t_max)});
                        obj.t_max = str2double(cell2mat(input));
                    end
                    if sum(change==7) > 0
                        input = inputdlg('Calculation rate?[Hz]',...
                            'freq',[1,40],{num2str(obj.freq)});
                        obj.freq = str2double(cell2mat(input));
                    end
                    if sum(change==8) > 0      %射角・基準風速・風向設定
                        if strcmp(obj.mode_calc,'Single')
                            cond_str = ["elev","Vw0","Wpsi"];
                            dlgtitle = 'Set Calculating Condition';
                            dims = [1 40];
                            definput = {num2str(obj.elev_set(1)),...
                                num2str(obj.Vw0_set(1)),...
                                num2str(obj.Wpsi_set(1))};
                            input = inputdlg(cond_str,dlgtitle,dims,definput);
                            input = str2double(string(input));
                            obj.elev_set = [input(1),input(1),1];
                            obj.Vw0_set = [input(2),input(2),1];
                            obj.Wpsi_set = [input(3),input(3),1];
                        else
                            list_cond = ["elev","Vw0","Wpsi","Comlete"];
                            while strcmp(set_cond,'Yes')
                                [ch,tf] = listdlg('ListString',list_cond,...
                                    'PromptString','Select Setting to Change:');
                                if tf == 1
                                    dims = [1 40];
                                    cond_str = ["min","max","step"];
                                    if sum(ch==1) > 0
                                        dlgtitle = 'Set Elevation';
                                        definput = {num2str(obj.elev_set(1)),...
                                            num2str(obj.elev_set(2)),num2str(obj.elev_set(3))};
                                        input = inputdlg(cond_str,dlgtitle,dims,definput);
                                        input = str2double(string(input));
                                        obj.elev_set = input';
                                    end
                                    if sum(ch==2) > 0
                                        dlgtitle = 'Set Vw0';
                                        definput = {num2str(obj.Vw0_set(1)),...
                                            num2str(obj.Vw0_set(2)),num2str(obj.Vw0_set(3))};
                                        input = inputdlg(cond_str,dlgtitle,dims,definput);
                                        input = str2double(string(input));
                                        obj.Vw0_set = input';
                                    end
                                    if sum(ch==3) > 0
                                        dlgtitle = 'Set Wpsi';
                                        definput = {num2str(obj.Wpsi_set(1)),...
                                            num2str(obj.Wpsi_set(2)),num2str(obj.Wpsi_set(3))};
                                        input = inputdlg(cond_str,dlgtitle,dims,definput);
                                        input = str2double(string(input));
                                        obj.Wpsi_set = input';
                                    end
                                    if sum(ch==4) > 0
                                        set_cond = 'No';
                                    end
                                end
                            end
                        end
                    end
                    if sum(change==9) > 0
                        set = 'No';
                    end
                end
            end
            if obj.elev_set(3)==0
                warning("Elavetion step = 0!")
            elseif obj.Vw0_set(3)==0
                warning("Vw0 step = 0!")
            elseif obj.Wpsi_set(3)==0
                warning("Wpsi step = 0!")
            else
                obj = obj.cond_resetting;
            end
            obj.disp_set('set_cond')
        end
        
        function obj = cond_resetting(obj)      %計算条件の再設定用関数
            %計算条件リストの作成
            if strcmp(obj.mode_calc,'Single')==0
                if strcmp(obj.wind_model,'PowerLaw')
                    obj.elev = obj.elev_set(1):obj.elev_set(3):obj.elev_set(2);         %射角リスト
                    obj.Vw0 = obj.Vw0_set(1):obj.Vw0_set(3):obj.Vw0_set(2);             %基準風速リスト

                    if obj.Wpsi_set(1) == 0 && obj.Wpsi_set(2) == 360                   %風向リスト
                        obj.Wpsi_res = obj.Wpsi_set(1):obj.Wpsi_set(3):obj.Wpsi_set(2)-obj.Wpsi_set(3);
                    else
                        obj.Wpsi_res = obj.Wpsi_set(1):obj.Wpsi_set(3):obj.Wpsi_set(2);
                    end
                end
            else
                obj.elev = obj.elev_set(1);
                if strcmp(obj.wind_model,'PowerLaw')
                    obj.Vw0 = obj.Vw0_set(1);
                    obj.Wpsi_res = obj.Wpsi_set(1);
                end
            end
            
            %風向再設定(入力値をME,CCWへ変換)
            base = obj.base_azm(1);
            azm = obj.base_azm(2);
            if strcmp(obj.mode_angle, 'CW')
                obj.Wpsi = 360 - obj.Wpsi_res;
            else
                obj.Wpsi = obj.Wpsi_res;
            end
            if strcmp(base, 'T')
                obj.Wpsi = obj.Wpsi - obj.mgd;
            end
            
            switch azm
                case 'N'
                    angle_cor = 90;
                case 'E'
                    angle_cor = 0;
                case 'W'
                    angle_cor = 180;
                case 'S'
                    angle_cor = -90;
            end
            obj.Wpsi = obj.Wpsi + angle_cor;
            
            %範囲調整
            over = obj.Wpsi>=360;                   %360deg以上の要素を判定
            less = obj.Wpsi<0;                      %0deg未満の要素を判定
            obj.Wpsi(over) = obj.Wpsi(over) - 360;
            obj.Wpsi(less) = obj.Wpsi(less) + 360;
            
            %各条件数
            obj.elev_n = size(obj.elev,2);
            obj.Vw0_n = size(obj.Vw0,2);
            obj.Wpsi_n = size(obj.Wpsi,2);
        end
        
        function obj = set_output(obj)      %結果出力設定
            obj.disp_set('set_output')
            obj.disp_set('set_log')
            obj.disp_set('set_feat')
            list = ["Mode export","Output data","Ab_log",...
                "Loging variables","Feature variables","Complete"];
            set = 'Yes';
            while strcmp(set, 'Yes')
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    if sum(change==1) > 0
                        input = questdlg('Mode export?','mode_export',...
                            'Default','Manual',obj.mode_export);
                        obj.mode_export = char(input);
                        if strcmp(obj.mode_export,'Manual')
                            obj.dir_res = uigetdir(obj.dir_home,'Select Directory for Export');
                            obj.dir_res = string(obj.dir_res);
                        end
                    end
                    if sum(change==2) > 0
                        list_output = ["vs-time_Logs","FeatureValues","None"];
                        [set_out,tf_out] = listdlg('ListString',list_output,...
                            'PromptString','Select Output Data');
                        if tf_out == 1
                            tmp = list_output(set_out);
                            if ismember("None",tmp)
                                obj.output = "None";
                            else
                                obj.output = tmp';
                            end
                        end
                    end
                    if sum(change==3) > 0
                        input = questdlg('Log Accel@body-frame after LaunchClear?',...
                            'Log Accel(@body frame)','Yes','No',obj.Ab_log);
                        obj.Ab_log = char(input);
                        if strcmp(obj.Ab_log,'Yes')
                            input = inputdlg('Time of Accel Log?[s]',...
                            'Time of Accel Log',[1,40],cellstr(num2str(obj.t_Ab_log)));
                            obj.t_Ab_log = str2double(input);
                        end
                    end
                    if sum(change==4) > 0
                        obj = obj.set_log;
                    end
                    if sum(change==5) > 0
                        obj = obj.set_feat;
                    end
                    if sum(change==6) > 0
                        set = 'No';
                    end
                end
            end
            obj.disp_set('set_output')
            obj.disp_set('set_log')
            obj.disp_set('set_feat')
        end
        
        function obj = set_log(obj)         %ログ記録変数設定
            str = obj.log_str;
            set = 'Yes';
            while strcmp(set,'Yes')
                variable = inputdlg(["Variable Name","Variable","Reference Value"],...
                    'Variable Registration',[1,40;1,40;1,40],{'','',''});
                if isempty(variable) == 0
                    obj.log_list = [obj.log_list; string(variable(2))];
                    obj.log = [obj.log; string(variable(3))];
                    str = [str;strcat(variable(1),'(',variable(2),')')];
                    set = questdlg('Add more Variables？',...
                        'Add more Variables','Yes','No','No');
                else
                    set = 'No';
                end
            end
            obj.log_str = str;
            obj.disp_set('set_log')
        end
        
        function obj = set_feat(obj)    %記録特徴値設定
            str = obj.feat_str;
            set = 'Yes';
            while strcmp(set,'Yes')
                variable = inputdlg(["FeatureValue Name","FeatureValue","Reference Value"],...
                    'FeatureValue Registration',[1,40;1,40;1,40],{'','',''});
                if isempty(variable) == 0
                    obj.feat_list = [obj.feat_list; string(variable(2))];
                    obj.feat = [obj.feat; string(variable(3))];
                    str = [str;strcat(variable(1),'(',variable(2),')')];
                    set = questdlg('Add more FeatureValues？',...
                        'Add more FeatureValues','Yes','No','No');
                else
                    set = 'No';
                end
            end
            obj.feat_str = str;
            obj.disp_set('set_feat')
        end
        
        function obj = set_option(obj)      %オプション設定
            list = ["AutoJudge","LimitArea","LimitArea PreView","Parallel","Complete"];
            set = 'Yes';
            while strcmp(set, 'Yes')
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    if sum(change==1) > 0
                        input = questdlg('Use Auto Judge Function?',...
                            'Use Auto Judge','Yes','No',obj.auto_judge);
                        obj.auto_judge = char(input);
                    end
                    if sum(change==2) > 0
                        cd(strcat(obj.dir_home,'/LaunchSite'))
                        [fn,path] = uigetfile('*.xlsx','Limited Area Data File');
                        if isfile(strcat(path,"/",fn))       %ファイルが正常に選択された場合、判定機能をオンにする
                            obj.limit_area.fn = string(fn);
                            obj.limit_area.path = string(path);
                            fn = strcat(path,"/",fn);
                            obj.auto_judge = 'Yes';
                            coord_tab = readmatrix(fn,'Sheet','Info',...
                                'Range','B3:D3','OutputType','string');
                            obj.limit_area.coord = coord_tab(1,1);
                            obj.limit_area.type = coord_tab(1,2);
                            obj.limit_area.rot = coord_tab(1,3);
                            obj.limit_area.circle.(coord_tab(1,1)) =...
                                readmatrix(fn,'Sheet','CenterPoint');
                            obj.limit_area.origin = obj.limit_area.circle.(coord_tab(1,1))(1,:)
                            obj.limit_area.polygon.(coord_tab(1,1)) =...
                                readmatrix(fn,'Sheet','Polygon');
                        else                %ファイルが正常に選択されなかった場合、判定機能をオフにする
                            warning('CANNNOT read Limited Area Data File!')
                            disp('Auto Judge Function will be turn OFF...')
                            obj.auto_judge = 'No';
                        end
                        cd(obj.dir_scr)
                        obj = obj.calc_limit_area;
                    end
                    if sum(change==3) > 0
                        obj.limit_preview;
                    end
                    if sum(change==4) > 0
                        if ismember("Parallel Computing Toolbox",obj.add_list)
                            input = questdlg('Use Parallel Computing?',...
                                'Use Parallel Computing','Yes','No',obj.parallel);
                            obj.parallel = char(input);
                        else
                            warning('CANNOT use Parallel Computing!')
                            warning('(MATLAB Addon "Parallel Computing Toolbox" is NOT installed.)')
                            obj.parallel = 'No';
                        end
                    end
                    if sum(change==5) > 0
                        set = 'No'; 
                    end
                end
            end
            close all
            obj.disp_set('set_opt')
        end
        
        function obj = calc_limit_area(obj)     %落下制限区域関連の計算
            x_list = ["circle"; "polygon"];
            obj.ll = lon_lat(obj.limit_area.origin);
            for h = 1:2
                if isempty(obj.limit_area.(x_list{h,:}).geo) && isempty(obj.limit_area.(x_list{h,:}).dist)
                    warning(strcat('Limit Area "',x_list{h,:},'" is NOT set correctly!'))
                else
                    switch obj.limit_area.coord
                        case "geo"
                            x_geo = obj.limit_area.(x_list{h,:}).geo;
                            x_dist = zeros(size(x_geo));
                            for i = 1:size(x_geo,1)
                                x_dist(i,1:2) = obj.ll.Vincenty_position(x_geo(i,1:2));
                                if h == 1
                                    x_dist(i,3) = x_geo(i,3);
                                end
                                if strcmp(obj.view_azm,'Magnetic')
                                    x_dist(i,1:2) = x_dist(i,1:2) *...
                                        [cosd(-obj.mgd), sind(-obj.mgd);
                                        -sind(-obj.mgd), cosd(-obj.mgd)];
                                end
                            end
                            obj.limit_area.(x_list{h,:}).dist = x_dist;
                            
                        case "dist"
                            x_dist = obj.limit_area.(x_list{h,:}).dist;
                            x_geo = zeros(size(x_dist));
                            for i = 1:size(x_dist,1)
                                if strcmp(obj.limit_area.type,'ME')
                                    x_dist(i,1:2) = x_dist(i,1:2) *...
                                        [cosd(obj.mgd), sind(obj.mgd);
                                        -sind(obj.mgd), cosd(obj.mgd)];
                                end
                                x_geo(i,1:2) = obj.ll.Vincenty_direct(x_dist(i,1:2));
                                if h == 1
                                    x_geo(i,3) = x_dist(i,3);
                                end
                            end
                            obj.limit_area.(x_list{h,:}).geo = x_geo;
                    end
                end
            end
        end
        
        function obj = set_disp(obj)    %各種出力図設定
            obj.disp_set('set_disp')
            list = ["Output Figure","FlightPath","FallPoint",...
                "KML of FlightPath","KML of FallPoint","Complete"];
            set = 'Yes';
            while strcmp(set, 'Yes')
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    if sum(change==1) > 0
                        list_slct = ["FlightPath","FallPoint",...
                            "KML of FlightPath","KML of FallPoint","None"];
                        [lf,~] = listdlg('ListString',list_slct,...
                            'PromptString','Select Output Figures:');
                        obj.list_fig = list_slct(lf)';
                        if ismember('None',obj.list_fig)
                            obj.list_fig = "";
                        end
                    end
                    if sum(change==2) > 0
                        obj = obj.set_path;
                    end
                    if sum(change==3) > 0
                        obj = obj.set_point;
                    end
                    if sum(change==4)
                        obj = obj.set_kml('path');
                    end
                    if sum(change==5)
                        obj = obj.set_kml('point');
                    end
                    if sum(change==6) > 0
                        set = 'No'; 
                    end
                end
            end
            obj.disp_set('set_disp')
        end
        
        function obj = set_path(obj)        %飛行経路図出力設定
            [fig, tmp_lgd] = obj.path_preview;
            obj.disp_set('set_path')
            list_slct = ["Window","Axis","Legend","FlightEvent","Complete"];
            set = 'Yes';
            while strcmp(set,'Yes')
                [change,tf] = listdlg('ListString',list_slct,...
                    'PromptString','Select Setting to Change:');
                setting = 1;
                if tf == 1
                    if sum(change==1) > 0      %Windowのサイズ・位置調節
                        while setting == 1
                            sz = fig.Position;
                            value = inputdlg({'left','bottom','width','height'},...
                                'Window Size',[1 40],string(sz));
                            value = str2double(string(value))';
                            if sz == value
                                setting = 0;
                            else
                                sz = value;
                                fig.Position = sz;
                            end
                        end
                        obj.fig_size.point = sz;
                    end
                    if sum(change==2) > 0
                        obj = obj.set_ax('path');
                    end
                    if sum(change==3) > 0
                        [obj, tmp_lgd] = obj.set_lgd(tmp_lgd,'path');
                    end
                    if sum(change==4) > 0
                        [obj, fig, tmp_lgd] = obj.set_FlightEvent(fig);
                    end
                    if sum(change==5) > 0
                        set = 'No';
                    end
                end
            end
            hold off
            close(fig)
        end
        
        function [obj,fig,lgd] = set_FlightEvent(obj,fig)   %飛行イベント設定
            set = 'Yes';
            while strcmp(set,"Yes")
                eve_list = string(fieldnames(obj.event));
                if isempty(eve_list)
                    list = ["Add events";"Complete"];
                else
                    list = [eve_list;"Add events";"Complete"];
                end
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    ch_list = list(change);
                    ex = ismember(ch_list,eve_list);
                    ex_list = ch_list(ex);
                    if isempty(ex_list) == 0
                        for i = 1:size(ex_list,2)
                            obj = obj.change_FlightEvents(ex_list(i,:),"ch");
                        end
                    end
                    if ismember("Add events",ch_list)
                        obj = obj.change_FlightEvents("","ad");
                    end
                    if ismember("Complete",ch_list)
                        set = "No";
                    end
                else
                    set = "No";
                end
                close(fig)
                [fig,lgd] = obj.path_preview;
            end
            obj.disp_set('set_path')
        end
        
        function obj = change_FlightEvents(obj,var_name,str)     %飛行イベントの詳細設定
            list = ["disp","Applying stage","Applying mode_landing",...
                "delete","Complete"];
            set = 'Yes';
            while strcmp(set,'Yes')
                switch str
                    case "ch"
                        disp_str = ["-----FlightEvents-----";
                            strcat("Now Setting ",var_name,"...");
                            strcat("Dipslay:",obj.event.(var_name).disp);
                            strcat("Applying stage:",num2str(obj.event.(var_name).stage));
                            strcat("Applying mode_landing:",obj.event.(var_name).mode_land)];
                        for i = 1:4
                            disp(disp_str(i,:))
                        end
                        [change,tf] = listdlg('ListString',list,...
                            'PromptString','Select Setting to Change:');
                    case "ad"
                         var = inputdlg(["Event Name","Reference Value"],...
                            'Variable Registration',[1,40],["",""]);
                        if isempty(var) == 0
                            var = string(var);
                            var_name = var(1,:);
                            obj.event.(var_name) = struct(...
                                'disp',"Yes",...
                                'ref',var(2,:),...
                                'stage',1,...
                                'mode_land',"Both");
                            change = [2 3];
                            tf = 1;
                        else
                            set = 'No';
                            tf = 0;
                        end
                end
                if tf == 1
                    if sum(change==1) > 0
                        val = questdlg(strcat('Display ',var_name,'?'),...
                            'More Variable Registration','Yes','No',...
                            obj.event.(var_name).disp);
                        obj.event.(var_name).disp = val;
                    end
                    if sum(change==2) > 0
                        stage_list = string(1:1:obj.param_n);
                        [stage_ch,stage_tf] = listdlg('ListString',stage_list,...
                            'PromptString','Select applying stage:');
                        if stage_tf == 1
                            obj.event.(var_name).stage = stage_ch;
                        else
                            obj.event.(var_name).stage = 1:obj.param_n;
                        end
                    end
                    if sum(change==3) > 0
                        val = questdlg('Applying landing mode?',...
                            'Select Applying landing mode',...
                            'Hard','Descent','Both',obj.event.(var_name).mode_land);
                        obj.event.(var_name).mode_land = val;
                    end
                    if sum(change==4) > 0
                        obj.event = rmfield(obj.event,var_name);
                        set = 'No';
                    end
                    if sum(change==5) > 0
                        set = 'No';
                    end
                end
                if strcmp(set,'Yes')
                    if strcmp(str,"ad")
                        set = questdlg('Add more Events?',...
                            'More Variable Registration','Yes','No','No');
                    end
                end
            end
        end
        
        function [fig, tmp_lgd] = path_preview(obj)         %飛行経路図プレビュー表示
            u = 1:500;
            x = u * cosd(30);
            y = -u * sind(30);
            a = 1000/250^2;
            v = -a * (u - 250).^2 +1000;
            ax_set = obj.ax.path;
            lgd_set = obj.lgd.path;
            eve_list = string(fieldnames(obj.event));
            
            fig = figure('Name','Preview of FallPoint Figure',...
                'Position',obj.fig_size.path);
            for i = 1:obj.param_n
                z = v * i;
                if obj.param_n == 1
                    color = obj.line.Color(1,:);
                else
                    color = interp1([1;obj.param_n],obj.line.Color,i);
                end
                plot3(x,y,z,'Color',color,'LineWidth',obj.line.Width,...
                    'DisplayName',strcat(num2str(i),' stage'));
                hold on
                %飛行イベント表示
                
                for k = 1:size(eve_list,1)
                    tmp_eve = obj.event.(eve_list{k,:});
                    if strcmp(eve_list(1,:),"")==0 && ismember(i,tmp_eve.stage) && strcmp(tmp_eve.disp,"Yes")
                        t = ceil(rand * 500);
                        str = num2str(i);
                        switch str(1,size(str,2))
                            case '1'
                                stage_str = strcat(str,'st');
                            case '2'
                                stage_str = strcat(str,'nd');
                            case '3'
                                stage_str = strcat(str,'rd');
                            otherwise
                                stage_str = strcat(num2str(i),'th');
                        end
                        text(x(t),y(t),z(t),...
                            strcat("\leftarrow",stage_str," ",eve_list(k,:)))
                    end
                end
            end
            grid on
            
            %軸設定
            tmp_ax = gca;
            xlabel(ax_set.label(1,:))
            ylabel(ax_set.label(2,:))
            zlabel(ax_set.label(3,:))
            tmp_ax.FontSize = ax_set.FontSize;
            tmp_ax.XColor = ax_set.Color;
            tmp_ax.YColor = ax_set.Color;
            tmp_ax.ZColor = ax_set.Color;
            tmp_ax.FontWeight = ax_set.FontWeight;
            %凡例作成・設定
            tmp_lgd = legend;
            tmp_lgd.Position = lgd_set.pos;
            tmp_lgd.FontSize = lgd_set.FontSize;
            tmp_lgd.TextColor = lgd_set.TextColor;
            tmp_lgd.FontWeight = lgd_set.FontWeight;
        end
        
        function obj = set_point(obj)    %落下分散図出力設定
            [fig, tmp_lgd] = obj.point_preview;
            obj.disp_set('set_point')
            list_slct = ["Window","BP_File","BP_Position","view_azm",...
                "axis","marker","Legend","LimitArea PreView","Complete"];
            set = 'Yes';
            while strcmp(set,'Yes')
                [change,tf] = listdlg('ListString',list_slct,...
                    'PromptString','Select Setting to Change:');
                setting = 1;
                if tf == 1
                    if sum(change==1) > 0      %Windowのサイズ・位置調節
                        while setting == 1
                            sz = fig.Position;
                            value = inputdlg(["left","bottom","width","height"],...
                                'Window Size',[1 40],string(sz));
                            value = str2double(string(value))';
                            if sz == value
                                setting = 0;
                            else
                                sz = value;
                                fig.Position = sz;
                            end
                        end
                        obj.fig_size.point = sz;
                    end
                    if sum(change==2) > 0
                        cd(strcat(obj.dir_home,'/LaunchSite'))
                        [img_fn,path] = uigetfile({'*.jpg;*.png'},'LunchSite File');
                        cd(path)
                        img_fn = char(img_fn);
                        img = imread(img_fn);
                        obj.back_pict.img = flipud(img);    %←図とグラフでy軸方向が逆
                        cd(obj.dir_scr)
                    end
                    if sum(change==3) > 0      %落下可能域図の位置調節
                        pict_pos = obj.back_pict.pos;
                        while setting == 1
                            value = reshape(pict_pos', [1,4]);
                            value = inputdlg(["x_min","x_max","y_min","y_max"],...
                                'BackPicture Size',[1 40],string(value));
                            value = str2double(string(value));
                            value = reshape(value, [2,2])';
                            if pict_pos == value
                                setting = 0;
                            else
                                pict_pos = value;
                                obj.back_pict.pos = pict_pos;
                                close(fig)
                                [fig, tmp_lgd] = obj.point_preview;
                            end
                        end
                    end
                    if sum(change==4) > 0      %落下分散図の基準方位設定
                        input = questdlg('出力図正方向?','veiw_azm',...
                            'Magnetic','True',obj.view_azm);
                        obj.view_azm = char(input);
                    end
                    if sum(change==5) > 0
                        obj = obj.set_ax('point');
                    end
                    if sum(change==6) > 0
                        [obj, fig, tmp_lgd] = obj.set_marker(fig);
                    end
                    if sum(change==7) > 0
                        [obj, tmp_lgd] = obj.set_lgd(tmp_lgd,'point');
                    end
                    if sum(change==8) > 0
                        obj.limit_preview;
                    end
                    if sum(change==9) > 0
                        set = 'No';
                    end
                end
            end
            close all
            obj.disp_set('set_point')
        end
        
        function [fig, tmp_lgd] = point_preview(obj)    %落下分散図プレビュー表示
            back_set = obj.back_pict;
            ax_set = obj.ax.point;
            lgd_set = obj.lgd.point;
            marker_set = obj.marker;
            
            fig = figure('Name','Preview of FallPoint Figure',...
                'Position',obj.fig_size.point);
            axis(ax_set.range)
            hold on
            image(back_set.pos(1,:),back_set.pos(2,:),back_set.img)
            switch marker_set.mode
                case 'shape'
                    mkr_list = ['o';'s';'d';'^';'p';'h';'+';'*';'x'];
                    for i = 1:obj.Vw0_n
                        mkr = mkr_list(i);
                        scatter(i*50,i*50,marker_set.size,marker_set.color(1,:),mkr,...
                            'LineWidth',1.5,'MarkerFaceColor',marker_set.mfc,...
                            'DisplayName',strcat(num2str(obj.Vw0(i)),'m/s'));
                    end
                case 'gradation'
                    if obj.Vw0_n > 1
                        color = interp1([1,obj.Vw0_n],marker_set.color,1:obj.Vw0_n);
                    else
                        color = marker_set.color(1,:);
                    end
                    for i = 1:obj.Vw0_n
                        scatter(i*50,i*50,marker_set.size,color(i,:),marker_set.shape,...
                            'LineWidth',1.5,'MarkerFaceColor',marker_set.mfc,...
                            'DisplayName',strcat(num2str(obj.Vw0(i)),'m/s'));
                    end
            end
            %軸設定
            tmp_ax = gca;
            xlabel(ax_set.label(1,:))
            ylabel(ax_set.label(2,:))
            tmp_ax.FontSize = ax_set.FontSize;
            tmp_ax.XColor = ax_set.Color;
            tmp_ax.YColor = ax_set.Color;
            tmp_ax.FontWeight = ax_set.FontWeight;
            %凡例作成・設定
            tmp_lgd = legend('boxoff');
            tmp_lgd.Position = lgd_set.pos;
            tmp_lgd.FontSize = lgd_set.FontSize;
            tmp_lgd.TextColor = lgd_set.TextColor;
            tmp_lgd.FontWeight = lgd_set.FontWeight;
        end
        
        function limit_preview(obj)     %落下制限区域プレビュー表示
            circle = obj.limit_area.circle.dist;
            polygon = obj.limit_area.polygon.dist;
            siz = obj.fig_size.point;
            back = obj.back_pict;
            ax_set = obj.ax.point;
            lgd_set = obj.lgd.point;
            
            if isempty(obj.back_pict.img) == 0
                if isempty(circle) && isempty(polygon)
                    warning("Limited Area Data is EMPTY!")
                else
                    fig = figure('Name','Preview of Limited Area','Position',siz);
                    axis(ax_set.range)
                    hold on
                    if isempty(circle) == 0
                        image(back.pos(1,:),back.pos(2,:),back.img)
                        scatter(circle(:,1),circle(:,2),'MarkerEdgeColor','r',...
                            'MarkerFaceColor','r','DisplayName','Limited Circle');
                        for i = 1:size(circle,1)
                            xc = circle(i,1);
                            yc = circle(i,2);
                            r = circle(i,3);
                            theta = linspace(0, 2*pi);
                            x = r * cos(theta) + xc;
                            y = r * sin(theta) + yc;
                            plot(x, y, 'Color','r','DisplayName','');
                        end
                    end
                    if isempty(polygon) == 0
                        polygon = [polygon; polygon(1,:)];
                        plot(polygon(:,1),polygon(:,2),'-o','Color','y','MarkerEdgeColor','y',...
                            'MarkerFaceColor','y','DisplayName','Limited Polygon')
                    end
                    tmp_lgd = legend('boxoff');
                    tmp_lgd.Position = lgd_set.pos;
                    tmp_lgd.FontSize = lgd_set.FontSize;
                    tmp_lgd.TextColor = lgd_set.TextColor;
                    tmp_lgd.FontWeight = lgd_set.FontWeight;
                    hold off
                end
            else
                warning("Picture of Limited Area is NOT selected!")
            end
        end
        
        function obj = set_point_view(obj)      %落下分散図表示設定
            if obj.Vw0_n > 9        %条件数がマーカー種類上限(9)を超える場合はgradationに強制変更
                warning("'gradation' is selected for Marker Detect Mode.")
                warning("(Number of Vw0-condition is more than of Markers!)")
                obj.marker.mode = 'gradation';
            end
            
            [fig, tmp_lgd] = obj.point_preview;
            
            set = 'Yes';
            while strcmp(set,'Yes')
                list = ["Window","BackPict","axis","marker","Legend","Complete"];
                [change,tf] = listdlg('ListString',list,...
                                            'PromptString','Select Setting to Change:');
                setting = 1;
                if tf == 1
                    if sum(change==1) > 0      %Windowのサイズ・位置調節
                        while setting == 1
                            sz = fig.Position;
                            value = inputdlg({'left','bottom','width','height'},...
                                'Window Size',[1 40],string(sz));
                            value = str2double(string(value))';
                            if sz == value
                                setting = 0;
                            else
                                sz = value;
                                fig.Position = sz;
                            end
                        end
                        obj.fig_size.point = sz;
                    end
                    if sum(change==2) > 0      %落下可能域図の位置調節
                        pict_pos = obj.back_pict.pos;
                        while setting == 1
                            value = reshape(pict_pos', [1,4]);
                            value = inputdlg({'x_min','x_max','y_min','y_max'},...
                                'BackPicture Size',[1 40],string(value));
                            value = str2double(string(value));
                            value = reshape(value, [2,2])';
                            if pict_pos == value
                                setting = 0;
                            else
                                pict_pos = value;
                                obj.back_pict.pos = pict_pos;
                                close(fig)
                                [fig, tmp_lgd] = obj.point_preview;
                            end
                        end
                    end
                    if sum(change==3) > 0
                        obj = obj.set_ax;
                    end
                    if sum(change==4) > 0
                        [obj, fig, tmp_lgd] = obj.set_marker(fig, tmp_lgd);
                    end
                    if sum(change==5) > 0
                        [obj, tmp_lgd] = obj.set_lgd(tmp_lgd);
                    end
                    if sum(change==6) > 0
                        set = 'No';
                    end
                end
            end
            hold off
            close(fig)
        end
        
        function obj = set_ax(obj ,str)         %軸設定
            list = ["Range","Label","FontSize","TextColor","FontWegiht","Complete"];
            tmp_ax = gca;
            set = 'Yes';
            while strcmp(set,'Yes')
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    if sum(change==1)
                        if strcmp(str,'path')
                            warning("Axis range setting for FlightPath is not supported!")
                        else
                            ax_range = obj.ax.(str).range;
                            setting = 1;
                            while setting == 1
                                value = inputdlg({'x_min','x_max','y_min','y_max'},...
                                    'Set Axis Size',[1 40],string(ax_range));
                                value = str2double(string(value))';
                                if ax_range == value
                                    setting = 0;
                                else
                                    ax_range = value;
                                    axis(ax_range)
                                end
                            end
                            obj.ax.(str).range = ax_range;
                        end
                    end
                    if sum(change==2)
                        label = obj.ax.(str).label;
                        if strcmp(str,'path')
                            label = inputdlg({'x-axis label';'y-axis label';'z-axis label'},...
                                "Set Axis' Label",[1,40],label);
                            label = string(label);
                            if isempty(label) == 0
                                xlabel(label(1,:))
                                ylabel(label(2,:))
                                zlabel(label(2,:))
                                obj.ax.(str).label = label;
                            end
                        else
                            label = inputdlg({'x-axis label';'y-axis label'},...
                                "Set Axis' Label",[1,40],label);
                            label = string(label);
                            if isempty(label) == 0
                                xlabel(label(1,:))
                                ylabel(label(2,:))
                                obj.ax.(str).label = label;
                            end
                        end
                    end
                    if sum(change==3)
                        FontSize = obj.ax.(str).FontSize;
                        setting = 1;
                        while setting == 1
                            value = inputdlg('Font Size [pt]',"Set Axis's Font Size",...
                                [1,40], string(FontSize));
                            value = str2double(string(value));
                            if FontSize == value
                                setting = 0;
                            else
                                FontSize = value;
                                tmp_ax.FontSize = FontSize;
                            end
                        end
                        obj.ax.(str).FontSize = FontSize;
                    end
                    if sum(change==4)
                        color = string(obj.ax.(str).Color);
                        color = inputdlg(["R", "G", "B"],"Set Axis Color",...
                            [1,40], string(color));
                        color = str2double(string(color))';
                        if isempty(color) == 0
                            tmp_ax.XColor = color;
                            tmp_ax.YColor = color;
                            if strcmp(str,'path')
                                tmp_ax.ZColor = color;
                            end
                            obj.ax.(str).Color = color;
                        end
                    end
                    if sum(change==5)
                        input = questdlg('Font Weight？',"Set Axis' Font Weight",...
                            'bold','normal',obj.ax.(str).FontWeight);
                        obj.ax.(str).FontWeight = char(input);
                        tmp_ax.FontWeight = char(input); 
                    end
                    if sum(change==6)
                        set = 'No';
                    end
                end
            end
        end
        
        function [obj, fig, lgd] = set_marker(obj, fig, lgd)    %マーカー設定
            list = ["Detect mode","Color","Marker size","Shape","MakerFaceColor","Complete"];
            set = 'Yes';
            while strcmp(set,'Yes')
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    if sum(change==1)
                        if obj.Vw0_n < 10
                            input = questdlg('Marker Detect Mode？',"Select Marker Detect Mode",...
                                'shape','gradation',obj.marker.mode);
                            obj.marker.mode = char(input);
                            close(fig)
                            [fig,lgd] = obj.point_preview;
                        else
                            warning("'gradation' is selected for Marker Detect Mode.")
                            warning("(Number of Vw0-condition is more than of Markers!)")
                            obj.marker.mode = 'gradation';
                        end
                    end
                    if sum(change==2)
                        color = obj.marker.color;
                        setting = 1;
                        while setting == 1
                            switch obj.marker.mode
                                case 'shape'
                                    value = inputdlg(["R", "G", "B"],"Set Marker Color",...
                                        [1,40], string(color(1,:)));
                                    value = string(value)';
                                case 'gradation'
                                    value1 = inputdlg(["R", "G", "B"],"Set Marker Color",...
                                        [1,40], string(color(1,:)));
                                    value2 = inputdlg(["R", "G", "B"],"Set Marker Color",...
                                        [1,40], string(color(2,:)));
                                    value1 = string(value1)';
                                    value2 = string(value2)';
                                    value = [value1; value2];
                            end
                            value = str2double(value);
                            if color == value
                                setting = 0;
                            else
                                color = value;
                                obj.marker.color(1:size(value,1),:) = value;
                                close(fig)
                                [fig,lgd] = obj.point_preview;
                            end
                        end
                    end
                    if sum(change==3)
                        setting = 1;
                        mark_size = obj.marker.size;
                        while setting == 1
                            value = inputdlg('Marker Size [pt]',"Set Marker Size",...
                                [1,40], string(mark_size));
                            value = str2double(string(value));
                            if mark_size == value
                                setting = 0;
                            else
                                mark_size = value;
                                obj.marker.size = mark_size;
                                close(fig)
                                [fig,lgd] = obj.point_preview;
                            end
                        end
                    end
                    if sum(change==4)
                        if strcmp(obj.marker.mode,'shape')
                            input = questdlg("Change Marker Detect Mode to 'gradation'?",...
                                "Change Marker Detect Mode",...
                                'Yes','No','No');
                            input = char(input);
                            if strcmp(input,'Yes')
                                obj.marker.mode = 'gradation';
                            end
                        end
                        if strcmp(obj.marker.mode,'gradation')
                            value = inputdlg('Marker Shape?',"Set Marker Shape",...
                                [1,40], obj.marker.shape);
                            value = string(value);
                            if isempty(value) == 0
                                obj.marker.shape = value;
                                close(fig)
                                [fig,lgd] = obj.point_preview;
                            end
                        end
                    end
                    if sum(change==5)
                        input = questdlg('Marker Face Color？',...
                            "Set Marker Face Color",...
                            'flat','none',obj.marker.mfc);
                        obj.marker.mfc = char(input);
                        close(fig)
                        [fig,lgd] = obj.point_preview;
                    end
                    if sum(change==6)
                        set = 'No';
                    end
                end
            end
        end
        
        function [obj, lgd] = set_lgd(obj, lgd, str)        %凡例設定
            list = ["LegendPos","FontSize","TextColor","TextWegiht","Complete"];
            set = 'Yes';
            while strcmp(set,'Yes')
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    if sum(change==1)
                        setting = 1;
                        pos = obj.lgd.(str).pos;
                        while setting == 1
                            value = inputdlg({'left','bottom','width','height'},...
                                'Set Legend Size',[1 40],string(pos));
                            value = str2double(string(value))';
                            if pos == value
                                setting = 0;
                            else
                                pos = value;
                                lgd.Position = pos;
                            end
                        end
                        obj.lgd.(str).pos = pos;
                    end
                    if sum(change==2)
                        setting = 1;
                        FontSize = obj.lgd.(str).FontSize;
                        while setting == 1
                            value = inputdlg('Font Size?',"Set Legend's Font Size",...
                                [1 40],string(FontSize));
                            value = str2double(string(value));
                            if FontSize == value
                                setting = 0;
                            else
                                FontSize = value;
                                lgd.FontSize = FontSize;
                            end
                        end
                        obj.lgd.(str).pos = FontSize;
                    end
                    if sum(change==3)
                        setting = 1;
                        color = obj.lgd.(str).TextColor;
                        while setting == 1
                            value = inputdlg(["R", "G", "B"],"Set Legend's Text Color",...
                                [1,40], string(color));
                            value = str2double(string(value))';
                            if color == value
                                setting = 0;
                            else
                                color = value;
                                lgd.TextColor = color;
                            end
                        end
                        obj.lgd.(str).TextColor = color;
                    end
                    if sum(change==4)
                        input = questdlg('Font Weight？',"Set Legend's Font Weight",...
                            'bold','normal',obj.lgd.(str).FontWeight);
                        obj.lgd.(str).FontWeight = char(input);
                        lgd.FontWeight = char(input);
                    end
                    if sum(change==5)
                        set = 'No';
                    end
                end
            end
        end
        
        function obj = set_kml(obj, set_str)        %GoogleEarth用kmlファイル出力設定
            list = ["Line Color","Line Width","Complete"];
            set = 'Yes';
            
            while strcmp(set,'Yes')
                [change,tf] = listdlg('ListString',list,...
                    'PromptString','Select Setting to Change:');
                if tf == 1
                    if sum(change==1)
                        color = obj.kml.(set_str).Color;
                        color = inputdlg(["R", "G", "B"],"Set kml data's Line Color",...
                            [1,40], string(color));
                        color = str2double(string(color))';
                        if isempty(color) == 0
                            obj.kml.(set_str).Color = color;
                        end
                    end
                    if sum(change==2)
                        width = obj.kml.(set_str).Width;
                        value = inputdlg("Line Width","Set kml data's Line Width",...
                            [1,40], string(width));
                        width = str2double(string(value))';
                        if isempty(width) == 0
                            obj.kml.(set_str).Width = width;
                        end
                    end
                    if sum(change==3)
                        set = 'No';
                    end
                end
            end
        end
    end
end
            