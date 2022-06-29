classdef PsyInt < handle
properties
    INTS
    IntNames
    nSInts
    bGoTo=false

    s
    int
    trl
    sName
    lastInc

    bNewS
    bPause
    bCmd
    bInit
    bLastInit
    bNext
    bForce

    sStartT=0
    elapsedT
    bTimeout
    remainT

    rOpts
    cOpts
    lastText
    lastTime

    defaults
end
methods
    function obj=PsyInt(fname,drawAppend)
        %fname='/home/dambam/Documents/MATLAB/.px/prj/DSP2/_def/D_psy_DSP2.m';
        if nargin < 1 || isempty(fname)
            d=Dir.parent(mfilename('fullpath'));
            fname=[d 'def/D_int_default.cfg'];
        end
        if ~ismember(filesep,fname)
            if ~startsWith(fname,'D_int_')
                fname=['D_int_' fname];
            end
            if ~endsWith(fname,'.cfg')
                fname=[fname '.cfg'];
            end
        end
        if ~Fil.exist(fname)
            error(['file does not exist: ' fname])
        end
        opts=Cfg.read(fname);
        %opts{'intOpts'}{'0'}{'countdown'}{'text'}
        obj.parse(opts);
        if nargin >=2 && ~isempty(drawAppend)
            obj.append_draw(drawAppend);
        end
    end
%% MAIN
    function [bNeedsUpdate,s,int,trl,opts]=getInt(obj,bInit,bPause,bCmd,lastDrawOnsetTime,bNext)
        if nargin < 4 || isempty(bCmd)
            bCmd=true;
        end
        if nargin < 6 || isempty(bNext)
            bNext=false;
        end
        if ~bInit && nargin >= 5 && ~isempty(lastDrawOnsetTime)
            obj.postDraw(lastDrawOnsetTime);
        end
        obj.bInit=bInit;
        obj.bPause=bPause;
        obj.bCmd=bCmd;
        obj.bNext=bNext;

        obj.bForce=false;
        bNeedsUpdate=obj.main(false);
        [trl,int,s]=obj.get_ints();
        opts=obj.cOpts;
    end
    function [bNeedsUpdate,s,opts]=forceInt(obj,trl,int,bInit,bPause,bCmd,lastDrawOnsetTime)
        if nargin < 3 || isempty(int)
            int=1;
        end

        if ~bInit && nargin >= 7 && ~isempty(lastDrawOnsetTime)
            obj.postDraw(lastDrawOnsetTime);
        end

        if ~bInit || isequal(obj.trl,trl) || ~isequal(obj.int,int)
            obj.s=1;
            bNew=true;
        else
            bNew=false;
        end
        obj.trl=trl;
        obj.int=int;

        obj.bInit=bInit;
        obj.bPause=bPause;
        obj.bCmd=bCmd;
        obj.bNext=false;

        obj.bForce=true;
        bNeedsUpdate=obj.main(bNew);
        [~,~,s]=obj.get_ints();
        opts=obj.cOpts;
    end
    function bNeedsUpdate=main(obj,bNew)
        % TIME
        if obj.bInit
            obj.reset_time();
        end
        obj.check_update();
        obj.bNewS=obj.bNewS || bNew || obj.bGoTo;

        % INC
        if obj.bNewS && ~obj.bForce && ~obj.bGoTo
            obj.auto_inc();
        end
        obj.get_sName();
        obj.bGoTo=false;

        % OPTSreplace
        obj.get_raw_sub_opts();

        % UPDATE-SELF
        if obj.bNewS
            obj.sStartT=0;
            obj.elapsedT=0;
            obj.remainT=obj.rOpts.time;
        end

        % PARSE
        obj.parse_sub_opts();
        obj.bLastInit=obj.bInit;

        % OUTPUT
        bNeedsUpdate=~isempty(obj.cOpts.reset) || ~isempty(obj.cOpts.close);

        if ~obj.gdCond();
            %display([num2str(obj.trl) ' ' num2str(obj.int) ' ' num2str(obj.s)]);
            [bNewS]=obj.main(true);
        end
    end
    function get_sName(obj)
        opts=obj.INTS{obj.int};
        flds=fieldnames(opts);
        obj.sName=flds{obj.s};
    end
    function [trl,int,s,intInd,sName]=get_ints(obj)
        s=obj.s;
        int=obj.IntNames(obj.int);
        trl=obj.trl;
        intInd=obj.int;
        sName=obj.sName;

    end
    function go(obj,t,int,s)
        if iscell(t)
            s=t{3};
            int=t{2};
            t=t{1};
        end
        % empty = first, 0 = same
        if nargin >= 2 && ~isempty(t)
            obj.trl=obj.trl+t;
            if obj.trl < 1
                obj.trl=1;
            end
        end
        if nargin >= 3  && ~isempty(int)
            obj.int=obj.int+int;
            if obj.int < 1
                obj.int=1;
            end
        elseif isempty(int)
            obj.int=1;
        end
        if nargin >= 4 && ~isempty(s) & s > 0
            obj.s=obj.s+s;
            if obj.s < 1
                obj.s=1;
            end
        elseif isempty(s)
            obj.s=1;
        end

        obj.bGoTo=true;
    end
    function goto(obj,t,int,s)
        if iscell(t)
            s=t{3};
            int=t{2};
            t=t{1};
        end
        % empty = same
        if nargin < 2 || isempty(t)
            t=obj.trl;
            if nargin < 3 || isempty(int)
                int=1;
            end
            if nargin < 4 || isempty(s)
                s=1;
            end
        elseif nargin < 3 || isempty(int) || int == 0
            int=obj.int;
            if nargin < 4 || isempty(s)
                s=1;
            end
        elseif nargin < 4 || s==0
            obj.s=1;
        end
        obj.trl=t;
        obj.int=int;
        obj.s=s;
        obj.bGoTo=true;

    end
    function next_trial(obj)
        obj.s=1;
        obj.int=1;
        obj.trl=obj.trl+1;
    end
