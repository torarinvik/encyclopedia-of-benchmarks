module multivariate_convolution_cyclic;
const usz MAX_K=3,MAX_P=32,MAX_INPUT=70,MAX_OUTPUT=256;
fn bool is_prime(int p){if(p<2)return false;for(int d=2;d*d<=p;d++)if(p%d==0)return false;return true;}
fn void store_le(uint8 *out,usz at,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){out[at+b]=(uint8)(bits&255ul);bits>>=8;}}
fn long multivariate_convolution_cyclic(long *input,usz length,uint8 *output,usz capacity) @export("multivariate_convolution_cyclic") {
    if(input==null||length<2||length>MAX_INPUT)return -1;long p0=input[0],k0=input[1];if(p0<2||p0>97||!is_prime((int)p0)||k0<0||k0>3)return -1;usz p=(usz)p0,k=(usz)k0;if(length<2+k)return -1;
    usz[3] dims;usz product=1;for(usz axis=0;axis<k;axis++){long d0=input[2+axis];if(d0<2||d0>MAX_P||(p-1)%(usz)d0!=0||product>MAX_P/(usz)d0)return -1;dims[axis]=(usz)d0;product*=dims[axis];}
    usz start=2+k;if(length!=start+2*product)return -1;for(usz q=start;q<length;q++)if(input[q]<0||input[q]>=p0)return -1;usz bytes=8*product;if(bytes>MAX_OUTPUT)return -1;if(output==null||capacity<bytes)return -2;
    long[MAX_P] a,b,result;for(usz i=0;i<product;i++){a[i]=input[start+i];b[i]=input[start+product+i];result[i]=0;}
    for(usz i=0;i<product;i++)for(usz j=0;j<product;j++){usz target=0,stride=1;for(usz axis=0;axis<k;axis++){usz d=dims[axis],sum=((i/stride)%d+(j/stride)%d)%d;target+=sum*stride;stride*=d;}result[target]=(result[target]+a[i]*b[j])%p0;}
    for(usz i=0;i<product;i++)store_le(output,8*i,result[i]);return (long)bytes;
}
