function bundle = FallPoint(outputMatPath, initCfg)
    % FallPoint.m
    % 落下分散図の設定（軸/凡例/マーカー/背景範囲/表示基準/LimitArea）を
    % 対話で編集し、設定＋背景画像を 1 つの MAT ファイルへ保存します。
    % ※ 磁気偏角 (mgd) は GeneralSettingUI 側で管理する設計のため、本ツールでは扱いません。
    %
    % USAGE:
    %   bundle = FallPoint();                            % 対話 → ダイアログで保存
    %   bundle = FallPoint('FallPointBundle.mat');       % 対話 → 指定パスへ保存
    %   bundle = FallPoint('FallPointBundle.mat', cfg0); % 既存 cfg0 を初期値に
    %
    % 返り値: bundle = struct('cfg','img','raw','name','saved_at')
    %
    % 依存: lon_lat クラス（Vincenty 法を実装）  ※パスに置いてください。

    %% 既定 cfg の用意
    cfg = defaultCfg();                             % ax/lgd/back_pos/marker/view_azm/limit_area
    if nargin >= 2 && ~isempty(initCfg), cfg = mergeCfg(cfg, initCfg); end
    % 旧バージョンの cfg に含まれる mgd は無視する
    if isfield(cfg,'mgd'), cfg = rmfield(cfg,'mgd'); end

    %% 背景画像の選択（任意）
    [fn, fp] = uigetfile({'*.jpg;*.png;*.tif','Image files';'*.*','All files'}, ...
                          '落下分散図の背景画像を選択（任意、キャンセル可）');
    img  = []; raw = []; name = '';
    if ((ischar(fn) || isstring(fn)) && ~isequal(fn,0))
        try
            name = char(fn);
            img  = imread(fullfile(fp, fn));
            % point_preview と整合のため上下反転（不要ならコメントアウト）
            img  = flipud(img);
            % 原本バイト列（EXIF 等も含め完全復元したい場合）
            fid = fopen(fullfile(fp, fn), 'rb'); raw = fread(fid, Inf, '*uint8'); fclose(fid);
        catch ME
            warning('FallPoint:LoadImageFailed', '背景画像の読み込みに失敗: %s', ME.message);
            img  = []; raw = []; name = '';
        end
    end

    %% プレビュー Figure
    [fig, axh, lgdh] = previewFigure(cfg, img);
    cleanupFig = onCleanup(@() safeClose(fig));
    drawLimitArea(axh, cfg.limit_area);  % 既に cfg に入っていれば最初から描く

    %% 対話メニュー
    menuList = [ ...
        "背景貼付け範囲", ...
        "軸設定", ...
        "凡例", ...
        "マーカー", ...
        "表示基準", ...
        "LimitArea 回転角", ...
        "LimitArea 読込（.xlsx）", ...
        "保存して終了", ...
        "キャンセル" ...
    ];
    keep = true;

    while keep
        [sel, tf] = listdlg( ...
            'ListString', menuList, ...
            'PromptString', '変更項目を選択:', ...
            'SelectionMode', 'single' ...
        );
        if ~tf
            sel = find(menuList == "キャンセル", 1);
            tf  = true;
        end
        choice = string(menuList(sel));

        switch choice
            case "背景貼付け範囲"
                v   = cfg.back_pos; def = reshape(v', [1,4]);
                answ = inputdlg({"x_min","x_max","y_min","y_max"}, ...
                                '背景画像の貼付け範囲（軸座標）', [1 40], ...
                                cellstr(string(def)));
                if ~isempty(answ)
                    val = str2double(string(answ));
                    if numel(val)==4 && all(isfinite(val)) && val(1)<val(2) && val(3)<val(4)
                        cfg.back_pos = reshape(val, [2,2])';
                        redraw(axh, lgdh, cfg, img);
                        drawLimitArea(axh, cfg.limit_area);
                    else
                        warndlg('x_min<x_max, y_min<y_max を満たす数値4要素を入力してください。','入力エラー');
                    end
                end

            case "軸設定"
                cfg = editAxis(cfg);
                redraw(axh, lgdh, cfg, img);
                drawLimitArea(axh, cfg.limit_area);

            case "凡例"
                cfg = editLegend(cfg);
                redraw(axh, lgdh, cfg, img);
                drawLimitArea(axh, cfg.limit_area);

            case "マーカー"
                cfg = editMarker(cfg);
                redraw(axh, lgdh, cfg, img);
                drawLimitArea(axh, cfg.limit_area);

            case "表示基準"
                answ1 = questdlg('出力図の基準方位?（背景画像の向き）', 'view_azm', ...
                                 'Magnetic','True', cfg.view_azm);
                if ~isempty(answ1), cfg.view_azm = string(answ1); end

                % view_azm が変わったので LimitArea の表示用座標を再計算
                if hasAnyLimitArea(cfg.limit_area)
                    cfg.limit_area = recomputeLimitAreaView(cfg.limit_area, cfg.view_azm, cfg.rot_deg);
                end
                redraw(axh, lgdh, cfg, img);
                drawLimitArea(axh, cfg.limit_area);

            case "LimitArea 回転角"
                % LimitArea を背景画像（Magnetic）に重ねるための回転角 [deg]（西偏=正、mgd と同義）
                % FallPoint プレビュー専用。GeneralSetting2 / DisplayFigure 側からは参照されない。
                answ = inputdlg('LimitArea 回転角 rot_deg [deg]（西偏=正、view_azm=Magnetic 時のみ適用）', ...
                                'rot_deg', [1 60], cellstr(string(cfg.rot_deg)));
                if ~isempty(answ)
                    v = str2double(string(answ{1}));
                    if isfinite(v)
                        cfg.rot_deg = v;
                        if hasAnyLimitArea(cfg.limit_area)
                            cfg.limit_area = recomputeLimitAreaView(cfg.limit_area, cfg.view_azm, cfg.rot_deg);
                        end
                        redraw(axh, lgdh, cfg, img);
                        drawLimitArea(axh, cfg.limit_area);
                    else
                        warndlg('数値を入力してください。');
                    end
                end

            case "LimitArea 読込（.xlsx）"
                [lfn, lfp] = uigetfile({'*.xlsx','Limited Area Excel';'*.*','All files'}, ...
                                       'LimitArea ファイルを選択（.xlsx）');
                if isequal(lfn,0), continue; end
                try
                    la = loadLimitAreaXlsx(fullfile(lfp, lfn));                                  % Info/B3:D3, CenterPoint, Polygon を読む
                    la = computeLimitAreaDistWithLonLat(la, cfg.view_azm, cfg.rot_deg);          % Vincenty で距離化＋表示用回転
                    cfg.limit_area = la;
                    redraw(axh, lgdh, cfg, img);                                % 背景・軸・凡例
                    drawLimitArea(axh, cfg.limit_area);                          % 制限区域オーバーレイ
                catch ME
                    warning('FallPoint:LoadLimitAreaFailed','LimitArea 読込失敗: %s', ME.message);
                    warndlg(sprintf('LimitArea 読込失敗:\n%s', ME.message),'読み込み失敗');
                end

            case "保存して終了"
                if nargin < 1 || isempty(outputMatPath)
                    [mfn, mfp] = uiputfile({'*.mat','MAT-file'}, ...
                                            '保存ファイル名を指定', 'FallPointBundle.mat');
                    if isequal(mfn,0), continue; end
                    outputMatPath = fullfile(mfp, mfn);
                end
                [dirn,~,~] = fileparts(outputMatPath);
                if ~isempty(dirn) && ~isfolder(dirn), mkdir(dirn); end

                bundle = struct('cfg',cfg,'img',img,'raw',raw,'name',name,'saved_at',datetime);
                try
                    save(outputMatPath,'-struct','bundle','-v7.3');
                    fprintf('FallPoint bundle を保存しました: %s\n', outputMatPath);
                catch ME
                    warning('FallPoint:SaveFailed','保存に失敗: %s', ME.message);
                end
                keep = false;

            case "キャンセル"
                bundle = struct('cfg',cfg,'img',img,'raw',raw,'name',name,'saved_at',[]);
                fprintf('キャンセルで終了しました（メモリ上には cfg 等が残っています）。\n');
                keep = false;
        end
    end
end

% ======================= ここからローカル関数 =======================

function cfg = defaultCfg()
    % GeneralSetting の落下分散図既定を踏襲（ax/legend/back_pict 等）
    cfg = struct();
    % 軸（ax.point）
    cfg.ax = struct();
    cfg.ax.range    = [-840, 880, -910, 750];
    cfg.ax.label    = ["Magnetic East[m]","Magnetic North[m]"];
    cfg.ax.FontSize = 10;
    % 凡例（lgd.point）
    cfg.lgd = struct();
    cfg.lgd.pos      = [0.8, 0.8, 0.1, 0.1];
    cfg.lgd.FontSize = 10;
    % 背景貼付け（back_pict.pos）
    cfg.back_pos     = [-830, 870; -907, 750];
    % マーカー
    cfg.marker = struct('mode','shape','size',50,'shape','o','mfc','flat','color',[1 0 0]);
    % 表示基準（背景画像の向き）
    cfg.view_azm = "Magnetic";
    % LimitArea 表示用回転角 [deg]（西偏=正、view_azm=Magnetic のときのみ適用、FallPoint 内専用）
    cfg.rot_deg  = 0;
    % LimitArea 空
    cfg.limit_area = emptyLimitArea();
    cfg.version  = 3;
end

function la = emptyLimitArea()
    la = struct( ...
        'fn',"", 'path', "", ...
        'coord',"geo", ...            % 'geo' or 'dist'
        'type', "TN", ...             % InfoのType（例: TN）
        'rot',  "CW",  ...            % InfoのRotate
        'origin', [NaN,NaN], ...
        'circle',  struct('geo',[],      'dist_true',[], 'dist_view',[]), ...
        'polygon', struct('geo',[],      'dist_true',[], 'dist_view',[]) ...
    );
end

function tf = hasAnyLimitArea(la)
    if ~isstruct(la), tf = false; return; end
    tf = false;
    if isfield(la,'circle')
        if (isfield(la.circle,'geo') && ~isempty(la.circle.geo)), tf = true; return; end
        if (isfield(la.circle,'dist') && ~isempty(la.circle.dist)), tf = true; return; end
        if (isfield(la.circle,'dist_true') && ~isempty(la.circle.dist_true)), tf = true; return; end
    end
    if isfield(la,'polygon')
        if (isfield(la.polygon,'geo') && ~isempty(la.polygon.geo)), tf = true; return; end
        if (isfield(la.polygon,'dist') && ~isempty(la.polygon.dist)), tf = true; return; end
        if (isfield(la.polygon,'dist_true') && ~isempty(la.polygon.dist_true)), tf = true; return; end
    end
end

function out = mergeCfg(base, x)
    out = base;
    if isempty(x), return; end
    fn = fieldnames(x);
    for i = 1:numel(fn)
        k = fn{i};
        if isstruct(x.(k)) && isfield(base,k) && isstruct(base.(k))
            out.(k) = mergeCfg(base.(k), x.(k));
        else
            out.(k) = x.(k);
        end
    end
end

function [fig, axh, lgdh] = previewFigure(cfg, img)
    fig = figure('Name','Preview of FallPoint Figure', 'Position',[100 50 800 700]);
    axh = axes('Parent',fig);
    axis(axh, cfg.ax.range); hold(axh,'on');
    if ~isempty(img)
        image(cfg.back_pos(1,:), cfg.back_pos(2,:), img, 'Parent', axh); % 軸座標で貼付け
    end
    xlabel(axh, cfg.ax.label(1)); ylabel(axh, cfg.ax.label(2));
    axh.FontSize = cfg.ax.FontSize;
    plot(axh, NaN,NaN,'o','DisplayName','Sample');  % ダミー
    lgdh = legend(axh,'boxoff'); lgdh.Position = cfg.lgd.pos; lgdh.FontSize = cfg.lgd.FontSize;
    grid(axh,'on');
end

function redraw(axh, lgdh, cfg, img)
    cla(axh); axis(axh, cfg.ax.range); hold(axh,'on');
    if ~isempty(img)
        image(cfg.back_pos(1,:), cfg.back_pos(2,:), img, 'Parent', axh);
    end
    xlabel(axh, cfg.ax.label(1)); ylabel(axh, cfg.ax.label(2));
    axh.FontSize = cfg.ax.FontSize;
    if ~isempty(lgdh) && isvalid(lgdh)
        lgdh.Position = cfg.lgd.pos; lgdh.FontSize = cfg.lgd.FontSize;
    end
    grid(axh,'on'); drawnow;
end

function cfg = editAxis(cfg)
    answ = inputdlg({"x_min","x_max","y_min","y_max"}, 'Axis Range', [1 40], cellstr(string(cfg.ax.range)));
    if ~isempty(answ)
        v = str2double(string(answ));
        if numel(v)==4 && all(isfinite(v)) && v(1)<v(2) && v(3)<v(4)
            cfg.ax.range = v(:).';
        else
            warndlg('x_min<x_max, y_min<y_max を満たす数値4要素を入力してください。','入力エラー');
        end
    end
    answ = inputdlg({"x-axis label","y-axis label"}, 'Axis Label', [1 40], cellstr(cfg.ax.label));
    if ~isempty(answ)
        lbl = string(answ(:)).';
        if numel(lbl)==2 && all(strlength(lbl)>0), cfg.ax.label = lbl;
        else, warndlg('x/y の2ラベルを入力してください。','入力エラー'); end
    end
    answ = inputdlg({"FontSize"}, 'Axis FontSize', [1 40], cellstr(string(cfg.ax.FontSize)));
    if ~isempty(answ)
        v = str2double(string(answ));
        if isfinite(v) && v>0, cfg.ax.FontSize = v; else, warndlg('正の数を入力してください。'); end
    end
end

function cfg = editLegend(cfg)
    answ = inputdlg({"left","bottom","width","height"}, 'Legend Pos (0..1)', [1 40], cellstr(string(cfg.lgd.pos)));
    if ~isempty(answ)
        v = str2double(string(answ));
        if numel(v)==4 && all(isfinite(v)) && all(v>=0 & v<=1), cfg.lgd.pos = v(:).';
        else, warndlg('0..1 の範囲の数値4要素を入力してください。','入力エラー'); end
    end
    answ = inputdlg({"FontSize"}, 'Legend FontSize', [1 40], cellstr(string(cfg.lgd.FontSize)));
    if ~isempty(answ)
        v = str2double(string(answ));
        if isfinite(v) && v>0, cfg.lgd.FontSize = v; else, warndlg('正の数を入力してください。'); end
    end
end

function cfg = editMarker(cfg)
    answ = inputdlg({"Size"}, 'Marker Size', [1 40], cellstr(string(cfg.marker.size)));
    if ~isempty(answ)
        v = str2double(string(answ));
        if isfinite(v) && v>0, cfg.marker.size = v; else, warndlg('正の数を入力してください。'); end
    end
end

% ---------- LimitArea の描画（距離系 dist を想定） ----------
function drawLimitArea(axh, la)
    if ~isstruct(la), return; end
    hold(axh,'on');

    % 円： [x y r]（view）
    if isfield(la,'circle') && isfield(la.circle,'dist_view') && ~isempty(la.circle.dist_view)
        C = la.circle.dist_view;
        plot(axh, C(:,1), C(:,2), 'r.', 'DisplayName','Limited Circle Center');
        for i=1:size(C,1)
            xc=C(i,1); yc=C(i,2); r=C(i,3);
            t = linspace(0,2*pi,256);
            if i==1
                dn = 'Limited Circle';
            else
                dn = '';
            end
            plot(axh, xc + r*cos(t), yc + r*sin(t), 'r-', 'LineWidth',1.5, ...
                 'DisplayName', dn);
        end
    end

    % 多角形： [x y]（view）
    if isfield(la,'polygon') && isfield(la.polygon,'dist_view') && ~isempty(la.polygon.dist_view)
        P = la.polygon.dist_view;
        P = [P; P(1,:)]; % 閉じる
        plot(axh, P(:,1), P(:,2), '-o', 'Color',[1 0.8 0], ...
             'MarkerFaceColor',[1 0.8 0], 'DisplayName','Limited Polygon');
    end
end

% ---------- LimitArea Excel 読取（Spica_v2.1 GeneralSetting.m 準拠） ----------
function la = loadLimitAreaXlsx(xlsx)
    % Spica_v2.1 の GeneralSetting.set_option と同一方式で読み取り
    % Info!B3:D3 → coord/type/rot, CenterPoint → circle, Polygon → polygon
    la = emptyLimitArea();
    la.fn   = string(getFileName(xlsx));
    la.path = string(xlsx);
    try
        % Info: B3:D3 から coord/type/rot を読み取り
        coord_tab = readmatrix(xlsx, 'Sheet','Info', ...
            'Range','B3:D3', 'OutputType','string');
        la.coord = lower(string(strtrim(coord_tab(1,1))));  % "geo" or "dist"
        la.type  = string(strtrim(coord_tab(1,2)));
        la.rot   = string(strtrim(coord_tab(1,3)));

        % CenterPoint（Spica_v2.1 方式 + 空列/空行除去）
        C = readmatrix(xlsx, 'Sheet','CenterPoint');
        C = stripNanRowsCols(C);
        la.circle.(la.coord) = C;
        la.origin = C(1,:);

        % Polygon（Spica_v2.1 方式 + 空列/空行除去）
        P = readmatrix(xlsx, 'Sheet','Polygon');
        P = stripNanRowsCols(P);
        la.polygon.(la.coord) = P;
    catch ME
        error('LimitAreaXlsx:ReadFailed','読み取り失敗: %s', ME.message);
    end
end

function M = stripNanRowsCols(M)
    % readmatrix が空列(A列等)を NaN で含む場合に除去する
    if ~isempty(M)
        M = M(:, ~all(isnan(M), 1));   % 全行NaN の列を除去
        M = M(~all(isnan(M), 2), :);   % 全列NaN の行を除去
    end
end

% ---------- lon_lat（Vincenty）で距離化＋表示用回転 ----------
function la = computeLimitAreaDistWithLonLat(la, view_azm, rot_deg)
    % lon_lat（Vincenty）で geo→距離化して dist_true を作成し、
    % 表示基準(view_azm) と回転角(rot_deg) に応じて dist_view を生成する。
    % rot_deg は FallPoint プレビュー専用（GeneralSetting2 / DisplayFigure では参照しない）。
    if ~exist('lon_lat','class')
        % FallPoint.m はルートから実行されるため Scripts/ を自動追加
        scriptDir = fullfile(fileparts(mfilename('fullpath')), 'Scripts');
        if isfolder(scriptDir)
            addpath(scriptDir);
        end
        if ~exist('lon_lat','class')
            error('lon_lat class が見つかりません（パスに追加してください）');
        end
    end

    % 1) dist_true の確定
    if la.coord=="geo"
        if any(isnan(la.origin))
            error('geo ですが origin が欠落しています（CenterPoint か Polygon に 1行以上必要）');
        end
        ll = lon_lat(la.origin);                          % 添付クラスを使用  [2](https://tmdacjp-my.sharepoint.com/personal/matsumoto_t_4b59_m_isct_ac_jp/_layouts/15/Doc.aspx?sourcedoc=%7BAC5F1360-13F2-4380-A2E3-C86B69B7E41B%7D&file=2024_3_kada.xlsx&action=default&mobileredirect=true)

        if ~isempty(la.circle.geo)
            N = size(la.circle.geo,1);
            XY = zeros(N,2);
            for i=1:N
                XY(i,1:2) = ll.Vincenty_position(la.circle.geo(i,1:2)); % [x y]  [2](https://tmdacjp-my.sharepoint.com/personal/matsumoto_t_4b59_m_isct_ac_jp/_layouts/15/Doc.aspx?sourcedoc=%7BAC5F1360-13F2-4380-A2E3-C86B69B7E41B%7D&file=2024_3_kada.xlsx&action=default&mobileredirect=true)
            end
            la.circle.dist_true = [XY, la.circle.geo(:,3)];  % r はそのまま
        else
            la.circle.dist_true = [];
        end

        if ~isempty(la.polygon.geo)
            N = size(la.polygon.geo,1);
            XY = zeros(N,2);
            for i=1:N
                XY(i,1:2) = ll.Vincenty_position(la.polygon.geo(i,1:2)); % [x y]  [2](https://tmdacjp-my.sharepoint.com/personal/matsumoto_t_4b59_m_isct_ac_jp/_layouts/15/Doc.aspx?sourcedoc=%7BAC5F1360-13F2-4380-A2E3-C86B69B7E41B%7D&file=2024_3_kada.xlsx&action=default&mobileredirect=true)
            end
            la.polygon.dist_true = XY;
        else
            la.polygon.dist_true = [];
        end

    else % coord == "dist"
        % 取り込み値を基準座標として“そのまま” dist_true に採用
        % （Info.Type が Magnetic系なら True に直す、等の運用拡張は必要に応じて）
        if isfield(la,'circle') && isfield(la.circle,'dist') && ~isempty(la.circle.dist)
            la.circle.dist_true = la.circle.dist;
        else
            la.circle.dist_true = [];
        end
        if isfield(la,'polygon') && isfield(la.polygon,'dist') && ~isempty(la.polygon.dist)
            la.polygon.dist_true = la.polygon.dist;
        else
            la.polygon.dist_true = [];
        end
    end

    % 2) dist_view の生成（view_azm, rot_deg に応じて dist_true から回転）
    [la.circle.dist_view, la.polygon.dist_view] = localMakeView( ...
        la.circle.dist_true, la.polygon.dist_true, view_azm, rot_deg);
end

function [Cview, Pview] = localMakeView(Ctrue, Ptrue, view_azm, rot_deg)
    % True 基準 → 表示基準 (Magnetic/True) へ回転。
    % Magnetic のときのみ rot_deg [deg]（西偏=正）で回転、True は恒等。
    if strcmpi(string(view_azm),'magnetic')
        th = -rot_deg * pi/180;
    else
        th = 0;
    end
    R = [cos(th) sin(th); -sin(th) cos(th)];

    % circle: [x y r]（r は半径なのでそのまま）
    if ~isempty(Ctrue)
        XY = (R * Ctrue(:,1:2).').';
        Cview = [XY, Ctrue(:,3)];
    else
        Cview = [];
    end
    % polygon: [x y]
    if ~isempty(Ptrue)
        Pview = (R * Ptrue(:,1:2).').';
    else
        Pview = [];
    end
end

% ---------- view_azm / rot_deg 変更時の再計算 ----------
function la = recomputeLimitAreaView(la, view_azm, rot_deg)
    % 既存の dist_view を回し直すのではなく、必ず dist_true から再生成する
    if ~isstruct(la), return; end
    [la.circle.dist_view, la.polygon.dist_view] = localMakeView( ...
        la.circle.dist_true, la.polygon.dist_true, view_azm, rot_deg);
end

% ---------- ユーティリティ ----------
function s = getFileName(p)
    [~,s,ext] = fileparts(p); s = [s,ext];
end

function safeClose(h)
    if ~isempty(h) && ishghandle(h)
        try close(h); catch, end
    end
end
