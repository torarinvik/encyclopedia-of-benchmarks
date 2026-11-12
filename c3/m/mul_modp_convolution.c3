module mul_modp_convolution;

const usz MAX_P = 97;
const usz MAX_INPUT = 196;
const usz MAX_OUTPUT = 776;
const long MOD = 998244353;

fn long pow_mod(long base, int exponent, int modulus) {
    long result=1;
    while(exponent>0){if((exponent&1)!=0)result=result*base%modulus;base=base*base%modulus;exponent>>=1;}
    return result;
}
fn bool is_prime(int p){if(p<2)return false;for(int d=2;d*d<=p;d++)if(p%d==0)return false;return true;}
fn int primitive_root(int p){
    int order=p-1;
    for(int candidate=1;candidate<p;candidate++){
        bool ok=true;
        for(int f=2;f<=order;f++){
            if(order%f!=0)continue;
            bool prime=true;for(int d=2;d*d<=f;d++)if(f%d==0){prime=false;break;}
            if(prime&&pow_mod(candidate,order/f,p)==1){ok=false;break;}
        }
        if(ok)return candidate;
    }
    return 1;
}
fn void store_le(uint8 *out,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){out[offset+b]=(uint8)(bits&255ul);bits>>=8;}}

fn long mul_modp_convolution(long *input,usz length,uint8 *output,usz capacity)
    @export("mul_modp_convolution") {
    if(input==null||length<5||length>MAX_INPUT)return -1;
    long p0=input[0];if(p0<2||p0>MAX_P||!is_prime((int)p0))return -1;
    int p=(int)p0;usz ps=(usz)p;if(length!=1+2*ps)return -1;
    for(usz i=1;i<length;i++)if(input[i]<0||input[i]>=MOD)return -1;
    usz bytes=8*ps;if(bytes>MAX_OUTPUT)return -1;if(output==null||capacity<bytes)return -2;
    long[97] a,b,left,right,cyclic,result;
    for(int i=0;i<97;i++)cyclic[i]=0;
    for(int i=0;i<p;i++){a[i]=input[1+i];b[i]=input[1+p+i];}
    int q=p-1,root=primitive_root(p),residue=1;
    int[97] by_exp,exp_by;for(int i=0;i<p;i++)exp_by[i]=-1;
    for(int e=0;e<q;e++){by_exp[e]=residue;exp_by[residue]=e;residue=(int)((long)residue*root%p);}
    for(int e=0;e<q;e++){left[e]=a[by_exp[e]];right[e]=b[by_exp[e]];}
    for(int i=0;i<q;i++)for(int j=0;j<q;j++){int slot=(i+j)%q;cyclic[slot]=(cyclic[slot]+left[i]*right[j]%MOD)%MOD;}
    long sum_a=0,sum_b=0;for(int i=0;i<p;i++)sum_a=(sum_a+a[i])%MOD;for(int i=1;i<p;i++)sum_b=(sum_b+b[i])%MOD;
    result[0]=(sum_a*b[0]%MOD+a[0]*sum_b%MOD)%MOD;
    for(int e=0;e<q;e++)result[by_exp[e]]=cyclic[e];
    for(int i=0;i<p;i++)store_le(output,8*(usz)i,result[i]);
    return (long)bytes;
}
