// Clean-room TSVC s115 profile; see package rights note.
#include <cstddef>
#include <cstdint>
static void put64(std::uint8_t*o,std::size_t p,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b);b>>=8;}}
extern "C" std::int64_t tsvc_s115_upper_triangular_saxpy_elimination(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap){if(!in||len<8||len>58)return -1;if(in[0]<2||in[0]>8||in[1]<1||in[1]>4)return -1;auto n=static_cast<std::size_t>(in[0]),passes=static_cast<std::size_t>(in[1]);if(len!=2+n+n*n)return -1;std::int64_t a[8],m[64];for(std::size_t i=0;i<n;++i){auto x=in[2+i];if(x< -1||x>1)return -1;a[i]=x;}for(std::size_t i=0;i<n*n;++i){auto x=in[2+n+i];if(x< -1||x>1)return -1;m[i]=x;}if(!out||cap<8*n)return -2;for(std::size_t p=0;p<passes;++p)for(std::size_t j=0;j<n;++j)for(std::size_t i=j+1;i<n;++i)a[i]-=m[j*n+i]*a[j];for(std::size_t i=0;i<n;++i)put64(out,8*i,a[i]);return static_cast<std::int64_t>(n);}
