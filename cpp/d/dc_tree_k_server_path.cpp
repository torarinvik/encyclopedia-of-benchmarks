#include <cstddef>
#include <cstdint>
namespace {void put_i64(std::uint8_t*out,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;i++)out[i]=static_cast<std::uint8_t>(b>>(8*i));}}
extern "C" std::int64_t dc_tree_k_server_path(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
    if(!input||length<5||length>18)return -1;auto k0=input[0],q0=input[1];if(k0<2||k0>4||q0<1||q0>12)return -1;auto k=static_cast<std::size_t>(k0),q=static_cast<std::size_t>(q0);if(length!=2+k+q)return -1;
    std::int64_t pos[4]{};for(std::size_t i=0;i<k;i++){pos[i]=input[2+i];if(pos[i]<0||pos[i]>15)return -1;}for(std::size_t i=0;i<q;i++)if(input[2+k+i]<0||input[2+k+i]>15)return -1;
    std::int64_t staged[60]{};std::size_t at=0;for(std::size_t r=0;r<q;r++){auto target=input[2+k+r];auto nearest=INT64_MAX;bool active[4]{};std::size_t active_count=0;
        for(std::size_t i=0;i<k;i++){bool first=true;for(std::size_t j=0;j<i;j++)if(pos[j]==pos[i]){first=false;break;}if(first){active[i]=true;active_count++;auto delta=pos[i]>target?pos[i]-target:target-pos[i];if(delta<nearest)nearest=delta;}}
        staged[at++]=nearest*static_cast<std::int64_t>(active_count);for(std::size_t i=0;i<k;i++)if(active[i]){if(pos[i]<target)pos[i]+=nearest;else if(pos[i]>target)pos[i]-=nearest;}for(std::size_t i=0;i<k;i++)staged[at++]=pos[i];}
    auto bytes=8*q*(k+1);if(!output||capacity<bytes)return -2;for(std::size_t i=0;i<at;i++)put_i64(output+8*i,staged[i]);return static_cast<std::int64_t>(bytes);
}
