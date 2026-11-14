module dirichlet_inverse_and_prefix_sums;
const long MODULUS = 998244353;
fn long power(long base, int exponent) {
    long result=1;
    while (exponent>0) {
        if ((exponent & 1) != 0) result=result*base%MODULUS;
        base=base*base%MODULUS; exponent >>= 1;
    }
    return result;
}
fn int locate(int* q, int count, int value) {
    int lo=0, hi=count;
    while (lo<hi) {
        int mid=lo+(hi-lo)/2;
        if (q[mid]<value) lo=mid+1; else hi=mid;
    }
    return lo<count && q[lo]==value ? lo : -1;
}
fn long dirichlet_inverse_and_prefix_sums(long* input, usz length, uchar* output, usz capacity)
        @export("dirichlet_inverse_and_prefix_sums") {
    if (input==null || length<2 || length>16 || input[0]<1 || input[0]>64) return -1;
    int n=(int)input[0], count=0;
    int[15] q = {};
    for (int i=n; i>=1; i--) {
        int value=n/i;
        if (count==0 || q[count-1]!=value) q[count++]=value;
    }
    if (length!=(usz)(1+count) || input[1]==0) return -1;
    for (int i=0; i<count; i++) if (input[1+i]<0 || input[1+i]>=MODULUS) return -1;
    if (output==null || capacity<(usz)(8*count)) return -2;
    long inverse=power(input[1],998244351);
    long[15] g = {};
    for (int i=0; i<count; i++) {
        int x=q[i], left=2; long total=0;
        while (left<=x) {
            int quotient=x/left, right=x/quotient;
            int hi=locate(&q[0],count,right), lo=locate(&q[0],count,left-1), gi=locate(&q[0],count,quotient);
            if (hi<0 || lo<0 || gi<0) return -1;
            long interval=(input[1+hi]-input[1+lo]+MODULUS)%MODULUS;
            total=(total+interval*g[gi])%MODULUS;
            left=right+1;
        }
        g[i]=((1-total+MODULUS)%MODULUS)*inverse%MODULUS;
    }
    for (int i=0; i<count; i++) {
        ulong bits=(ulong)g[i];
        for (int byte=0; byte<8; byte++) output[8*i+byte]=(uchar)(bits >> (8*byte));
    }
    return 8*count;
}
