#include <cstddef>
#include <cstdint>
#include <algorithm>

namespace {
constexpr int MAX_P=97, MOD=998244353;
std::int64_t pow_mod(std::int64_t base,int exponent,int modulus){std::int64_t r=1;while(exponent){if(exponent&1)r=r*base%modulus;base=base*base%modulus;exponent>>=1;}return r;}
bool is_prime(int p){if(p<2)return false;for(int d=2;d*d<=p;++d)if(p%d==0)return false;return true;}
int primitive_root(int p){int order=p-1;for(int candidate=1;candidate<p;++candidate){bool ok=true;for(int f=2;f<=order;++f){if(order%f)continue;bool prime=true;for(int d=2;d*d<=f;++d)if(f%d==0){prime=false;break;}if(prime&&pow_mod(candidate,order/f,p)==1){ok=false;break;}}if(ok)return candidate;}return 1;}
void store_le(std::uint8_t *o,std::size_t at,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;++i){o[at+i]=static_cast<std::uint8_t>(b&255u);b>>=8;}}
}

extern "C" std::int64_t mul_modp_convolution(const std::int64_t *input,std::size_t length,
    std::uint8_t *output,std::size_t capacity){
    if(!input||length<5||length>196)return -1;
    const auto p0=input[0];if(p0<2||p0>MAX_P||!is_prime(static_cast<int>(p0)))return -1;
    const int p=static_cast<int>(p0);if(length!=1+2*static_cast<std::size_t>(p))return -1;
    for(std::size_t i=1;i<length;++i)if(input[i]<0||input[i]>=MOD)return -1;
    const auto bytes=8*static_cast<std::size_t>(p);if(bytes>776)return -1;if(!output||capacity<bytes)return -2;
    std::int64_t a[MAX_P]{},b[MAX_P]{},left[MAX_P]{},right[MAX_P]{},cyclic[MAX_P]{},result[MAX_P]{};
    for(int i=0;i<p;++i){a[i]=input[1+i];b[i]=input[1+p+i];}
    const int q=p-1,root=primitive_root(p);int residue=1;int by_exp[MAX_P]{},exp_by[MAX_P]{};
    for(int i=0;i<p;++i)exp_by[i]=-1;
    for(int e=0;e<q;++e){by_exp[e]=residue;exp_by[residue]=e;residue=static_cast<int>(static_cast<std::int64_t>(residue)*root%p);}
    for(int e=0;e<q;++e){left[e]=a[by_exp[e]];right[e]=b[by_exp[e]];}
    for(int i=0;i<q;++i)for(int j=0;j<q;++j){const int slot=(i+j)%q;cyclic[slot]=(cyclic[slot]+left[i]*right[j]%MOD)%MOD;}
    std::int64_t sa=0,sb=0;for(int i=0;i<p;++i)sa=(sa+a[i])%MOD;for(int i=1;i<p;++i)sb=(sb+b[i])%MOD;
    result[0]=(sa*b[0]%MOD+a[0]*sb%MOD)%MOD;
    for(int e=0;e<q;++e)result[by_exp[e]]=cyclic[e];
    for(int i=0;i<p;++i)store_le(output,8*static_cast<std::size_t>(i),result[i]);
    return static_cast<std::int64_t>(bytes);
}
