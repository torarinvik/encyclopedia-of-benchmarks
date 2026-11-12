#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

enum { MAX_P=97, MAX_INPUT=196, MAX_OUTPUT=776, MOD=998244353 };

static int64_t pow_mod(int64_t base,int exponent,int modulus){
    int64_t result=1;while(exponent>0){if(exponent&1)result=result*base%modulus;base=base*base%modulus;exponent>>=1;}return result;
}
static bool is_prime(int p){if(p<2)return false;for(int d=2;d*d<=p;++d)if(p%d==0)return false;return true;}
static int primitive_root(int p){
    int order=p-1;
    for(int candidate=1;candidate<p;++candidate){bool root=true;
        for(int factor=2;factor<=order;++factor){if(order%factor!=0)continue;bool prime=true;for(int d=2;d*d<=factor;++d)if(factor%d==0){prime=false;break;}
            if(prime&&pow_mod(candidate,order/factor,p)==1){root=false;break;}}
        if(root)return candidate;
    }return 1;
}
static void store_i64_le(uint8_t *out,size_t at,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b){out[at+b]=(uint8_t)(bits&255u);bits>>=8;}}

int64_t mul_modp_convolution(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<5||length>MAX_INPUT)return -1;
    int64_t p0=input[0];if(p0<2||p0>MAX_P||!is_prime((int)p0))return -1;
    int p=(int)p0;if(length!=1+2*(size_t)p)return -1;
    for(size_t i=1;i<length;++i)if(input[i]<0||input[i]>=MOD)return -1;
    size_t bytes=8*(size_t)p;if(bytes>MAX_OUTPUT)return -1;
    if(output==NULL||capacity<bytes)return -2;
    int64_t a[MAX_P],b[MAX_P],left[MAX_P],right[MAX_P],cyclic[MAX_P]={0},result[MAX_P]={0};
    for(int i=0;i<p;++i){a[i]=input[1+i];b[i]=input[1+p+i];}
    int order=p-1,root=primitive_root(p),residue=1;
    int residue_by_exp[MAX_P],exp_by_residue[MAX_P];for(int i=0;i<p;++i)exp_by_residue[i]=-1;
    for(int e=0;e<order;++e){residue_by_exp[e]=residue;exp_by_residue[residue]=e;residue=(int)((int64_t)residue*root%p);}
    for(int e=0;e<order;++e){left[e]=a[residue_by_exp[e]];right[e]=b[residue_by_exp[e]];}
    for(int i=0;i<order;++i)for(int j=0;j<order;++j){int slot=(i+j)%order;cyclic[slot]=(cyclic[slot]+left[i]*right[j]%MOD)%MOD;}
    int64_t sum_a=0,sum_b_nonzero=0;for(int i=0;i<p;++i)sum_a=(sum_a+a[i])%MOD;for(int i=1;i<p;++i)sum_b_nonzero=(sum_b_nonzero+b[i])%MOD;
    result[0]=(sum_a*b[0]%MOD+a[0]*sum_b_nonzero%MOD)%MOD;
    for(int e=0;e<order;++e)result[residue_by_exp[e]]=cyclic[e];
    for(int i=0;i<p;++i)store_i64_le(output,8*(size_t)i,result[i]);
    return (int64_t)bytes;
}
