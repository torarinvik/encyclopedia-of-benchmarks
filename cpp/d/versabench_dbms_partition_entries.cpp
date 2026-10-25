#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_fan = 8;
bool valid_box(const std::int64_t *v, std::size_t at) {
    for (std::size_t d = 0; d < 4; ++d)
        if (v[at+d] < -8 || v[at+d] > 8 || v[at+4+d] < -8 || v[at+4+d] > 8 || v[at+d] >= v[at+4+d]) return false;
    return true;
}
std::int64_t volume_at(const std::int64_t *v, std::size_t at) {
    std::int64_t product=1; for(std::size_t d=0;d<4;++d) product*=v[at+4+d]-v[at+d]; return product;
}
std::int64_t union_volume(const std::int64_t *v,std::size_t left,std::size_t right) {
    std::int64_t product=1;
    for(std::size_t d=0;d<4;++d){const auto lo=std::min(v[left+d],v[right+d]);const auto hi=std::max(v[left+4+d],v[right+4+d]);product*=hi-lo;}
    return product;
}
std::int64_t penalty(const std::int64_t *v,std::size_t seed,std::size_t entry){return union_volume(v,seed,entry)-volume_at(v,seed);}
}

extern "C" std::int64_t versabench_dbms_partition_entries(const std::int64_t *values,std::size_t length){
    if(values==nullptr||length<1||length>74)return -1;
    const auto raw_fan=values[0];if(raw_fan<2||raw_fan>static_cast<std::int64_t>(max_fan))return -1;
    const auto fan=static_cast<std::size_t>(raw_fan),count=fan+1;if(length!=1+8*count)return -1;
    for(std::size_t i=0;i<count;++i)if(!valid_box(values,1+8*i))return -1;
    std::size_t seed_a=0,seed_b=1;auto largest=union_volume(values,1,9);
    for(std::size_t i=0;i<count;++i)for(std::size_t j=i+1;j<count;++j){const auto candidate=union_volume(values,1+8*i,1+8*j);if(candidate>largest){largest=candidate;seed_a=i;seed_b=j;}}
    const auto a_at=1+8*seed_a,b_at=1+8*seed_b;std::size_t size_a=1,size_b=1;std::int64_t mask=std::int64_t{1}<<seed_a;
    for(std::size_t i=0;i<count;++i){if(i==seed_a||i==seed_b)continue;const auto at=1+8*i;
        if(size_a<fan&&size_b<fan){if(penalty(values,a_at,at)<penalty(values,b_at,at)){mask|=std::int64_t{1}<<i;++size_a;}else ++size_b;}
        else if(size_a>=fan&&size_b<fan)++size_b;
        else if(size_b>=fan&&size_a<fan){mask|=std::int64_t{1}<<i;++size_a;}
        else return -1;
    }
    return mask;
}
