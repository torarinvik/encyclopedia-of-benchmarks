#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t MAX_TARGET=6, MAX_WORDS=4, MAX_WAYS=4096; }
extern "C" std::int64_t all_construct(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(input==nullptr||length<2||input[0]<0||input[0]>static_cast<std::int64_t>(MAX_TARGET))return -1;
    const auto n=static_cast<std::size_t>(input[0]);for(std::size_t i=0;i<n;++i)if(input[i+1]<'a'||input[i+1]>'z')return -1;
    const auto wc_slot=1+n;if(wc_slot>=length||input[wc_slot]<0||input[wc_slot]>static_cast<std::int64_t>(MAX_WORDS))return -1;
    const auto words=static_cast<std::size_t>(input[wc_slot]);std::size_t cursor=wc_slot+1;
    std::size_t starts[MAX_WORDS]={},word_lengths[MAX_WORDS]={};
    for(std::size_t w=0;w<words;++w){if(cursor>=length||input[cursor]<1||input[cursor]>static_cast<std::int64_t>(MAX_TARGET))return -1;const auto wl=static_cast<std::size_t>(input[cursor++]);if(cursor+wl>length)return -1;starts[w]=cursor;word_lengths[w]=wl;for(std::size_t j=0;j<wl;++j)if(input[cursor+j]<'a'||input[cursor+j]>'z')return -1;cursor+=wl;}
    if(cursor!=length)return -1;
    std::uint8_t paths[MAX_TARGET+1][MAX_WAYS][MAX_TARGET]={};std::uint8_t path_lengths[MAX_TARGET+1][MAX_WAYS]={};std::size_t counts[MAX_TARGET+1]={};counts[0]=1;
    for(std::size_t pos=0;pos<n;++pos)for(std::size_t w=0;w<words;++w){const auto wl=word_lengths[w];if(wl>n-pos)continue;std::size_t j=0;while(j<wl&&input[pos+1+j]==input[starts[w]+j])++j;if(j!=wl)continue;const auto end=pos+wl;for(std::size_t r=0;r<counts[pos];++r){const auto dest=counts[end]++;if(dest>=MAX_WAYS)return -1;const auto plen=path_lengths[pos][r];for(std::size_t k=0;k<plen;++k)paths[end][dest][k]=paths[pos][r][k];paths[end][dest][plen]=static_cast<std::uint8_t>(w);path_lengths[end][dest]=static_cast<std::uint8_t>(plen+1);}}
    std::size_t required=0;for(std::size_t r=0;r<counts[n];++r){required+=1;for(std::size_t k=0;k<path_lengths[n][r];++k){const auto w=paths[n][r][k];required+=1+word_lengths[w];}}if(capacity<required||(required!=0&&output==nullptr))return -2;
    std::size_t written=0;for(std::size_t r=0;r<counts[n];++r){const auto plen=path_lengths[n][r];output[written++]=plen;for(std::size_t k=0;k<plen;++k){const auto w=paths[n][r][k];output[written++]=static_cast<std::uint8_t>(word_lengths[w]);for(std::size_t j=0;j<word_lengths[w];++j)output[written++]=static_cast<std::uint8_t>(input[starts[w]+j]);}}return static_cast<std::int64_t>(counts[n]);
}
