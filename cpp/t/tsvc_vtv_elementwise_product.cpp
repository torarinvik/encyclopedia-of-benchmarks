// Clean-room implementation of TSVC vtv; see package rights note.
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_n=32; void store_i64_le(std::uint8_t* o,std::size_t p,std::int64_t v){std::uint64_t b=static_cast<std::uint64_t>(v);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b&255u);b>>=8;}} }
extern "C" std::int64_t tsvc_vtv_elementwise_product(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
 if(!input||length<4||length>66)return -1;
 if(input[0]<1||input[0]>static_cast<std::int64_t>(max_n)||input[1]<1||input[1]>8||length!=2+2*static_cast<std::size_t>(input[0]))return -1;
 const std::size_t n=static_cast<std::size_t>(input[0]),passes=static_cast<std::size_t>(input[1]);double a[max_n],b[max_n];
 for(std::size_t i=0;i<n;++i){auto av=input[2+i],bv=input[2+n+i];if(av< -2||av>2||bv< -2||bv>2)return -1;a[i]=static_cast<double>(av);b[i]=static_cast<double>(bv);}
 const std::size_t bytes=8*n;if(!output||capacity<bytes)return -2;
 for(std::size_t p=0;p<passes;++p)for(std::size_t i=0;i<n;++i)a[i]*=b[i];
 for(std::size_t i=0;i<n;++i)store_i64_le(output,8*i,static_cast<std::int64_t>(a[i]));return static_cast<std::int64_t>(bytes);
}
