#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n=8, max_k=8, max_input=75;
void put64(std::uint8_t *out,std::size_t offset,std::int64_t value){std::uint64_t bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b){out[offset+b]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}}
}

extern "C" std::int64_t radio_network_decay_phase(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity){
    if(input==nullptr||length<3||length>max_input)return -1;
    const auto n64=input[0],k64=input[1],initial=input[2];
    if(n64<2||n64>8||k64<1||k64>8||length!=3+static_cast<std::size_t>(n64)+static_cast<std::size_t>(n64)*static_cast<std::size_t>(k64))return -1;
    const std::size_t n=static_cast<std::size_t>(n64),k=static_cast<std::size_t>(k64);
    const std::uint64_t full=(std::uint64_t{1}<<n)-1U;
    if(initial<=0||(static_cast<std::uint64_t>(initial)&~full)!=0)return -1;
    std::uint64_t adjacency[max_n]{};
    for(std::size_t v=0;v<n;++v){const auto raw=input[3+v];if(raw<0||(static_cast<std::uint64_t>(raw)&~full)!=0||(static_cast<std::uint64_t>(raw)&(std::uint64_t{1}<<v))!=0)return -1;adjacency[v]=static_cast<std::uint64_t>(raw);}
    for(std::size_t u=0;u<n;++u)for(std::size_t v=0;v<n;++v)if(((adjacency[u]>>v)&1U)!=((adjacency[v]>>u)&1U))return -1;
    const std::size_t tape_at=3+n;for(std::size_t i=0;i<n*k;++i)if(input[tape_at+i]!=0&&input[tape_at+i]!=1)return -1;
    if(output==nullptr||capacity<16)return -2;
    std::uint8_t active[max_n]{};for(std::size_t v=0;v<n;++v)active[v]=static_cast<std::uint8_t>((static_cast<std::uint64_t>(initial)>>v)&1U);
    std::uint64_t newly=0;std::int64_t transmissions=0;
    for(std::size_t slot=0;slot<k;++slot){
        for(std::size_t sender=0;sender<n;++sender)if(active[sender])++transmissions;
        for(std::size_t receiver=0;receiver<n;++receiver){if((static_cast<std::uint64_t>(initial)>>receiver)&1U)continue;std::size_t count=0;for(std::size_t sender=0;sender<n;++sender)if(active[sender]&&((adjacency[sender]>>receiver)&1U))++count;if(count==1)newly|=std::uint64_t{1}<<receiver;}
        for(std::size_t sender=0;sender<n;++sender)if(active[sender]&&(input[tape_at+sender*k+slot]==0||slot+1==k))active[sender]=0;
    }
    std::uint8_t staged[16];put64(staged,0,static_cast<std::int64_t>(newly));put64(staged,8,transmissions);for(std::size_t i=0;i<16;++i)output[i]=staged[i];return 16;
}
