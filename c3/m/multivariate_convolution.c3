module multivariate_convolution;
const usz MAX_K = 3, MAX_P = 32, MAX_INPUT = 69, MAX_OUTPUT = 256;
const long MOD = 998244353;
fn void store_le(uint8 *out, usz at, long value) { ulong bits=(ulong)value; for(usz b=0;b<8;b++){out[at+b]=(uint8)(bits&255ul);bits>>=8;} }
fn long multivariate_convolution(long *input, usz length, uint8 *output, usz capacity) @export("multivariate_convolution") {
    if(input==null||length<1||length>MAX_INPUT)return -1;long k0=input[0];if(k0<0||k0>3)return -1;usz k=(usz)k0;if(length<1+k)return -1;
    usz[3] dims;usz p=1;for(usz axis=0;axis<k;axis++){long d0=input[1+axis];if(d0<2||d0>32||p>MAX_P/(usz)d0)return -1;dims[axis]=(usz)d0;p*=dims[axis];}
    if(length!=1+k+2*p)return -1;usz start=1+k;for(usz q=start;q<length;q++)if(input[q]<0||input[q]>=MOD)return -1;
    usz bytes=8*p;if(bytes>MAX_OUTPUT)return -1;if(output==null||capacity<bytes)return -2;
    long[MAX_P] a,b,result;for(usz i=0;i<p;i++){a[i]=input[start+i];b[i]=input[start+p+i];result[i]=0;}
    for(usz i=0;i<p;i++)for(usz j=0;j<p;j++){usz target=0,stride=1;bool valid=true;for(usz axis=0;axis<k;axis++){usz d=dims[axis],sum=(i/stride)%d+(j/stride)%d;if(sum>=d){valid=false;break;}target+=sum*stride;stride*=d;}if(valid)result[target]=(result[target]+a[i]*b[j])%MOD;}
    for(usz i=0;i<p;i++)store_le(output,8*i,result[i]);return (long)bytes;
}
