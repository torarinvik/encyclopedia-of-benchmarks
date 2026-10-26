// Clean-room TSVC s471 profile; see package rights note.
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_n=32; void put64(std::uint8_t* o,std::size_t p,std::int64_t v){std::uint64_t b=static_cast<std::uint64_t>(v);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b&255u);b>>=8;}} }
extern "C" std::int64_t tsvc_s471_ordered_two_vector_map(const std::int64_t* in,std::size_t len,std::uint8_t* out,std::size_t cap){
 if(!in||len<6||len>130)return -1;
 if(in[0]<1||in[0]>static_cast<std::int64_t>(max_n)||in[1]<1||in[1]>4||len!=2+4*static_cast<std::size_t>(in[0]))return -1;
 const std::size_t n=static_cast<std::size_t>(in[0]),passes=static_cast<std::size_t>(in[1]);double x[max_n],b[max_n],c[max_n],d[max_n],e[max_n];
 for(std::size_t i=0;i<n;++i){auto bv=in[2+i],cv=in[2+n+i],dv=in[2+2*n+i],ev=in[2+3*n+i];if(bv< -2||bv>2||cv< -2||cv>2||dv< -2||dv>2||ev< -2||ev>2)return -1;b[i]=double(bv);c[i]=double(cv);d[i]=double(dv);e[i]=double(ev);}
 const std::size_t bytes=16*n;if(!out||cap<bytes)return -2;
 for(std::size_t p=0;p<passes;++p)for(std::size_t i=0;i<n;++i){x[i]=b[i]+d[i]*d[i];b[i]=c[i]+d[i]*e[i];}
 for(std::size_t i=0;i<n;++i){put64(out,8*i,(std::int64_t)x[i]);put64(out,8*(n+i),(std::int64_t)b[i]);}return static_cast<std::int64_t>(bytes);
}
