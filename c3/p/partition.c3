module partition;
fn bool solve(long* v,usz n,usz i,long target,long half){if(target==half)return true;if(i>=n||target>half)return false;return solve(v,n,i+1,target+v[i],half)||solve(v,n,i+1,target,half);}
fn long partition(long* v,usz n) @export("partition"){if(v==null||n<1||n>17||v[0]<0||v[0]>16||n!=(usz)v[0]+1)return -1;usz count=(usz)v[0];long sum=0;for(usz i=1;i<n;i++){if(v[i]<0||v[i]>1000)return -1;sum+=v[i];}if(sum%2!=0)return 0;return solve(&v[1],count,0,0,sum/2); }
