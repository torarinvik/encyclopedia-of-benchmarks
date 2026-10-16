/* Pinned digit-sum sequence with cached decimal-prefix jumps. */
#include <cstdint>
#include <vector>

namespace {
constexpr std::int64_t max_n = 1'000'000'000'000'000;
constexpr std::size_t state_capacity = 32768;
constexpr std::size_t jump_capacity = 131072;
constexpr std::uint64_t table_mask = state_capacity - 1;
struct State { std::int32_t prefix_sum; std::int64_t suffix; std::int32_t head; };
struct Jump { std::int64_t difference, terms; std::int32_t k, next; };
struct Memo {
    std::vector<State> states = std::vector<State>(state_capacity);
    std::vector<Jump> jumps = std::vector<Jump>(jump_capacity);
    std::int32_t jump_count = 0;
    bool failed = false;
    Memo() { for (auto& state : states) state.head = -2; }
};

std::int64_t power10(std::int64_t exponent) { std::int64_t value=1; while (exponent-- > 0) value*=10; return value; }
std::int64_t digit_sum(std::int64_t value) { std::int64_t total=0; while(value>0){total+=value%10;value/=10;} return total; }
std::uint32_t hash_state(std::int64_t prefix_sum, std::int64_t suffix) {
    auto value = static_cast<std::uint64_t>(suffix) ^ (static_cast<std::uint64_t>(prefix_sum) * 0x9e3779b97f4a7c15ULL);
    value ^= value >> 30; value *= 0xbf58476d1ce4e5b9ULL;
    value ^= value >> 27; value *= 0x94d049bb133111ebULL;
    value ^= value >> 31;
    return static_cast<std::uint32_t>(value) & table_mask;
}
std::int32_t find_state(Memo& memo, std::int64_t prefix_sum, std::int64_t suffix) {
    const auto slot = hash_state(prefix_sum, suffix);
    for (std::uint32_t probe=0; probe<state_capacity; ++probe) {
        const auto index = static_cast<std::int32_t>((slot+probe)&table_mask);
        auto& state=memo.states[static_cast<std::size_t>(index)];
        if (state.head == -2) { state={static_cast<std::int32_t>(prefix_sum),suffix,-1}; return index; }
        if (state.prefix_sum==prefix_sum && state.suffix==suffix) return index;
    }
    memo.failed=true; return -1;
}
void add_jump(Memo& memo, std::int32_t state_index, std::int64_t difference, std::int64_t terms, std::int64_t k) {
    if (memo.jump_count >= static_cast<std::int32_t>(jump_capacity)) { memo.failed=true; return; }
    const auto index=memo.jump_count++;
    auto& state=memo.states[static_cast<std::size_t>(state_index)];
    memo.jumps[static_cast<std::size_t>(index)]={difference,terms,static_cast<std::int32_t>(k),state.head};
    state.head=index;
}
void compute(std::int64_t& value, std::int64_t k, std::int64_t index, std::int64_t target,
             std::int64_t& difference_out, std::int64_t& terms_out) {
    const auto start=index, base=power10(k), prefix_sum=digit_sum(value/base);
    auto suffix=value%base; std::int64_t difference=0;
    while(index<target){++index;const auto addend=prefix_sum+digit_sum(suffix);difference+=addend;suffix+=addend;if(suffix>=base)break;}
    value+=difference; difference_out=difference; terms_out=index-start;
}
void next_term(std::int64_t& value, std::int64_t k, std::int64_t index, std::int64_t target,
               Memo& memo, std::int64_t& difference_out, std::int64_t& terms_out) {
    const auto base=power10(k), prefix_sum=digit_sum(value/base), suffix=value%base, max_terms=target-index;
    const auto state_index=find_state(memo,prefix_sum,suffix);
    if(state_index<0){difference_out=0;terms_out=0;return;}
    std::int64_t difference=0,terms=0;std::int32_t best=-1;
    for(auto jump=memo.states[static_cast<std::size_t>(state_index)].head;jump>=0;jump=memo.jumps[static_cast<std::size_t>(jump)].next){
        const auto& entry=memo.jumps[static_cast<std::size_t>(jump)];
        if(entry.k<=k&&entry.terms<=max_terms&&(best<0||entry.terms>memo.jumps[static_cast<std::size_t>(best)].terms))best=jump;
    }
    if(best>=0){const auto& entry=memo.jumps[static_cast<std::size_t>(best)];difference=entry.difference;terms=entry.terms;value+=difference;}
    if(terms>=max_terms||suffix+difference>=base){difference_out=difference;terms_out=terms;return;}
    if(k>2){while(!memo.failed){std::int64_t extra,jumped;next_term(value,k-1,index+terms,target,memo,extra,jumped);difference+=extra;terms+=jumped;if(terms>=max_terms||suffix+difference>=base)break;}}
    else {std::int64_t extra,jumped;compute(value,k,index+terms,target,extra,jumped);difference+=extra;terms+=jumped;}
    if(!memo.failed&&terms<max_terms)add_jump(memo,state_index,difference,terms,k);
    difference_out=difference;terms_out=terms;
}
}

extern "C" std::int64_t problem551(std::int64_t n) {
    if(n<1||n>max_n)return -1;
    Memo memo;std::int64_t value=1,jumped=0;
    while(jumped!=n-1&&!memo.failed){std::int64_t ignored,terms;next_term(value,18,1+jumped,n,memo,ignored,terms);jumped+=terms;}
    return memo.failed?-1:value;
}