%% TIME
    function resetTime(obj)
        obj.sStartT=0;
    end
    function continueTime(obj)
        obj.sStartT=GetSecs-obj.elapsedT;
    end
    function continue_int(obj)
        %obj.lastInc=[obj.s obj.int obj.trl];
        obj.s=obj.lastInc(1);
        obj.int=obj.lastInc(2);
        obj.trl=obj.lastInc(3);
        obj.resetTime();
    end
    function postDraw(obj,drawOnsetTime)
        if obj.sStartT==0
            obj.sStartT=drawOnsetTime;
            obj.elapsedT=0;
            obj.remainT=obj.cOpts.time;
            obj.bTimeout=obj.cOpts.time <= obj.elapsedT;
        else
            obj.elapsedT=GetSecs-obj.sStartT;
            obj.remainT=(obj.cOpts.time-obj.elapsedT);
            obj.bTimeout=obj.cOpts.time <= obj.elapsedT;
            if obj.bTimeout
                obj.lastTime=obj.cOpts.time;
                obj.reset_time();
            end
        end
    end
%% MODIFY
    function replaceAll(obj,fld,val)
        def=obj.defaults{ismember(obj.defaults(:,1),fld),2};
        % REPLACE DEFAULT
        % USED FOR EASY NEAR DUPLICATION
        for i = 1:length(INTS)
            flds=fieldnames(obj.INTS{i});
            for j = 1:length(flds)
                if isequal(obj.INTS.(flds{j}).(fld),def)
                    obj.INTS.(flds{j}).(fld)=val;
                end
            end
        end
    end
    function modifyAll(obj,fld,val)
    % USED FOR EASY NEAR DUPLICATION
        for i = 1:length(obj.INTS)
            flds=fieldnames(obj.INTS{i});
            for j = 1:length(flds)
                obj.INTS{i}.(flds{j}).(fld)=val;
            end
        end
    end
    function modifyS(obj,fld,val)
    % MODIFY FOR THE REMAINDER OF THE SUBINT
        obj.cOpts.(fld)=val; % current draw
        obj.rOpts.(fld)=val; % rest of interval
    end
%% UTIL
    function n=getNSub(obj,int)
        opts=obj.INTS{obj.nums==int};
        n=numel(fieldnames(opts));
    end
    function key=getKey(obj,num,s)
        if nargin < 2
            num=1;
        end
        if nargin < 3
            s=1;
        end
        flds=fieldnames(obj.INTS{num});
        key=obj.INTS{num}.(flds{s}).key;
    end
    function reInit(obj)
        obj.get_raw_sub_opts();
        obj.parse_sub_opts();
    end
