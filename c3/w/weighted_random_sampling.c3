module weighted_random_sampling;
const usz MAX_N=16; const usz MAX_INPUT=50;

fn long pow_small(long base, long exponent) {
    long result=1;
    for (long i=0;i<exponent;i+=1) result*=base;
    return result;
}
fn void put64(char*o,usz p,long x){ulong b=(ulong)x;for(usz j=0;j<8;j+=1){o[p+j]=(char)(b&255);b>>=8;}}

long weighted_random_sampling(long*in,usz len,char*out,usz cap) @export("weighted_random_sampling") {
    if(in==null||len<5||len>MAX_INPUT)return -1;
    long n64=in[0],count64=in[1];
    if(n64<1||n64>(long)MAX_N||count64<1||count64>n64||len!=2+3*(usz)n64)return -1;
    usz n=(usz)n64,count=(usz)count64;
    long[MAX_N] weights=zeroed,nums=zeroed,dens=zeroed;
    for(usz i=0;i<n;i+=1){weights[i]=in[2+3*i];nums[i]=in[3+3*i];dens[i]=in[4+3*i];if(weights[i]<1||weights[i]>3||nums[i]<1||nums[i]>=dens[i]||dens[i]>100)return -1;}
    usz bytes=8*count;if(out==null||cap<bytes)return -2;
    long[MAX_N] available=zeroed,selected=zeroed;for(usz i=0;i<n;i+=1)available[i]=(long)i;
    for(usz rank=0;rank<count;rank+=1){usz best=0;for(usz i=1;i<n-rank;i+=1){long left=available[i],right=available[best];long lhs=pow_small(nums[(usz)left],weights[(usz)right])*pow_small(dens[(usz)right],weights[(usz)left]);long rhs=pow_small(nums[(usz)right],weights[(usz)left])*pow_small(dens[(usz)left],weights[(usz)right]);if(lhs>rhs||(lhs==rhs&&left<right))best=i;}selected[rank]=available[best];for(usz i=best;i+1<n-rank;i+=1)available[i]=available[i+1];}
    for(usz i=0;i<count;i+=1)put64(out,8*i,selected[i]);return (long)bytes;
}
