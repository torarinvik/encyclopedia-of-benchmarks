module smith_weighted_completion_time;
const usz MAX_N=12;const usz MAX_INPUT=25;
fn void put64(char*o,usz p,long x){ulong b=(ulong)x;for(usz j=0;j<8;j+=1){o[p+j]=(char)(b&255);b>>=8;}}
long smith_weighted_completion_time(long*in,usz len,char*out,usz cap) @export("smith_weighted_completion_time"){
 if(in==null||len<3||len>MAX_INPUT)return -1;long n64=in[0];if(n64<1||n64>(long)MAX_N||len!=1+2*(usz)n64)return -1;usz n=(usz)n64;
 long[MAX_N] p=zeroed,w=zeroed,order=zeroed;for(usz i=0;i<n;i+=1){p[i]=in[1+2*i];w[i]=in[2+2*i];if(p[i]<1||p[i]>10000||w[i]<1||w[i]>10000)return -1;order[i]=(long)i;}
 usz bytes=8*(n+1);if(out==null||cap<bytes)return -2;
 for(usz i=1;i<n;i+=1){long key=order[i];usz j=i;while(j>0){usz prev=(usz)order[j-1];bool before=w[(usz)key]*p[prev]>w[prev]*p[(usz)key]||(w[(usz)key]*p[prev]==w[prev]*p[(usz)key]&&key<(long)prev);if(!before)break;order[j]=order[j-1];j-=1;}order[j]=key;}
 long time=0,total=0;for(usz i=0;i<n;i+=1){usz job=(usz)order[i];time+=p[job];total+=w[job]*time;}put64(out,0,total);for(usz i=0;i<n;i+=1)put64(out,8*(i+1),order[i]);return (long)bytes;
}
