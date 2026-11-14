module polynomial_discrete_antiderivative;
const long MODULUS=998244353;
fn long polynomial_discrete_antiderivative(long* input, usz length, uchar* output, usz capacity)
        @export("polynomial_discrete_antiderivative") {
    if (input==null || length<2 || length>33 || input[0]<1 || input[0]>32) return -1;
    int n=(int)input[0];
    if (length!=(usz)(n+1)) return -1;
    for (int i=0; i<n; i++) if (input[1+i]<0 || input[1+i]>=MODULUS) return -1;
    if (output==null || capacity<(usz)(8*(n+1))) return -2;
    long[1089] choose={}; long[33] inverse={}, g={};
    choose[0]=1;
    for (int k=1; k<=n; k++) {
        choose[33*k]=1; choose[33*k+k]=1;
        for (int j=1; j<k; j++) choose[33*k+j]=(choose[33*(k-1)+j-1]+choose[33*(k-1)+j])%MODULUS;
    }
    inverse[1]=1;
    for (int k=2; k<=n; k++) inverse[k]=MODULUS-(MODULUS/k)*inverse[MODULUS%k]%MODULUS;
    for (int j=n-1; j>=0; j--) {
        long sum=0;
        for (int k=j+2; k<=n; k++) sum=(sum+choose[33*k+j]*g[k])%MODULUS;
        g[j+1]=((input[1+j]-sum+MODULUS)%MODULUS)*inverse[j+1]%MODULUS;
    }
    for (int i=0; i<=n; i++) {
        ulong bits=(ulong)g[i];
        for (int byte=0; byte<8; byte++) output[8*i+byte]=(uchar)(bits >> (8*byte));
    }
    return 8*(n+1);
}
