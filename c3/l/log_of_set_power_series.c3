module log_of_set_power_series;
const long MODULUS=998244353;
fn long log_of_set_power_series(long* input,usz length,uchar* output,usz capacity) @export("log_of_set_power_series") {
    if (input==null || length<2 || length>33 || input[0]<0 || input[0]>5) return -1;
    int size=1 << (int)input[0];
    if (length!=(usz)(1+size) || input[1]!=1) return -1;
    for (int i=0;i<size;i++) if (input[1+i]<0 || input[1+i]>=MODULUS) return -1;
    if (output==null || capacity<(usz)(8*size)) return -2;
    long[32] result={};
    for (int mask=1;mask<size;mask++) {
        int pivot=mask & -mask; long sum=0;
        for (int sub=(mask-1)&mask;sub!=0;sub=(sub-1)&mask)
            if ((sub & pivot)!=0) sum=(sum+result[sub]*input[1+(mask^sub)])%MODULUS;
        result[mask]=(input[1+mask]-sum+MODULUS)%MODULUS;
    }
    for (int i=0;i<size;i++) {
        ulong bits=(ulong)result[i];
        for (int byte=0;byte<8;byte++) output[8*i+byte]=(uchar)(bits >> (8*byte));
    }
    return 8*size;
}
