classdef PsyInt < handle
properties
    INTS
    nums

    s
    int
    trl

    cOpts
    name
    bLastInit
end
methods
    function obj=PsyInt(fname)
        %fname='/home/dambam/Documents/MATLAB/.px/prj/DSP2/_def/D_psy_DSP2.m';
        if nargin < 1 || isempty(fname)
            d=Dir.parent(mfilename('fullpath'));
            fname=[d 'def/D_int_default.cfg'];
        end
        if ~Fil.exist(fname)
            error('file does not exist')
        end
        opts=Cfg.read(fname);
        obj.parse(opts);
    end
    function n=getNSub(obj,int)
        opts=obj.INTS{obj.nums==int};
        n=numel(fieldnames(opts));
    end
    function [s,int,trl,opts,name]=inc(obj,bInit)
        if nargin < 2
            bInit=false;
        end
        bSame=false;
        if bInit
            obj.s=1;
            obj.int=1;
            obj.trl=1;
        elseif obj.s+1 <= obj.nums(obj.int)
            obj.s=obj.s+1;
        elseif obj.int+1 <= length(obj.INTS)
            obj.s=1;
            obj.int=obj.int+1;
        elseif obj.cOpts.autoInc
            obj.s=1;
            obj.int=1;
            obj.trl=obj.trl+1;
        else
            bSame=true;
        end
        s=obj.s;
        int=obj.int;
        trl=obj.trl;
        if bSame && ~obj.bLastInit
            opts=obj.cOpts;
        else
            opts=obj.getSubOpts(obj.int, obj.s, bInit);
        end
        obj.cOpts=opts;
        obj.bLastInit=bInit;
    end
    function opts=getSubOpts(obj,int,subIntORname,bInit)
        if nargin < 2 || isempty(int)
            int=obj.int;
        end
        if nargin < 3 || isempty(subIntORname)
            subIntORname=1;
        end
        if nargin < 4
            bInit=0;
        end

        opts=obj.INTS{obj.nums==int};
        flds=fieldnames(opts);

        if ischar(subIntORname)
            name=subIntORname;
            s=find(ismember(flds,name));
        else
            s=subIntORname;
            name=flds{s};
        end
        opts=opts.(name);
        opts.name=name;
        if bInit && ~isempty(opts.draw)
            opts.reset=[opts.reset; opts.draw(~ismember(opts.draw,opts.reset))];
        end
    end
end
methods(Access=private)
    function parse(obj,opts)
        flds=fieldnames(opts{'intOpts'});
        defInds=cellfun(@isempty,regexp(flds,'[0-9]+h?'));
        defFlds=flds(defInds);
        intFlds=flds(~defInds);

        intOpts=dict();
        for i = 1:length(intFlds)
            intOpts{intFlds{i}}=opts{'intOpts'}{intFlds{i}};
        end
        defOpts=dict(1);
        for i = 1:length(defFlds)
            defOpts{defFlds{i}}=opts{'intOpts'}{defFlds{i}};
        end

        P=obj.getP;
        def=Args.parse([],P,defOpts);
        for i = 1:size(P,1)
            P{i,2}=def.(P{i,1});
        end

        n=length(intFlds);
        obj.INTS=cell(length(intFlds),1);
        mtch=regexp(intFlds,'[0-9]*','match');
        obj.nums=cellfun(@str2double,vertcat(mtch{:}));
        obj.nums=str2double(intFlds);
        for i = 1:n
            IntI=intOpts{intFlds{i}};
            flds=fieldnames(IntI);
            INTS{i}=struct();
            for j = 1:length(flds)
                IntIJ=IntI{flds{j}};
                IntIJ=Args.parse([],P,IntIJ);
                obj.INTS{i}.(flds{j})=obj.parse_fun(IntIJ,P);
            end
        end

        %    if endsWith(intFlds{i},'h')
        %        h=h+1;
        %        IntH{h}=IntIJ;
        %    else
        %        n=n+1;
        %        INTS{n}=IntIJ;
        % end
        %end
        %obj.order=
        %obj.IntH=IntH;
        %obj.INTS=INTS;
        %obj.nInt=numel(obj.INTS);
        %obj.nIntA=obj.nInt+numel(obj.nIntH);
    end
    function out=parse_fun(obj,int,P)
        out=int;
        flds=fieldnames(int);
        for i = 1:length(flds)
            val=int.(flds{i});
            ex=P{i,2};

            if ischar(val) && startsWith(val,'+')
                if ~iscell(ex)
                    out.(flds{i})={ex; val(2:end)};
                else
                    out.(flds{i})=[ex; val(2:end)];
                end
            elseif iscell(val) && startsWith(val{1},'+')
                out.(flds{i})=[ex; val(2:end)];
            end

        end
    end

end
methods(Static)
    function P=getP()
        P={...
            't',0,'Num.isInt';                          % view
            'modt',0,'Num.isInt';                       % view
            ...
            'key','limited','ischar'; ...               % key
            'mode',[],'ischar_e'; ...                    % key
            ...
            'reset','','@(x) iscell(x) || ischar(x)';   % draw
            'draw','', '@(x) iscell(x) || ischar(x)';   % draw
            'close','','@(x) true';                     % draw
            ...
            'hook','','ischar'; ...       % *
            'loadt',0,'Num.isInt';                       % view
            ...
            'time',0,'@(x) true'; ...                   % view
            'autoInc',1,'isbinary'; ...
            'keyHold',0,'isbinary'; ...
            ...
            %'close','','@(x) iscell(x) || ischar(x)';
        };
    end
end
end
