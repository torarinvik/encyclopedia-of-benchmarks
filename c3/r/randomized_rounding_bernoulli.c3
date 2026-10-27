module randomized_rounding_bernoulli;
const usz MAX_N=16; const usz MAX_INPUT=65;

long randomized_rounding_bernoulli(long*in,usz len,char*out,usz cap) @export("randomized_rounding_bernoulli") {
    if(in==null||len<5||len>MAX_INPUT)return -1;
    long n64=in[0];
    if(n64<1||n64>(long)MAX_N||len!=1+4*(usz)n64)return -1;
    usz n=(usz)n64;
    char[MAX_N] staged=zeroed;
    for(usz i=0;i<n;i+=1){
        long xn=in[1+4*i],xd=in[2+4*i],un=in[3+4*i],ud=in[4+4*i];
        if(xd<1||xd>32||xn<0||xn>xd||ud<1||ud>32||un<0||un>=ud)return -1;
        staged[i]=(char)(un*xd<xn*ud);
    }
    if(out==null||cap<n)return -2;
    for(usz i=0;i<n;i+=1)out[i]=staged[i];
    return (long)n;
}
