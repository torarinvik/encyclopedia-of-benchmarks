module number_theoretic_transform;
// New bounded port based on AtCoder Library convolution semantics (CC0); see benchmarks/n/number_theoretic_transform/LICENSE.txt.
const long MOD = 998244353;
fn long mod_pow(long a, long e) { long r=1; while (e>0) { if ((e&1)!=0) r=(r*a)%MOD; a=(a*a)%MOD; e >>= 1; } return r; }
fn long number_theoretic_transform(long* input, usz length, uint8* output, usz capacity) @export("number_theoretic_transform") {
    if (input==null || length<2 || length>65) return -1;
    long n0=input[0]; if (n0<1 || n0>64 || (n0&(n0-1))!=0 || length!=(usz)n0+1) return -1;
    int n=(int)n0; long[64] a;
    for (int i=0;i<n;i++) { if (input[i+1]<0 || input[i+1]>=MOD) return -1; a[i]=input[i+1]; }
    if (output==null || capacity<4*n) return -2;
    for (int i=1,j=0;i<n;i++) { int bit=n/2; for (; (j&bit)!=0;bit>>=1) j^=bit; j^=bit; if (i<j) { long t=a[i];a[i]=a[j];a[j]=t; } }
    for (int len=2;len<=n;len*=2) { long step=mod_pow(3,(MOD-1)/len); for (int base=0;base<n;base+=len) { long w=1; for (int j=0;j<len/2;j++) { long u=a[base+j],v=(a[base+j+len/2]*w)%MOD; a[base+j]=(u+v)%MOD; a[base+j+len/2]=(u-v+MOD)%MOD; w=(w*step)%MOD; } } }
    for (int i=0;i<n;i++) { ulong x=(ulong)a[i]; for (int b=0;b<4;b++) output[4*i+b]=(uint8)(x>>(8*b)); }
    return 4*n;
}
