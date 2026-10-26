module list_scheduling;
const usz MAX_M=8; const usz MAX_N=32; const usz MAX_INPUT=34;
fn void put64(char* o,usz p,long x){ulong b=(ulong)x;for(usz j=0;j<8;j+=1){o[p+j]=(char)(b&255);b>>=8;}}
long list_scheduling(long* in,usz len,char* out,usz cap) @export("list_scheduling"){
    if(in==null||len<3||len>MAX_INPUT)return -1;long m64=in[0],n64=in[1];
    if(m64<1||m64>(long)MAX_M||n64<1||n64>(long)MAX_N||len!=2+(usz)n64)return -1;
    usz m=(usz)m64,n=(usz)n64;for(usz i=0;i<n;i+=1)if(in[2+i]<1||in[2+i]>10000)return -1;
    usz bytes=8*(1+n+m);if(out==null||cap<bytes)return -2;
    long[MAX_M] load=zeroed;long[MAX_N] assign=zeroed;
    for(usz i=0;i<n;i+=1){usz best=0;for(usz j=1;j<m;j+=1)if(load[j]<load[best])best=j;assign[i]=(long)best;load[best]+=in[2+i];}
    long makespan=load[0];for(usz j=1;j<m;j+=1)if(load[j]>makespan)makespan=load[j];
    put64(out,0,makespan);for(usz i=0;i<n;i+=1)put64(out,8*(1+i),assign[i]);for(usz j=0;j<m;j+=1)put64(out,8*(1+n+j),load[j]);return (long)bytes;
}
