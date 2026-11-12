#include <cstddef>
#include <cstdint>
namespace {
constexpr int MAX_P=32,MAX_K=3,MAX_INPUT=70,MAX_OUTPUT=256;
bool is_prime(int p){if(p<2)return false;for(int d=2;d*d<=p;++d)if(p%d==0)return false;return true;}
void store_le(std::uint8_t *out,std::size_t at,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b){out[at+b]=static_cast<std::uint8_t>(bits&255u);bits>>=8;}}
}
extern "C" std::int64_t multivariate_convolution_cyclic(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity){
    if(!input||length<2||length>MAX_INPUT)return -1;auto p0=input[0],k0=input[1];if(p0<2||p0>97||!is_prime(static_cast<int>(p0))||k0<0||k0>MAX_K)return -1;
    const auto p=static_cast<std::size_t>(p0),k=static_cast<std::size_t>(k0);if(length<2+k)return -1;std::size_t dims[MAX_K]{},product=1;
    for(std::size_t axis=0;axis<k;++axis){auto d0=input[2+axis];if(d0<2||d0>MAX_P||(p-1)%static_cast<std::size_t>(d0)!=0||product>MAX_P/static_cast<std::size_t>(d0))return -1;dims[axis]=static_cast<std::size_t>(d0);product*=dims[axis];}
    const auto start=2+k;if(length!=start+2*product)return -1;for(std::size_t q=start;q<length;++q)if(input[q]<0||input[q]>=p0)return -1;
    const auto bytes=8*product;if(bytes>MAX_OUTPUT)return -1;if(!output||capacity<bytes)return -2;
    std::int64_t a[MAX_P]{},b[MAX_P]{},result[MAX_P]{};for(std::size_t i=0;i<product;++i){a[i]=input[start+i];b[i]=input[start+product+i];}
    for(std::size_t i=0;i<product;++i)for(std::size_t j=0;j<product;++j){std::size_t target=0,stride=1;for(std::size_t axis=0;axis<k;++axis){const auto d=dims[axis],sum=((i/stride)%d+(j/stride)%d)%d;target+=sum*stride;stride*=d;}result[target]=(result[target]+a[i]*b[j])%p0;}
    for(std::size_t i=0;i<product;++i)store_le(output,8*i,result[i]);return static_cast<std::int64_t>(bytes);
}