end
methods(Access=private)
    function append_draw(obj,list)
        for i = 1:length(obj.INTS)
            flds=fieldnames(obj.INTS{i});
            for f = 1:length(flds)
                fld=flds{f};
                obj.INTS{i}.(fld).draw=[obj.INTS{i}.(fld).draw; list];
            end
        end
    end
    function out=gdCond(obj)
        bT=  obj.cOpts.t    >= 0;
        bMod=obj.cOpts.modt >= 0;

        gdT  =obj.trl == obj.cOpts.t;
        gdMod=mod(obj.trl,obj.cOpts.modt)==0;
        if obj.cOpts.or
            out=gdMod || gdT;
        else
            out=(~bMod || gdMod) && (~bT || gdT);
        end
    end
    function check_update(obj)
        obj.bNewS=obj.bInit || ( ...
                      obj.bTimeout && ...
                      ~obj.bPause  && ...
                      (obj.cOpts.autoInc || obj.bNext) && ...
                      (~obj.cOpts.keyHold || obj.bCmd) ...
                  );
    end
    function auto_inc(obj,inc)
        if nargin < 2 || isempty(inc)
            inc=1;
        end
        obj.lastInc=[obj.s obj.int obj.trl];
        if obj.bInit
            obj.s=inc;
            obj.int=inc;
            obj.trl=inc;
        elseif obj.s+inc <= obj.nSInts(obj.int)
            obj.s=obj.s+inc;
        elseif obj.int+inc <= numel(obj.INTS)
            obj.s=inc;
            obj.int=obj.int+inc;
        else
            obj.s=inc;
            obj.int=inc;
            obj.trl=obj.trl+inc;
        end

    end
    function reset_time(obj)
        obj.sStartT=0;
        obj.elapsedT=0;
        if isempty(obj.cOpts)
            obj.remainT=0;
        else
            obj.remainT=obj.cOpts.time;
        end
        obj.bTimeout=true;
    end
    function opts=get_raw_sub_opts(obj)
        if ~obj.bNewS && ~obj.bLastInit
            return
        end
        opts=obj.INTS{obj.int};
        obj.rOpts=opts.(obj.sName);
        obj.rOpts.name=obj.sName;
    end
    function parse_sub_opts(obj)
        opts=obj.rOpts;
        if obj.bInit && ~isempty(opts.draw)
            opts.reset=[opts.reset; opts.draw(~ismember(opts.draw,opts.reset),1)];
        elseif obj.bPause
            opts.reset={};
        end

        % META TEXT
        if ~isempty(opts.text)
            opts=obj.parse_text(opts);
        end
        %display([num2str(obj.trl) ' ' num2str(obj.int) ' ' num2str(obj.s)]);
        %display(opts.text.text)

        obj.cOpts=opts;
    end
    function opts=parse_text(obj,opts)
        if iscell(opts.text.text)
            if length(opts.text.text{1})==1 && isempty(opts.text.text{2})
                opts.text.text=obj.(opts.text.text{1}{1});
            end
        end
        if isnumeric(opts.text.text)
            if opts.text.bCeil
                opts.text.text=ceil(opts.text.text);
            end
            opts.text.text=num2str(opts.text.text);
        end
        if ~strcmp(obj.lastText, opts.text.text)
            if ~ismember(opts.text.name, opts.reset)
                opts.reset{end+1,1}=opts.text.name;
            end
        end
        if ~ismember(opts.text.name, opts.draw)
            opts.draw{end+1,1}=opts.text.name;
        end
        obj.lastText=opts.text.text;
    end
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
        obj.defaults=P;

        n=length(intFlds);
        obj.INTS=cell(length(intFlds),1);
        %mtch=regexp(intFlds,'[0-9]*','match');
        %obj.IntNames=cellfun(@str2double,vertcat(mtch{:}));
        obj.IntNames=str2double(intFlds);
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
        obj.nSInts=cellfun(@(x) numel(fieldnames(x)),obj.INTS);

    end
    function out=parse_fun(obj,int,P)
        out=int;
        flds=fieldnames(int);
        for i = 1:length(flds)
            val=int.(flds{i});
            ex=P{ismember(P(:,1),flds{i}),2};

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

        flds={'reset','draw','close'};
        for i =1 :length(flds)
            if ischar(out.(flds{i}));
                out.(flds{i})={out.(flds{i})};
            end
        end
        if isempty(out.or)
            out.or=false;
        elseif isnan(out.or)
            out.or=true;
        elseif ~Num.isInt(out.or)
            error('Invalid value ''or''');
        end

        if ~isempty(out.text)
            if ischar(out.text)
                txt=out.text;
                out.text=struct('text',txt);
            end
            [out.text,Opts]=Args.parseLoose([],PsyInt.getTextP,out.text);
            out.text.Opts=Opts;
            if startsWith(out.text.text,'@')
                [objs,args]=Args.splitMeta(out.text.text);
                out.text.text={objs;args};
            end
        end

    end

end
methods(Static)
    function P=getP()
        P={...
            't',        -1,        'Num.isInt';                          % view
            'modt',     -1,        'Num.isInt';                       % view
            'or',       [],        '@(x) true';                       % view
            ...
            'key',      'limited', 'ischar'; ...               % key
            'mode',     [],        'ischar_e'; ...                    % key
            ...
            'reset',    '',        '@(x) iscell(x) || ischar(x)';   % draw
            'draw',     '',        '@(x) iscell(x) || ischar(x)';   % draw
            'close',    '',        '@(x) true';                     % draw
            ...
            'hook',     '',        'ischar'; ...       % *
            'loadTrls', 0,         'Num.isInt';                       % view
            ...
            'time',     0,         '@(x) true'; ...                   % view
            'autoInc',  1,         'isbinary'; ...
            'keyHold',  0,         'isbinary'; ...
            'text',     [],        '@(x) true';
            ...
            %'close','','@(x) iscell(x) || ischar(x)';
        };
    end
    function P=getTextP()
        P={...
            'text','','ischar';...
            'name','ctrText','ischar';...
            'num',1,'Num.isInt';...
            'bCeil',0,'Num.isBinary';...
            'bgColor',0,'Num.is';...
            'borderFill',0,'Num.is';...
            'borderWidth',0,'Num.is';...
        };
    end
end
end
