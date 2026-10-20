// New bounded port based on AtCoder Library convolution semantics (CC0); see benchmarks/n/number_theoretic_transform/LICENSE.txt.
#include <cstddef>
#include <cstdint>
static constexpr std::int64_t MOD=998244353;
static std::int64_t mod_pow(std::int64_t a,std::int64_t e){std::int64_t r=1;while(e>0){if(e&1)r=r*a%MOD;a=a*a%MOD;e>>=1;}return r;}
extern "C" std::int64_t number_theoretic_transform(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(input==nullptr||length<2||length>65)return -1;auto n0=input[0];if(n0<1||n0>64||(n0&(n0-1))!=0||length!=static_cast<std::size_t>(n0)+1)return -1;int n=static_cast<int>(n0);std::int64_t a[64];
    for(int i=0;i<n;i++){if(input[i+1]<0||input[i+1]>=MOD)return -1;a[i]=input[i+1];}if(output==nullptr||capacity<static_cast<std::size_t>(4*n))return -2;
    for(int i=1,j=0;i<n;i++){int bit=n/2;for(;j&bit;bit>>=1)j^=bit;j^=bit;if(i<j){auto t=a[i];a[i]=a[j];a[j]=t;}}
    for(int len=2;len<=n;len*=2){auto step=mod_pow(3,(MOD-1)/len);for(int base=0;base<n;base+=len){std::int64_t w=1;for(int j=0;j<len/2;j++){auto u=a[base+j],v=a[base+j+len/2]*w%MOD;a[base+j]=(u+v)%MOD;a[base+j+len/2]=(u-v+MOD)%MOD;w=w*step%MOD;}}}
    for(int i=0;i<n;i++){auto x=static_cast<std::uint32_t>(a[i]);for(int b=0;b<4;b++)output[4*i+b]=static_cast<std::uint8_t>(x>>(8*b));}return 4*n;
}
