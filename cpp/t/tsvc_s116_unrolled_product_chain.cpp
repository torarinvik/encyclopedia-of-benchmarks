// Clean-room TSVC s116 profile; see package rights note.
#include <cstddef>
#include <cstdint>
static void put64(std::uint8_t*o,std::size_t p,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b);b>>=8;}}
extern "C" std::int64_t tsvc_s116_unrolled_product_chain(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap){if(!in||len<8||len>23)return -1;auto nr=in[0],pr=in[1];if(nr<6||nr>21||(nr-1)%5||pr<1||pr>4)return -1;auto n=static_cast<std::size_t>(nr);if(len!=2+n)return -1;std::int64_t a[21];for(std::size_t k=0;k<n;++k){if(in[2+k]!=-1&&in[2+k]!=1)return -1;a[k]=in[2+k];}if(!out||cap<8*n)return -2;for(std::size_t p=0;p<static_cast<std::size_t>(pr);++p)for(std::size_t i=0;i<n-5;i+=5){a[i]=a[i+1]*a[i];a[i+1]=a[i+2]*a[i+1];a[i+2]=a[i+3]*a[i+2];a[i+3]=a[i+4]*a[i+3];a[i+4]=a[i+5]*a[i+4];}for(std::size_t k=0;k<n;++k)put64(out,8*k,a[k]);return static_cast<std::int64_t>(n);}
