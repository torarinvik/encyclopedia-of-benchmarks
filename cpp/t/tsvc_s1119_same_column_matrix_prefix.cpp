// Clean-room TSVC s1119 profile; see package rights note.
#include <cstddef>
#include <cstdint>
static void put64(std::uint8_t*o,std::size_t p,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b);b>>=8;}}
extern "C" std::int64_t tsvc_s1119_same_column_matrix_prefix(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap){if(!in||len<10||len>130)return -1;auto nr=in[0],passes=in[1];if(nr<2||nr>8||passes<1||passes>4)return -1;auto n=static_cast<std::size_t>(nr),nn=n*n;if(len!=2+2*nn)return -1;std::int64_t a[64],b[64];for(std::size_t i=0;i<nn;++i){auto x=in[2+i],y=in[2+nn+i];if(x< -1||x>1||y< -1||y>1)return -1;a[i]=x;b[i]=y;}if(!out||cap<8*nn)return -2;for(std::size_t p=0;p<static_cast<std::size_t>(passes);++p)for(std::size_t i=1;i<n;++i)for(std::size_t j=0;j<n;++j)a[i*n+j]=a[(i-1)*n+j]+b[i*n+j];for(std::size_t i=0;i<nn;++i)put64(out,8*i,a[i]);return static_cast<std::int64_t>(nn);}
