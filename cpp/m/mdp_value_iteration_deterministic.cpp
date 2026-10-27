#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t MAX_STATES=4,MAX_ACTIONS=3,MAX_INPUT=29,MAX_OUTPUT=72;
void put64(std::uint8_t*out,std::size_t at,std::int64_t value){std::uint64_t bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b){out[at+b]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}}
}

extern "C" std::int64_t mdp_value_iteration_deterministic(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
    if(input==nullptr||length<7||length>MAX_INPUT)return -1;
    const auto s64=input[0],a64=input[1],h64=input[2],p=input[3],q=input[4];
    if(s64<1||s64>static_cast<std::int64_t>(MAX_STATES)||a64<1||a64>static_cast<std::int64_t>(MAX_ACTIONS)||h64<1||h64>8||q<1||q>4||p<0||p>=q||length!=5+2*static_cast<std::size_t>(s64)*static_cast<std::size_t>(a64))return -1;
    const std::size_t states=static_cast<std::size_t>(s64),actions=static_cast<std::size_t>(a64),horizon=static_cast<std::size_t>(h64);
    std::int64_t reward[MAX_STATES][MAX_ACTIONS]{},target[MAX_STATES][MAX_ACTIONS]{};std::size_t at=5;
    for(std::size_t s=0;s<states;++s)for(std::size_t a=0;a<actions;++a){const auto r=input[at++],next=input[at++];if(r< -100||r>100||next<0||next>=s64)return -1;reward[s][a]=r;target[s][a]=next;}
    std::int64_t scale=1;for(std::size_t i=0;i<horizon;++i)scale*=q;
    std::int64_t value[MAX_STATES]{},next_value[MAX_STATES]{},policy[MAX_STATES]{};
    for(std::size_t step=0;step<horizon;++step){for(std::size_t s=0;s<states;++s){auto best=std::numeric_limits<std::int64_t>::min();std::size_t best_action=0;for(std::size_t a=0;a<actions;++a){const auto candidate=reward[s][a]*scale+p*(value[static_cast<std::size_t>(target[s][a])]/q);if(candidate>best){best=candidate;best_action=a;}}next_value[s]=best;policy[s]=static_cast<std::int64_t>(best_action);}for(std::size_t s=0;s<states;++s)value[s]=next_value[s];}
    const std::size_t bytes=8*(1+2*states);if(output==nullptr||capacity<bytes)return -2;std::uint8_t staged[MAX_OUTPUT];put64(staged,0,scale);for(std::size_t s=0;s<states;++s)put64(staged,8*(1+s),value[s]);for(std::size_t s=0;s<states;++s)put64(staged,8*(1+states+s),policy[s]);for(std::size_t b=0;b<bytes;++b)output[b]=staged[b];return static_cast<std::int64_t>(bytes);
}
