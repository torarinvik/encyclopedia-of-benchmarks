#include <array>
#include <cstddef>
#include <cstdint>
#include <map>

struct MajoritySummary { int64_t value; unsigned count; };
static MajoritySummary combine(MajoritySummary a, MajoritySummary b) {
    if (!a.count) return b;
    if (!b.count) return a;
    if (a.value == b.value) return {a.value,a.count+b.count};
    if (a.count >= b.count) return {a.value,a.count-b.count};
    return {b.value,b.count-a.count};
}
static uint64_t prefix(size_t p) { return p == 64 ? UINT64_MAX : (uint64_t{1} << p)-1; }
extern "C" int64_t dynamic_range_majority(const int64_t *f, size_t length, uint8_t *output, size_t capacity) {
    if (!f || length < 2 || length > 258 || f[0] < 1 || f[0] > 64 || f[1] < 1 || f[1] > 64) return -1;
    const auto n = static_cast<size_t>(f[0]), q = static_cast<size_t>(f[1]);
    if (length != 2+n+3*q) return -1;
    for (size_t i=0; i<n; ++i) if (f[2+i]<0 || f[2+i]>1000000000) return -1;
    size_t queries = 0;
    for (size_t i=0; i<q; ++i) {
        auto op=f[2+n+3*i], a=f[3+n+3*i], b=f[4+n+3*i];
        if (op == 0) { if (a<0 || a>=static_cast<int64_t>(n) || b<0 || b>1000000000) return -1; }
        else if (op == 1) { if (a<0 || a>=b || b>static_cast<int64_t>(n)) return -1; ++queries; }
        else return -1;
    }
    if (!queries) return -1;
    if (!output || capacity<8*queries) return -2;
    std::array<MajoritySummary,128> tree{};
    std::array<int64_t,64> data{};
    std::map<int64_t,uint64_t> masks;
    for (size_t i=0; i<n; ++i) { data[i]=f[2+i]; tree[64+i]={data[i],1}; masks[data[i]] |= uint64_t{1} << i; }
    for (size_t i=63; i>0; --i) tree[i]=combine(tree[2*i],tree[2*i+1]);
    size_t written=0;
    for (size_t i=0; i<q; ++i) {
        auto op=f[2+n+3*i], a=f[3+n+3*i], b=f[4+n+3*i];
        if (op == 0) {
            auto p=static_cast<size_t>(a);
            masks[data[p]] &= ~(uint64_t{1} << p); masks[b] |= uint64_t{1} << p;
            data[p]=b; auto node=64+p; tree[node]={b,1};
            while (node>1) { node/=2; tree[node]=combine(tree[2*node],tree[2*node+1]); }
        } else {
            auto lo=static_cast<size_t>(a), hi=static_cast<size_t>(b), l=64+lo, r=64+hi;
            MajoritySummary x{},y{};
            while (l<r) {
                if (l&1) x=combine(x,tree[l++]);
                if (r&1) y=combine(tree[--r],y);
                l/=2; r/=2;
            }
            auto candidate=combine(x,y);
            uint64_t bits=masks[candidate.value] & (prefix(hi)^prefix(lo));
            unsigned count=0; while (bits) { bits &= bits-1; ++count; }
            int64_t answer=(candidate.count && 2*count>hi-lo) ? candidate.value : -1;
            uint64_t encoded=static_cast<uint64_t>(answer);
            for (size_t byte=0; byte<8; ++byte) output[8*written+byte]=static_cast<uint8_t>(encoded >> (8*byte));
            ++written;
        }
    }
    return static_cast<int64_t>(8*written);
}
