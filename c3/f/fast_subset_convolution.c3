module fast_subset_convolution;
const MOD: long = 998244353;

fn int rank_of(usz mask) { int r=0; while(mask>0){r+=(int)(mask&1);mask>>=1;} return r; }
fn void put_i64_le(char* out,usz off,long x){ulong bits=(ulong)x;for(usz b=0;b<8;b++){out[off+b]=(char)(bits&255);bits>>=8;}}

fn long fast_subset_convolution(long* input,usz length,char* output,usz capacity) @export("fast_subset_convolution") {
    if(input==null||length<3||length>33)return -1;
    long n64=input[0];if(n64<0||n64>4)return -1;
    usz n=(usz)n64,size=(usz)1<<n;if(length!=1+2*size)return -1;
    for(usz i=0;i<2*size;i++)if(input[1+i]<0||input[1+i]>=MOD)return -1;
    long[5][16] f=zeroed;long[5][16] g=zeroed;long[5][16] h=zeroed;
    for(usz s=0;s<size;s++){usz r=(usz)rank_of(s);f[r][s]=input[1+s];g[r][s]=input[1+size+s];}
    for(usz bit=0;bit<n;bit++)for(usz s=0;s<size;s++)if((s&((usz)1<<bit))!=0){usz other=s^((usz)1<<bit);for(usz r=0;r<=n;r++){f[r][s]=(f[r][s]+f[r][other])%MOD;g[r][s]=(g[r][s]+g[r][other])%MOD;}}
    for(usz s=0;s<size;s++)for(usz r=0;r<=n;r++){long sum=0;for(usz i=0;i<=r;i++)sum=(sum+f[i][s]*g[r-i][s])%MOD;h[r][s]=sum;}
    for(usz bit=0;bit<n;bit++)for(usz s=0;s<size;s++)if((s&((usz)1<<bit))!=0){usz other=s^((usz)1<<bit);for(usz r=0;r<=n;r++)h[r][s]=(h[r][s]-h[r][other]+MOD)%MOD;}
    usz required=size*8;if(capacity<required||output==null)return -2;
    for(usz s=0;s<size;s++)put_i64_le(output,8*s,h[rank_of(s)][s]);return (long)required;
}
