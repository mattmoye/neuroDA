function filename =     save_as_dot_mat_from_time_obs(tmeas,ymeas,datafilename)

inds=1:length(tmeas);
inds=reshape(inds,length(inds),1); 
Iappdata=zeros(size(tmeas));
Iappdata=reshape(Iappdata,length(Iappdata),1);
obs=reshape(ymeas,max(size(ymeas)),min(size(ymeas)));
time = reshape(tmeas,length(tmeas),1);
%filename=['fib];
[folder, filename, extension]=fileparts(datafilename);
%filename=filename(1:end-
filename=strrep(filename,'.','pt');
filename=[filename,'for_AD','.mat'];
data = [inds, time, Iappdata, obs];
save(filename,'data');
end