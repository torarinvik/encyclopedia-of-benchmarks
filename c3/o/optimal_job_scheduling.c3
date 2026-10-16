module optimal_job_scheduling;
fn usz append_uint(char*b,usz n,uint x){char[10] d;usz k=0;do{d[k++]=(char)('0'+x%10);x/=10;}while(x>0);while(k>0)b[n++]=d[--k];return n;}
fn long optimal_job_scheduling(long*v,usz n,char*out,usz cap) @export("optimal_job_scheduling"){
if(v==null||n<4||n>194||v[0]<1||v[0]>16||v[1]<1||v[1]>8)return -1;usz p=(usz)v[0],m=(usz)v[1];if(n!=2+p*m+m*m)return -1;uint[128] run;uint[64] transfer;usz at=2;
for(usz i=0;i<p*m;i++){if(v[at]<0||v[at]>1000)return -1;run[i]=(uint)v[at++];}for(usz i=0;i<m*m;i++){if(v[at]<0||v[at]>1000)return -1;transfer[i]=(uint)v[at++];}
uint[128] cost;for(usz j=0;j<m;j++)cost[j]=run[j];for(usz i=1;i<p;i++)for(usz j=0;j<m;j++){uint best=0xFFFFFFFF;for(usz k=0;k<m;k++){uint x=cost[(i-1)*m+k]+transfer[k*m+j]+run[i*m+j];if(x<best)best=x;}cost[i*m+j]=best;}
char[2048] b;usz used=0;for(usz i=0;i<p;i++){for(usz j=0;j<m;j++){if(j)b[used++]=',';used=append_uint(&b[0],used,cost[i*m+j]);}if(i+1<p)b[used++]='\n';}if(used>cap)return -2;for(usz i=0;i<used;i++)out[i]=b[i];return (long)used;
}
