// Clean-room TSVC s1111 profile; see package rights note.
#include <cstddef>
#include <cstdint>
static void put64(std::uint8_t* o,std::size_t p,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b&255u);b>>=8;}}
extern "C" std::int64_t tsvc_s1111_stride_two_polynomial_map(const std::int64_t* in,std::size_t len,std::uint8_t* out,std::size_t cap){
 if(!in||len<6||len>161)return -1;if(in[0]<1||in[0]>32)return -1;auto n=static_cast<std::size_t>(in[0]);if(len!=1+5*n)return -1;
 std::int64_t a[64],b[32],c[32],d[32];std::size_t off=1;for(std::size_t i=0;i<2*n;++i){auto x=in[off+i];if(x< -2||x>2)return -1;a[i]=x;}off+=2*n;
 std::int64_t* vecs[3]={b,c,d};for(auto* v:vecs)for(std::size_t i=0;i<n;++i){auto x=in[off++];if(x< -2||x>2)return -1;v[i]=x;}
 auto bytes=16*n;if(!out||cap<bytes)return -2;for(std::size_t i=0;i<n;++i)a[2*i]=c[i]*b[i]+d[i]*b[i]+c[i]*c[i]+d[i]*b[i]+d[i]*c[i];for(std::size_t i=0;i<2*n;++i)put64(out,8*i,a[i]);return static_cast<std::int64_t>(2*n);
}
