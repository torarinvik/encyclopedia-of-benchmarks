// Clean-room TSVC s1213 profile; see package rights note.
#include <cstddef>
#include <cstdint>
static void put64(std::uint8_t*o,std::size_t p,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b);b>>=8;}}
extern "C" std::int64_t tsvc_s1213_ordered_neighbor_array_map(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap){if(!in||len<13||len>129)return -1;auto nr=in[0];if(nr<3||nr>32)return -1;auto n=static_cast<std::size_t>(nr);if(len!=1+4*n)return -1;std::int64_t a[32],b[32],c[32],d[32];for(std::size_t i=0;i<n;++i){auto x=in[1+i],y=in[1+n+i],z=in[1+2*n+i],w=in[1+3*n+i];if(x< -1||x>1||y< -1||y>1||z< -1||z>1||w< -1||w>1)return -1;a[i]=x;b[i]=y;c[i]=z;d[i]=w;}if(!out||cap<16*n)return -2;for(std::size_t i=1;i<n-1;++i){a[i]=b[i-1]+c[i];b[i]=a[i+1]*d[i];}for(std::size_t i=0;i<n;++i){put64(out,8*i,a[i]);put64(out,8*(n+i),b[i]);}return static_cast<std::int64_t>(2*n);}
