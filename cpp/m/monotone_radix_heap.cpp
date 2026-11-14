#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>
#include <vector>

namespace {
unsigned bucket_of(std::uint32_t key, std::uint32_t last) {
    auto difference=key^last;
    unsigned bits=0;
    while (difference) { ++bits; difference>>=1; }
    return bits;
}
}

extern "C" std::int64_t monotone_radix_heap(const std::int64_t* input, std::size_t length) {
    if (!input || length<1 || length>130 || input[0]<0 || input[0]>64) return -1;
    const auto q=static_cast<std::size_t>(input[0]);
    if (length!=1+2*q) return -1;
    std::array<std::vector<std::uint32_t>,32> buckets;
    std::uint32_t last=0;
    std::int64_t count=0,result=0;
    for (std::size_t i=0; i<q; ++i) {
        const auto op=input[1+2*i], key=input[2+2*i];
        if (op==0) {
            if (key<static_cast<std::int64_t>(last) || key>2147483647) return -1;
            const auto value=static_cast<std::uint32_t>(key);
            buckets[bucket_of(value,last)].push_back(value);
        } else if (op==1 && key==0) {
            if (buckets[0].empty()) {
                std::size_t index=1;
                while (index<32 && buckets[index].empty()) ++index;
                if (index==32) return -1;
                last=*std::min_element(buckets[index].begin(),buckets[index].end());
                auto pending=std::move(buckets[index]);
                buckets[index].clear();
                for (auto value:pending) buckets[bucket_of(value,last)].push_back(value);
            }
            const auto value=buckets[0].back(); buckets[0].pop_back();
            result+=(++count)*value;
        } else return -1;
    }
    return result;
}
