function [tout,yout,inds] = downsample_from_threshold(tin,yin,thresh,apwidth,dsf,varargin)
% thresh is theshold for spiking
% apwidth is overall size of AP (will be spread around thresh)
% dsf is downsample factor
% dsf_all varargin{1}; option to downsample all the data at the start, dsf
% will then downsample a factor multiplicative with dsf_all.
SHOWFIGS=0;
preservedIdx=[];
if nargin>5
   dsf_all= varargin{1};
   tin=tin(1:dsf_all:end);
   yin=yin(1:dsf_all:end);
   if nargin>6
      preservedIdx=varargin{2};
      if nargin> 7
          SHOWFIGS=varargin{3};
      end
   else
       preservedIdx=[];
   end
end
tinMin=tin(2)-tin(1); % assume starts from uniform
apwidthidx=apwidth/tinMin;
halfWindow=ceil(apwidthidx/2);

idx = find(yin>thresh);

idxUsetemp = find(diff(idx)>20); % arbitrary, could be wrong in weird cases.
idxUse=idxUsetemp+1;
if ~isempty(idxUse)
idxUse=[1; idxUse];
end
idxUse = [idxUse];
if SHOWFIGS
figure, 
plot(tin,yin,'.'), hold on
if ~isempty(idxUse)
plot(tin(idx(idxUse)),yin(idx(idxUse)),'x')
end
end
idxWAPwindow=[];
idxAtThresh=idx(idxUse);
for i=1:length(idxAtThresh)   
    idxWAPwindow=[idxWAPwindow (max(idxAtThresh(i)-halfWindow,1)):(min(idxAtThresh(i)+halfWindow,length(yin)));];
end
idxWAPwindow=unique(idxWAPwindow);
idxWAPwindow=sort(idxWAPwindow);
if SHOWFIGS
figure, plot(tin,yin,'--'), hold on, plot(tin(idxWAPwindow),yin(idxWAPwindow),'rx')
end
% downsample
idxOrig=1:length(yin);
idxSlow=~ismember(idxOrig,idxWAPwindow);
idxSlow=idxOrig(idxSlow);
idxSlowDS=idxSlow(1:dsf:end);
fullidx=[idxWAPwindow idxSlowDS preservedIdx];
fullidx=sort(unique(fullidx));

% crappy way to push things to two regions (downsampled and regular
% sampled)
idxtemp=find((diff(fullidx)>0) & (diff(fullidx)<dsf));
for j=idxtemp
    fullidx=[fullidx fullidx(j):fullidx(j+1)];
end
fullidx=unique(fullidx);
fullidx=sort(fullidx);

tout=tin(fullidx);
yout=yin(fullidx);
inds=fullidx;
if SHOWFIGS
figure, plot(tin,yin,'--')
hold on, plot(tin(fullidx),yin(fullidx),'x')
figure, plot(tin,yin,'--')
hold on, plot(tin(idxWAPwindow),yin(idxWAPwindow),'x')
hold on, plot(tin(idxSlowDS),yin(idxSlowDS),'x')
end

% 
% at the moment, transitions are not dealt with well.
end