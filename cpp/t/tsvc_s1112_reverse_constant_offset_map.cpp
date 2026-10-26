// Clean-room TSVC s1112 profile; see package rights note.
#include <cstddef>
#include <cstdint>
static void put64(std::uint8_t*o,std::size_t p,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b);b>>=8;}}
extern "C" std::int64_t tsvc_s1112_reverse_constant_offset_map(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap){if(!in||len<3||len>129)return -1;if(in[0]<1||in[0]>64)return -1;auto n=static_cast<std::size_t>(in[0]);if(len!=1+2*n)return -1;std::int64_t a[64],b[64];for(std::size_t i=0;i<n;++i){auto x=in[1+i],y=in[1+n+i];if(x< -2||x>2||y< -2||y>2)return -1;a[i]=x;b[i]=y;}if(!out||cap<8*n)return -2;for(std::size_t i=n;i-- >0;)a[i]=b[i]+1;for(std::size_t i=0;i<n;++i)put64(out,8*i,a[i]);return static_cast<std::int64_t>(n);}
