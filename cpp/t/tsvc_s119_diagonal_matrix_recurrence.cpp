// Clean-room TSVC s119 profile; see package rights note.
#include <cstddef>
#include <cstdint>
namespace {constexpr std::size_t max_side=8,max_cells=64;void put64(std::uint8_t*o,std::size_t p,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b&255u);b>>=8;}}}
extern "C" std::int64_t tsvc_s119_diagonal_matrix_recurrence(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap){
 if(!in||len<10||len>130)return -1;if(in[0]<2||in[0]>static_cast<std::int64_t>(max_side)||in[1]<1||in[1]>4)return -1;auto n=static_cast<std::size_t>(in[0]),passes=static_cast<std::size_t>(in[1]),cells=n*n;if(len!=2+2*cells)return -1;
 std::int64_t a[max_cells],b[max_cells];for(std::size_t i=0;i<cells;++i){auto av=in[2+i],bv=in[2+cells+i];if(av< -2||av>2||bv< -2||bv>2)return -1;a[i]=av;b[i]=bv;}auto bytes=8*cells;if(!out||cap<bytes)return -2;
 for(std::size_t p=0;p<passes;++p)for(std::size_t i=1;i<n;++i)for(std::size_t j=1;j<n;++j)a[i*n+j]=a[(i-1)*n+j-1]+b[i*n+j];for(std::size_t i=0;i<cells;++i)put64(out,8*i,a[i]);return static_cast<std::int64_t>(cells);
}
