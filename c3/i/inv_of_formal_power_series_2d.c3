module inv_of_formal_power_series_2d;
const long MODULUS=998244353;
fn long power(long x,int exponent) {
    long result=1;
    while (exponent>0) {
        if ((exponent & 1)!=0) result=result*x%MODULUS;
        x=x*x%MODULUS; exponent >>= 1;
    }
    return result;
}
fn long inv_of_formal_power_series_2d(long* input,usz length,uchar* output,usz capacity)
        @export("inv_of_formal_power_series_2d") {
    if (input==null || length<3 || length>66 || input[0]<1 || input[0]>8 || input[1]<1 || input[1]>8) return -1;
    int n=(int)input[0], m=(int)input[1];
    if (length!=(usz)(2+n*m) || input[2]==0) return -1;
    for (int i=0;i<n*m;i++) if (input[2+i]<0 || input[2+i]>=MODULUS) return -1;
    if (output==null || capacity<(usz)(8*n*m)) return -2;
    long[64] g={}; long inverse=power(input[2],998244351); g[0]=inverse;
    for (int i=0;i<n;i++) for (int j=0;j<m;j++) {
        if (i==0 && j==0) continue;
        long sum=0;
        for (int a=0;a<=i;a++) for (int b=0;b<=j;b++)
            if (a!=0 || b!=0) sum=(sum+input[2+a*m+b]*g[(i-a)*m+j-b])%MODULUS;
        g[i*m+j]=((MODULUS-sum)%MODULUS)*inverse%MODULUS;
    }
    for (int i=0;i<n*m;i++) {
        ulong bits=(ulong)g[i];
        for (int byte=0;byte<8;byte++) output[8*i+byte]=(uchar)(bits >> (8*byte));
    }
    return 8*n*m;
}
