#include <cstddef>
#include <cstdint>
namespace {
void put_i64(std::uint8_t* out,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;b++)out[b]=static_cast<std::uint8_t>(bits>>(8*b));}
}
extern "C" std::int64_t counting_triangles_stream_reservoir(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(!input||length<6||length>114)return -1;
    auto n0=input[0],m0=input[1];if(n0<2||n0>8||m0<1||m0>28||length!=2+4*static_cast<std::size_t>(m0))return -1;
    auto n=static_cast<std::size_t>(n0),m=static_cast<std::size_t>(m0);bool seen[8][8]{};std::int64_t edges[28][2]{};
    for(std::size_t i=0;i<m;i++){auto u=input[2+2*i],v=input[3+2*i];if(u<0||v<=u||v>=n0||seen[u][v])return -1;seen[u][v]=seen[v][u]=true;edges[i][0]=u;edges[i][1]=v;}
    auto base=2+2*m;for(std::size_t t=1;t<=m;t++)for(std::size_t s=0;s<2;s++){auto r=input[base+2*(t-1)+s];if(r<0||r>=static_cast<std::int64_t>(t))return -1;}
    std::int64_t slots[2][2]={{-1,-1},{-1,-1}},staged[112]{};std::size_t at=0;
    for(std::size_t t=1;t<=m;t++){for(std::size_t s=0;s<2;s++)if(input[base+2*(t-1)+s]==0){slots[s][0]=edges[t-1][0];slots[s][1]=edges[t-1][1];}for(std::size_t s=0;s<2;s++){staged[at++]=slots[s][0];staged[at++]=slots[s][1];}}
    auto bytes=16*m;if(!output||capacity<bytes)return -2;for(std::size_t i=0;i<at;i++)put_i64(output+8*i,staged[i]);return static_cast<std::int64_t>(bytes);
}
