module first_fit_bin_packing;
fn void put_i64_le(char* out,usz off,long x){ulong u=(ulong)x;for(usz b=0;b<8;b++){out[off+b]=(char)(u&255);u>>=8;}}
fn long first_fit_bin_packing(long* input,usz length,char* output,usz capacity) @export("first_fit_bin_packing") {
    if(input==null||length<1||length>65)return -1;long n64=input[0];if(n64<0||n64>64||length!=1+(usz)n64)return -1;usz n=(usz)n64;
    for(usz i=0;i<n;i++)if(input[i+1]<1||input[i+1]>1000000)return -1;
    long[64] loads=zeroed;long[64] ids=zeroed;usz bins=0;
    for(usz i=0;i<n;i++){long size=input[i+1];usz b=0;while(b<bins&&loads[b]+size>1000000)b++;if(b==bins){loads[bins]=size;bins++;}else loads[b]+=size;ids[i]=(long)b;}
    usz required=(n+1)*8;if(capacity<required||output==null)return -2;put_i64_le(output,0,(long)bins);for(usz i=0;i<n;i++)put_i64_le(output,8*(i+1),ids[i]);return (long)required;
}
