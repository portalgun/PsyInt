classdef PsyInt < handle
properties
    Int
    nums
    pos
end
methods
    function obj=PsyInt(fname)
        %fname='/home/dambam/Documents/MATLAB/.px/prj/DSP2/_def/D_psy_DSP2.m';
        if nargin < 1 || isempty(fname)
            d=Dir.parent(mfilename('fullpath'));
            fname=[d 'D_int_default.cfg'];
        end
        if ~Fil.exist(fname)
            error('file does not exist')
        end
        opts=Cfg.read(fname);
        obj.parse(opts);
    end
    function n=getNSub(obj,int)
        opts=obj.Int{obj.nums==int};
        n=numel(fieldnames(opts));
    end
    function [opts,name]=getSubOpts(obj,int,subIntORname)
        if isempty(int);
            int=1;
        end
        if isempty(subIntORname)
            subIntORname=1;
        end
        opts=obj.Int{obj.nums==int};
        if ischar(subIntORname)
            name=subIntORname;
        else
            flds=fieldnames(opts);
            name=flds{subIntORname};
        end
        opts=opts.(name);
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
        obj.Int=cell(length(intFlds),1);
        mtch=regexp(intFlds,'[0-9]*','match');
        obj.nums=cellfun(@str2double,vertcat(mtch{:}));
        obj.nums=str2double(intFlds);
        for i = 1:n
            IntI=intOpts{intFlds{i}};
            flds=fieldnames(IntI);
            Int{i}=struct();
            for j = 1:length(flds)
                IntIJ=IntI{flds{j}};
                IntIJ=Args.parse([],P,IntIJ);
                obj.Int{i}.(flds{j})=obj.parse_fun(IntIJ,P);
            end
        end

        %    if endsWith(intFlds{i},'h')
        %        h=h+1;
        %        IntH{h}=IntIJ;
        %    else
        %        n=n+1;
        %        Int{n}=IntIJ;
        % end
        %end
        %obj.order=
        %obj.IntH=IntH;
        %obj.Int=Int;
        %obj.nInt=numel(obj.Int);
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
            ...
            %'close','','@(x) iscell(x) || ischar(x)';
        };
    end
end
end
