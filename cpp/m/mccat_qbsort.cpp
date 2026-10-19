#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 32;
void bubble(std::int32_t *a, std::size_t n) {
    for (std::size_t end=n; end>1; --end) for (std::size_t i=0; i+1<end; ++i)
        if (a[i+1]<a[i]) { auto t=a[i]; a[i]=a[i+1]; a[i+1]=t; }
}
void quick(std::int32_t *a, std::size_t n) {
    if (n<2) return;
    const auto pivot=a[0]; std::int32_t lower[MAX_ITEMS], upper[MAX_ITEMS]; std::size_t nl=0,nu=0;
    for (std::size_t i=1;i<n;++i) { if (a[i]<pivot) lower[nl++]=a[i]; else upper[nu++]=a[i]; }
    quick(upper,nu); quick(lower,nl); std::size_t k=0;
    for (std::size_t i=0;i<nl;++i) a[k++]=lower[i]; a[k++]=pivot;
    for (std::size_t i=0;i<nu;++i) a[k++]=upper[i];
}
}
extern "C" std::int64_t mccat_qbsort(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length<3 || length>2+MAX_ITEMS) return -1;
    auto mode=input[0], cv=input[1]; if ((mode!=0&&mode!=1)||cv<1||cv>static_cast<std::int64_t>(MAX_ITEMS)) return -1;
    auto n=static_cast<std::size_t>(cv); if(length!=n+2) return -1;
    std::int32_t a[MAX_ITEMS];
    for(std::size_t i=0;i<n;++i){if(input[i+2]<INT32_MIN||input[i+2]>INT32_MAX)return -1;a[i]=static_cast<std::int32_t>(input[i+2]);}
    for(int pass=0;pass<1000;++pass){for(std::size_t i=0;i<n;++i)a[i]=static_cast<std::int32_t>(input[i+2]);if(mode==0)bubble(a,n);else quick(a,n);}
    const auto need=4*n; if(!output||capacity<need)return -2;
    for(std::size_t i=0;i<n;++i){auto bits=static_cast<std::uint32_t>(a[i]);for(std::size_t b=0;b<4;++b)output[4*i+b]=static_cast<std::uint8_t>(bits>>(8*b));}
    return static_cast<std::int64_t>(need);
}
