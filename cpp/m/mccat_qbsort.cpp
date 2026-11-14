#include <cstddef>
#include <cstdint>
#include <forward_list>
#include <iterator>

namespace {
constexpr std::size_t MAX_ITEMS = 32;
void bubble(std::int32_t *a, std::size_t n) {
    for (std::size_t end=n; end>1; --end) for (std::size_t i=0; i+1<end; ++i)
        if (a[i+1]<a[i]) { auto t=a[i]; a[i]=a[i+1]; a[i+1]=t; }
}
std::forward_list<std::int32_t> quick(const std::forward_list<std::int32_t>& items) {
    if (items.empty()) return {};
    const auto pivot = items.front();
    std::forward_list<std::int32_t> lower, upper;
    for (auto it = std::next(items.begin()); it != items.end(); ++it) {
        if (*it < pivot) lower.push_front(*it);
        else upper.push_front(*it);
    }
    auto sorted_upper = quick(upper);
    auto sorted_lower = quick(lower);
    auto tail = sorted_lower.before_begin();
    for (auto it = sorted_lower.begin(); it != sorted_lower.end(); ++it) ++tail;
    tail = sorted_lower.insert_after(tail, pivot);
    sorted_lower.splice_after(tail, sorted_upper);
    return sorted_lower;
}
}
extern "C" std::int64_t mccat_qbsort(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length<3 || length>2+MAX_ITEMS) return -1;
    auto mode=input[0], cv=input[1]; if ((mode!=0&&mode!=1)||cv<1||cv>static_cast<std::int64_t>(MAX_ITEMS)) return -1;
    auto n=static_cast<std::size_t>(cv); if(length!=n+2) return -1;
    std::int32_t a[MAX_ITEMS];
    for(std::size_t i=0;i<n;++i){if(input[i+2]<INT32_MIN||input[i+2]>INT32_MAX)return -1;a[i]=static_cast<std::int32_t>(input[i+2]);}
    for(int pass=0;pass<1000;++pass){
        for(std::size_t i=0;i<n;++i)a[i]=static_cast<std::int32_t>(input[i+2]);
        if(mode==0) bubble(a,n);
        else {
            std::forward_list<std::int32_t> items;
            for(std::size_t i=n;i>0;--i) items.push_front(a[i-1]);
            const auto sorted=quick(items);
            std::size_t i=0;
            for(auto value:sorted) a[i++]=value;
        }
    }
    const auto need=4*n; if(!output||capacity<need)return -2;
    for(std::size_t i=0;i<n;++i){auto bits=static_cast<std::uint32_t>(a[i]);for(std::size_t b=0;b<4;++b)output[4*i+b]=static_cast<std::uint8_t>(bits>>(8*b));}
    return static_cast<std::int64_t>(need);
}
