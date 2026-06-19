%Spica
%計算実行+結果整理用クラス
%-------------------------------------------------------------------------%
classdef Calculation
    properties
        %-----directry-----
        dir_home = '';              %ホームディレクトリ(Spicaフォルダ)
        dir_res = '';               %Resultフォルダ
        dir_scr = '';               %Scriptフォルダ
        dir_form = '';              %Formatsフォルダ
        
        %-----parameter-----
        param = [];                 %機体パラメータ(MainSolverクラス)
        param_fn = '';              %諸元表ファイル名
        param_path = '';            %諸元表インデックス
        param_n = 1;                %全段数
        CP_fn = '';                 %圧力中心位置データファイル名
        CP_index = '';              %圧力中心位置データインデックス
        thrust_fn = '';             %推力履歴ファイル名
        thrust_path = '';           %推力履歴インデックス
        t_max = 100;                %計算打切り時間
        freq = 200;                 %計算レート
        wind_model = 'PowerLaw';    %風速モデル
        MSM_fn = '';                %MSMデータファイル名(.nc形式)
        wind_fn = '';               %風速実データファイル名(.csv形式)
        mode_export = 'Default';    %結果ファイルの出力先設定
        tipoff_model = 'Do not';    %チップオフモード
        lug_error = 0;              %ランチラグ位相誤差によるランチャに対する機体の初期姿勢角
        
        %-----option-----
        auto_judge = 'No';          %風向風速制限の自動判定機能
        Ab_log = 'No';              %ランチクリア直後の加速度ログの出力機能
        t_Ab_log = 0;               %↑の記録時間
        parallel= 'Yes';            %CPU並列計算機能
        
        %-----calculating condition-----
        base_azm = 'ME';            %基準方位 M:Magnetic T:True, E:East N:North ...
        mode_angle = 'CCW';         %方位角の正方向 CW:ClockWise, CCW:CounterClockWise
        view_azm = 'Magnetic';      %落下分散図の基準方位種類
        mode_calc = 'Single';       %計算モード  Single, Multiple
        mode_landing = 'Hard';      %降下モード  Hard, Descent, Both
        descent_model = 'Vw_model'; %減速降下モデル    Vw_model, Dynamics
        elev_set = zeros(3,1);      %射角設定
        Vw0_set = zeros(3,1);       %基準風速設定
        Wpsi_set = zeros(3,1);      %風向設定
        mgd = 0;                    %射点磁気偏角(西偏=正)
        
        %-----calculating-----
        elev = [];                  %射角リスト
        Vw0 = [];                    %風速リスト
        Wpsi = [];                  %風向リスト
        Wpsi_res = [];              %風向リスト(結果用)
        elev_n = 0;                 %射角条件数
        Vw0_n = 0;                  %風速条件数
        Wpsi_n = 0;                 %風向条件数
        
        %-----variable-----
        output = '';                %出力データ設定
        log_list = '';              %ログ記録変数名リスト
        log = '';                   %ログ記録変数リスト
        feat_list = '';             %特徴値名リスト
        feat = '';                  %特徴値リスト
        
        %-----result-----
        result_name = ["Hard";"Descent"];   %結果配列名
        Hard = [];                          %弾道計算結果(MainSolverクラス)
        Descent = [];                       %減速計算結果(MainSolverクラス)
        logName = [];                       %ログ変数名
        feature = [];                       %特徴値
        feat_min = [];                      %各特徴値の最小値(制限内)
        feat_max = [];                      %各特徴値の最大値(制限内)
        featureName = [];                   %特徴値名
        ll = [];                            %経緯度変換用クラス(lon_latクラス)
        
        %-----judge-----
        judge = [];                 %風向風速制限判定結果
        limit_area = struct(...
            'coord',"geo",...
            'polygon', struct(...
                'geo', zeros(1,3),...
                'dist', zeros(1,3)),...
            'circle', struct(...
                'geo', zeros(1,3),...
                'dist', zeros(1)));   %落下制限区域
        
    end
    
    methods
        function obj = Calculation(gs)  %コンストラクタメソッド GS:GeneralSettingクラス
            %GSクラスのプロパティを代入
            gs_list = properties(gs);
            cc_list = properties(obj);
            list = ismember(cc_list,gs_list);
            list_true = cc_list(list==1);
            for i = 1:size(list_true,1)
                obj.(list_true{i,:}) = gs.(list_true{i,:});
            end
            obj.log_list = ["t";obj.log_list];
            obj.log = ["ts(1:1,:)";obj.log];
            if strcmp(obj.mode_landing,'Both')
                obj.mode_landing = ["Hard";"Descent"];
            end
            if ismember("t_landing",obj.feat_list)
                obj.feat_list(obj.feat_list=="t_landing") = [];
                obj.feat_list = [obj.feat_list;strcat("t_",obj.mode_landing)];
                obj.feat = [obj.feat;repmat("t_landing",size(obj.mode_landing,1),1)];
            end
            if ismember("FP",obj.feat_list)
                obj.feat_list(obj.feat_list=="FP") = [];
                obj.feat_list = [obj.feat_list;strcat("FP_",obj.mode_landing)];
                obj.feat = [obj.feat;repmat("xe",size(obj.mode_landing,1),1)];
            end
            
            %MainSolverクラス作成
            obj.param = repmat(MainSolver(gs,1),1,obj.param_n);
            for i = 2:obj.param_n
                obj.param(i) = MainSolver(gs,i);
            end
            
            %計算実行
            obj = obj.calc;
        end
        
        function obj = calc(obj)    %計算実行関数
            disp(" ")
            disp("***** Calculation Start! *****")
            for i = 1:size(obj.mode_landing,1)
                disp(strcat("Landing Mode：",obj.mode_landing{i,:}))
                for k = 1:obj.param_n
                    obj.param(k).mode_landing = obj.mode_landing{i,:};
                end
                if strcmp(obj.mode_calc,'Single')
                    obj.(obj.mode_landing{i,:}) = obj.Single;
                else
                    obj.(obj.mode_landing{i,:}) = obj.Multiple;
                end
            end
            obj = obj.Record_FeatVal;
            if strcmp(obj.auto_judge,'Yes')
                obj = obj.cond_judge;
            end
        end
        
        function result = Single(obj)  %単一条件計算(Single)
            result = repmat(obj.param(1),1,obj.param_n);
            result = obj.simulation(result,1,1,1);
            if ismember("vs-time_Logs",obj.output)
                obj.Record_Log(result)
            end
        end
        
        function result = Multiple(obj)     %複数条件計算(Multiple,FallPoint)
            %MainSolverクラスから結果配列を作成
            %射角数×風速数×風向数×段数の4次元MainSolverクラス
            result = repmat(obj.param(1),obj.elev_n,...
                obj.Vw0_n,obj.Wpsi_n,obj.param_n);
            for i = 2:obj.param_n
                result(:,:,:,i) = repmat(obj.param(i),obj.elev_n,...
                    obj.Vw0_n,obj.Wpsi_n,1);
            end
            for i = 1:obj.elev_n
                disp(strcat("Elevation = ",num2str(obj.elev(i))))
                for j = 1:obj.Vw0_n
                    disp(strcat("Now Calculating：Vw0 = ",num2str(obj.Vw0(j)),"..."))
                    if strcmp(obj.parallel,'Yes')
                        parfor k = 1:obj.Wpsi_n
                            result(i,j,k,:) = obj.simulation(result(i,j,k,:),i,j,k);
                            if ismember("vs-time_Logs",obj.output)
                                obj.Record_Log(result(i,j,k,:))
                            end
                        end
                    else
                        for k = 1:obj.Wpsi_n
                            result(i,j,k,:) = obj.simulation(result(i,j,k,:),i,j,k);
                            if ismember("vs-time_Logs",obj.output)
                                obj.Record_Log(result(i,j,k,:))
                            end
                        end
                    end
                end
            end
        end
        
        function result = simulation(obj, result, num_elev, num_Vw, num_Wpsi)
        %シミュレーション実行関数
            for i = 1:obj.param_n
                result(i).elev = obj.elev(num_elev);
                result(i).Vw0 = obj.Vw0(num_Vw);
                result(i).Wpsi = obj.Wpsi(num_Wpsi);
                if i > 1        %初期条件設定
                    before = result(i-1);
                    if before.sep_st == 2
                        X0 = [before.xs(1:13,before.t_sep*before.freq); before.t_sep];
                    else
                        str_i = char(num2str(i));
                        switch str_i(1,size(str_i,2))
                                case '1'
                                    stage_str = strcat(str,'st');
                                case '2'
                                    stage_str = strcat(str,'nd');
                                case '3'
                                    stage_str = strcat(str,'rd');
                                otherwise
                                    stage_str = strcat(num2str(i),'th');
                        end
                        msg = strcat(str_i,stage_str," stage was not separated!");
                        warning(msg)
                    end
                else
                    X0 = zeros(14,1);
                end
                
                %計算実行
                result(i) = result(i).simulation(X0);
                
                %計算打切時刻までにロケットが着地しなかった場合の警告表示
                if result(i).t_landing == 0
                    switch i
                        case 1
                            num = '1st';
                        case 2
                            num = '2nd';
                        case 3
                            num = '3rd';
                        otherwise
                            num = strcat(num2str(i),'th');
                    end
                    warning(strcat(num,' Stage has NOT landed yet! (elev=',...
                        num2str(result(i).elev),',Vw0=',num2str(result(i).Vw0),',Wpsi=',...
                        num2str(result(i).Wpsi),')'))
                end
            end
        end
        
        function [dir_fn,dir_tmp] = make_outputfile(obj,file_type,elev,Vw0,fn)    %記録ファイル作成用関数
            %注　関数使用前後で作業フォルダは変わらない仕様
            old = cd;
            
            %フォーマットファイル指定
            switch file_type
                case 'log'      %ログ記録ファイル
                    format = 'Format_Log.xlsx';
                case 'featval'      %特徴値記録ファイル
                    format = 'Format_FeatVal.xlsx';
                case 'restriction'      %風向風速制限記録ファイル
                    format = 'Format_Restriction_list.xlsm';
            end
            
            %結果フォルダ生成
            if isfolder(obj.dir_res)==0
                cd(obj.dir_home);
                mkdir 'Result'
                obj.dir_res = strcat(obj.dir_home,'/Result');
            end
            cd(obj.dir_res)
            if strcmp(file_type,'restriction') == 0
                st_elev = strcat(num2str(elev),'deg');
                if isfolder(st_elev)==0
                    mkdir(st_elev)
                end
                cd(st_elev);
                if strcmp(file_type, 'log')
                    st_Vw0 = strcat(num2str(Vw0),'m');
                    if isfolder(st_Vw0)==0
                        mkdir(st_Vw0)
                    end
                    cd(st_Vw0);
                end
            end
            
            %記録ファイル生成
            dir_tmp = cd;
            form = strcat(obj.dir_form,'/',format);
            dir_fn = strcat(dir_tmp,'/',fn);
            copyfile(form,dir_fn,'f')
            
            cd(old)
        end
        
        function Record_Log(obj,result)  %ログ記録用関数
                                         %引数のresultは1*1*1*段数
            feat_str = obj.feat_list;
            feat_str(contains(feat_str,["Hard","Descent"])) = [];
            feat_str = [feat_str; "t_flight"; "FallPoint"];
            feat_log = obj.feat;
            feat_log(feat_log=="t_landing") = [];
            feat_log(feat_log=="xe") = [];
            feat_log = [feat_log; "t_landing"; "xe"];
            for i = 1:obj.param_n
                if i == 1
                    s = obj.elev_set/(abs(obj.elev_set));
                    elev_tmp = s * abs(result(i).elev);
                    Vw0_tmp = result(i).Vw0;
                    Wpsi_tmp = result(i).Wpsi;
                    land_tmp = result(i).mode_landing;
                    %ログファイル生成
                    switch obj.wind_model
                        case 'PowerLaw'
                            fn = strcat("Log_",num2str(elev_tmp),"deg_",...
                                num2str(Vw0_tmp),"m_",num2str(Wpsi_tmp),"deg_",...
                                land_tmp,".xlsx");
                        case 'MSM'
                            fn = strcat("Log_",elev_tmp,"deg_(MSM)",...
                                erase(obj.MSM_fn,'.nc'),"_",land_tmp,".xlsx");
                        case 'csv'
                            fn = strcat("Log_",elev_tmp,"deg_(csv)",...
                                erase(obj.wind_fn,'.csv'),"_",land_tmp,".xlsx");
                    end
                    [dir_fn,dir_tmp] = obj.make_outputfile('log',elev_tmp,Vw0_tmp,fn);
                end
                
                %ログ記録変数の値を抽出
                str = split(obj.log,'(');
                log_name = str(:,1);
                log_num = extractBefore(str(:,2),',');
                log_num = str2double(split(log_num,':'));
                for k = 1:size(obj.log_list,1)
                    res.(obj.log_list{k,:}) = result(i).(log_name{k,:})(log_num(k,1):log_num(k,2),:);
                    res.(obj.log_list{k,:}) = res.(obj.log_list{k,:})';
                    if log_name{k,:} == "xe";
                        xe = res.(obj.log_list{k,:});
                        res.(obj.log_list{k,:})(:,4) = (xe(:,1).^2 + xe(:,2).^2) .^ (1/2);
                    end
                end
                
                %Excelファイルにログを記録
                for j = 2:size(obj.log_list,1)
                    writematrix([res.t,res.(obj.log_list{j,1})],dir_fn,...
                        'Sheet',strcat('(Ns=',num2str(i),')',obj.log_list(j)),...
                        'Range','A2')
                end
                if strcmp(land_tmp,'Hard')
                    q_Ble = [1:size(res.q,1); res.q'];    %Blender用
                    Ble_name = strcat(dir_tmp,'/Blender_',...
                        num2str(elev_tmp),'deg_',num2str(Vw0_tmp),...
                        'm_',num2str(Wpsi_tmp),'deg_',num2str(i),'.csv');
                    writematrix(q_Ble, Ble_name)
                end
                if strcmp(obj.Ab_log,'Yes') && i == 1
                    log_Ab = res.Ab(1:obj.t_Ab_log*obj.freq+1,:);
                    t_Ab = res.t(1:obj.t_Ab_log*obj.freq+1,:);
                    writematrix([t_Ab,log_Ab],dir_fn,'Ab_lc','A2')
                end
                
                %特徴値を抽出
                if i == 1
                    table = zeros(size(feat_log,1),obj.param_n);
                end
                for k = 1:size(feat_log,1)
                    if strcmp(feat_str{k,:},"FallPoint")
                        table(k:k+1,i) = result(i).xe(1:2,:);
                    else
                        table(k,i) = result(i).(feat_log{k,:});
                    end
                end
            end
            %Excelファイルに特徴値を記録
            writematrix(1:obj.param_n, dir_fn,'Sheet','FeatVal','Range','B1')
            writematrix(["Ns";feat_str],dir_fn,'Sheet','FeatVal','Range','A1')
            writematrix(table,dir_fn,'Sheet','FeatVal','Range','B2')
        end
        
        function obj = Record_FeatVal(obj)          %特徴値記録用関数,結果はobj.feature.(各特徴値)に格納
                                                    %風向数×風速数(×x,y(落下分散のみ))×段数×射角数
            for i = 1:obj.elev_n
                
                
                %記録ファイル生成
                fn = strcat("FeatVal_(elev)",num2str(obj.elev(i)),".xlsx");
                dir_fn = obj.make_outputfile('featval',obj.elev(i),1,fn);
                
                %特徴値を抽出
                for l = 1:obj.param_n
                    for h = 1:size(obj.feat_list,1)
                        for k = 1:obj.Wpsi_n
                            for j = 1:obj.Vw0_n
                                result = obj.(obj.mode_landing{1,:});
                                if strcmp(obj.feat{h,:},"t_landing") || contains(obj.feat_list{h,:},"FP")
                                    result = obj.(extractAfter(obj.feat_list{h,:},"_"));
                                end
                                if strcmp(obj.feat{h,:},"Va_para") && (size(obj.mode_landing,1) > 1)
                                    result = obj.(obj.mode_landing{2,:});
                                end
                                if contains(obj.feat_list{h,:},"FP")
                                    obj.feature.(obj.feat_list{h,:})(k,j,1:2,l,i) =...
                                        result(i,j,k,l).(obj.feat{h,:})(1:2);
                                else
                                    obj.feature.(obj.feat_list{h,:})(k,j,l,i) =...
                                        result(i,j,k,l).(obj.feat{h,:});
                                end
                            end
                        end
                        
                        if strcmp(obj.mode_calc,"Multiple") && ismember("FeatureValues",obj.output)
                            if contains(obj.feat_list{h,:},"FP_")
                                fp = repelem(obj.feature.(obj.feat_list{h,:})(:,:,1,l,i),1,2);
                                for j = 1:obj.Vw0_n
                                    fp(:,2*j) = obj.feature.(obj.feat_list{h,:})(:,j,2,l,i);
                                end
                                table = [0,repelem(obj.Vw0,2),0;
                                    obj.Wpsi_res',fp,obj.Wpsi'];
                                ME_pos = excel_cell_calc([size(repelem(obj.Vw0,2),2)+2,3]);
                            else
                                tmp(:,:) = obj.feature.(obj.feat_list{h,:})(:,:,l,i);
                                table = [0, obj.Vw0,0;
                                    obj.Wpsi_res',tmp,obj.Wpsi'];
                                ME_pos = excel_cell_calc([size(obj.Vw0,2)+2,3]);
                            end

                            %Excelファイルに特徴値を記録
                            writematrix(table,dir_fn,...
                                'Sheet',obj.feat_list{h,:},...
                                'Range',strcat('A',num2str(3+(obj.Wpsi_n+2)*(l-1))))
                            writematrix(strcat("Ns=",num2str(l)),dir_fn,...
                                'Sheet',obj.feat_list{h,:},...
                                'Range',strcat('A',num2str(2+(obj.Wpsi_n+2)*(l-1))))
                            writematrix(obj.base_azm,dir_fn,...
                                'Sheet',obj.feat_list{h,:},...
                                'Range',strcat('A',num2str(3+(obj.Wpsi_n+2)*(l-1))))
                            writematrix('ME',dir_fn,...
                                'Sheet',obj.feat_list{h,:},...
                                'Range',ME_pos)
                        end
                    end
                end
                cd(obj.dir_scr)
            end
        end
            
        function obj = cond_judge(obj)  %風向風速制限判定関数
            fn = 'Restriction_List.xlsm';
            dir_fn = obj.make_outputfile('restriction',1,1,fn);
            tf_poly = ones(obj.Wpsi_n,obj.Vw0_n,obj.param_n,size(obj.mode_landing,1),obj.elev_n);
            tf_cir = ones(obj.Wpsi_n,obj.Vw0_n,obj.param_n,size(obj.mode_landing,1),obj.elev_n);
            for h = 1:obj.elev_n
                for i = 1:size(obj.mode_landing,1)
                    for j = 1:obj.param_n
                        fp = obj.feature.(strcat("FP_",obj.mode_landing{i,:}))(:,:,1:2,j,h);
                        tf_poly(:,:,j,i,h) = inpolygon(fp(:,:,1),fp(:,:,2),...
                            obj.limit_area.polygon.dist(:,1),obj.limit_area.polygon.dist(:,2));
                        for k = 1:size(obj.limit_area.circle.dist,1)
                            tf_cir(:,:,j,i,h) = tf_cir(:,:,j,i,h) &...
                                sqrt((fp(:,:,1)-obj.limit_area.circle.dist(k,1)).^2+...
                                (fp(:,:,2)-obj.limit_area.circle.dist(k,2)).^2) >...
                                obj.limit_area.circle.dist(k,3);
                        end
                    end
                end
            end
            obj.judge.poly = tf_poly;
            obj.judge.cir = tf_cir;
            %制限範囲統合
            obj.judge.tf = tf_poly & tf_cir;
            %多段式統合
            obj.judge.judge = obj.judge.tf(:,:,1,:,:);
            for i = 2:obj.param_n
                obj.judge.judge = obj.judge.judge & obj.judge.tf(:,:,i,:,:);
            end
            %降下モード統合
            if size(obj.mode_landing,1) == 2
                hard_judge = obj.judge.judge(:,:,:,1,:);
                dicent_judge = obj.judge.judge(:,:,:,2,:);
                obj.judge.judge(:,:,:,1,:) = obj.judge.judge(:,:,:,1,:)...
                    & obj.judge.judge(:,:,:,2,:);
                obj.judge.judge(:,:,:,2,:) = [];
            end
            obj.judge.judge = squeeze(obj.judge.judge);
            
            %Excelファイルに判定結果を記録
            table = nan(obj.Wpsi_n*obj.elev_n+1,obj.Vw0_n*2+3);
            table(1,3:obj.Vw0_n+2) = obj.Vw0;
            table(1,obj.Vw0_n+4:obj.Vw0_n*2+3) = obj.Vw0;
            for i = 1:obj.elev_n
                if ismember('Descent',obj.mode_landing)
                    table(obj.Wpsi_n*(i-1)+2:obj.Wpsi_n*i+1,3:obj.Vw0_n+2) =...
                        dicent_judge(:,:,i);
                end
                if ismember('Hard',obj.mode_landing)
                    table(obj.Wpsi_n*(i-1)+2:obj.Wpsi_n*i+1,obj.Vw0_n+4:obj.Vw0_n*2+3) =...
                        hard_judge(:,:,i);
                end
                table(obj.Wpsi_n*(i-1)+2,1) = obj.elev(i);
                table(obj.Wpsi_n*(i-1)+2:obj.Wpsi_n*i+1,2) = obj.Wpsi_res';
                table(obj.Wpsi_n*(i-1)+2:obj.Wpsi_n*i+1,obj.Vw0_n+3) = obj.Wpsi';
            end

            writematrix(table,dir_fn,'Sheet','Judge','Range','A2')
            writematrix('elev',dir_fn,'Sheet','Judge','Range','A2')
            writematrix(obj.base_azm,dir_fn,'Sheet','Judge','Range','B2')

            if sum(obj.judge.judge,'all') > 0
                obj = obj.feat_judge(dir_fn);
            else
                warning("Any conditions DON'T fulfill landing restriction!")
                disp("FeatureValues of conditions in restriction will NOT be output...")
            end
            
%             dir = cd;
%             ExcelApp = actxserver('Excel.Application');
%             ExcelApp.Visible = 1;
%             ExcelApp.Workbooks.Open(fullfile(pwd,list_fn));
%             ExcelApp.Run('make_table');
%             ExcelApp.DisplayAlerts = false;
%             ExcelApp.ActiveWorkbook.SaveAs(strcat(dir,'\',list_fn));
%             ExcelApp.DisplayAlerts = true;
%             ExcelApp.Quit;
%             ExcelApp.release;
%
%           cd(old)
        end
        
        function obj = feat_judge(obj,fn)  %風向風速制限下での特徴値の最大・最小値算出関数
            list = obj.feat_list;
            list(contains(list,'FP_')==1) = [];
            table = zeros(1,obj.param_n*4);
            param_tab = NaN(1,obj.param_n*4);
            for h = 1:obj.param_n
                param_tab(1,h*4-3) = h;
            end
            j = 1;          %書込用配列(table)の行カウンター(始点)
            for i = 1:size(list,1)
                min_tab = zeros(1,4*obj.param_n);
                max_tab = zeros(1,4*obj.param_n);
                for h = 1:obj.param_n
                    %制限内の特徴値配列を算出
                    tmp_tab = squeeze(obj.feature.(list{i,:})(:,:,h,:));
                    tmp_judge = tmp_tab(obj.judge.judge);

                    %最大・最小値に対応する計算条件を算出
                    siz = [size(tmp_tab,1),size(tmp_tab,2),size(tmp_tab,3)];
                    
                    %最小値
                    [r_min,c_min,h_min] = ind2sub(siz,find(tmp_tab==min(tmp_judge)));
                    min_Vw0 = obj.Vw0(c_min)';
                    min_Wpsi = obj.Wpsi_res(r_min)';
                    if obj.elev_n == 1
                        min_elev = obj.elev(h_min);
                    else
                        min_elev = obj.elev(h_min)';
                    end
                    min_tmp = [min(tmp_judge);NaN(size(r_min,1)-1,1)];
                    %最大値
                    [r_max,c_max,h_max] = ind2sub(siz,find(tmp_tab==max(tmp_judge)));
                    max_Vw0 = obj.Vw0(c_max)';
                    max_Wpsi = obj.Wpsi_res(r_max)';
                    if obj.elev_n == 1
                        max_elev = obj.elev(h_max);
                    else
                        max_elev = obj.elev(h_max)';
                    end
                    max_tmp = [max(tmp_judge);NaN(size(r_max,1)-1,1)];
                    
                    min_tmp(:,2:4) = [min_Vw0,min_Wpsi,min_elev];
                    max_tmp(:,2:4) = [max_Vw0,max_Wpsi,max_elev];
                    if h > 1
                        %最小値配列の結合
                        siz_cmp = size(min_tmp,1)-size(min_tab,1);
                        if siz_cmp > 0
                            min_tab(size(min_tab,1)+1:size(min_tab,1)+abs(siz_cmp),:)...
                                = NaN(abs(siz_cmp),4*(h-1));
                            obj.feat_min.(list{i,:})(:,:,1:h-1) = NaN(abs(siz_cmp),4,h-1);
                        elseif siz_cmp < 0
                            min_tmp(size(min_tmp,1)+1:size(min_tmp,1)+abs(siz_cmp),:)...
                                = NaN(abs(siz_cmp),4*(h-1));
                        end
                        min_tab(:,4*(h-1)+1:4*h) = min_tmp;
                        %最大値配列の結合
                        siz_cmp = size(max_tmp,1)-size(max_tab,1);
                        if siz_cmp > 0
                            max_tab(size(max_tab,1)+1:size(max_tab,1)+abs(siz_cmp),:)...
                                = NaN(abs(siz_cmp),4*(h-1));
                            obj.feat_max.(list{i,:})...
                                (size(obj.feat_max.(list{i,:}),1)+1:size(obj.feat_max.(list{i,:}),1)+siz_cmp,:,1:h-1)...
                                = NaN(abs(siz_cmp),4,h-1);
                        elseif siz_cmp < 0
                            max_tmp(size(max_tmp,1)+1:size(max_tmp,1)+abs(siz_cmp),:)...
                                = NaN(abs(siz_cmp),4*(h-1));
                        end
                        max_tab(:,4*(h-1)+1:4*h) = max_tmp;
                    else
                        min_tab = min_tmp;
                        max_tab = max_tmp;
                    end
                    obj.feat_min.(list{i,:})(:,:,h) = min_tmp;
                    obj.feat_max.(list{i,:})(:,:,h) = max_tmp;
                end
                %記録用配列を作成
                table(j:j+size(min_tab,1)+size(max_tab,1)-1,1:4*h) = [min_tab; max_tab];
                mm_str(j:j+size(min_tab,1)+size(max_tab,1)-1,:) =...
                    ["min"; NaN(size(min_tab,1)-1,1); "max"; NaN(size(max_tab,1)-1,1)];
                feat_str(j:j+size(min_tab,1)+size(max_tab,1)-1,:) =...
                    [list(i,:); NaN(size(min_tab,1)+size(max_tab,1)-1,1)];
                j = size(table,1) + 1;
            end
            %Excelファイルに保存
            ref_tab = ["min,max",repmat(["value","Vw0","Wpsi","elev"],1,obj.param_n)];
            writematrix(param_tab,fn,'Sheet','FeatVal','Range','C1')
            writematrix(["Ns";"ref";feat_str],fn,'Sheet','FeatVal','Range','A1')
            writematrix(ref_tab,fn,'Sheet','FeatVal','Range','B2')
            writematrix(mm_str,fn,'Sheet','FeatVal','Range','B3')
            writematrix(table,fn,'Sheet','FeatVal','Range','C3')
        end
    end
end