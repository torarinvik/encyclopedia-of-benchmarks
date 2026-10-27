#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int K = 16, Q = 16, NN = 2 * K - 1, OUT = 3 + 5 * NN + Q;
struct Node { int bit = -1, left = -1, right = -1, leaves = 1; std::uint32_t key = 0, low = 0, high = 0; };
std::array<std::uint32_t, K> keys{};
std::array<Node, NN> nodes{};
int used_nodes = 0;
int build(int lo, int hi, int width) {
    int id = used_nodes++;
    if (hi - lo == 1) { nodes[id] = Node{-1, -1, -1, 1, keys[lo], keys[lo], keys[lo]}; return id; }
    std::uint32_t diff = keys[lo] ^ keys[hi - 1];
    int bit = width - 1;
    while (((diff >> bit) & 1u) == 0) --bit;
    int split = lo;
    while (split < hi && ((keys[split] >> bit) & 1u) == 0) ++split;
    nodes[id].bit = width - 1 - bit;
    nodes[id].low = keys[lo]; nodes[id].high = keys[hi - 1];
    nodes[id].left = build(lo, split, width);
    nodes[id].right = build(split, hi, width);
    nodes[id].leaves = nodes[nodes[id].left].leaves + nodes[nodes[id].right].leaves;
    return id;
}
int rank_key(std::uint32_t q, int width) {
    int id = 0, rank = 0;
    while (true) {
        if (q < nodes[id].low) return rank;
        if (q > nodes[id].high) return rank + nodes[id].leaves;
        if (nodes[id].bit < 0) return rank;
        int shift = width - 1 - nodes[id].bit;
        if ((q >> shift) & 1u) { rank += nodes[nodes[id].left].leaves; id = nodes[id].right; }
        else id = nodes[id].left;
    }
    return rank;
}
void put(std::uint8_t* out, std::size_t pos, std::int64_t x) {
    auto bits = static_cast<std::uint64_t>(x);
    for (std::size_t b = 0; b < 8; ++b) out[pos+b] = static_cast<std::uint8_t>(bits >> (8*b));
}
}
extern "C" std::int64_t mmpfh_compacted_trie_rank(const std::int64_t* in, std::size_t len,
                                                   std::uint8_t* out, std::size_t cap) {
    if (!in || len < 3 || len > 35) return -1;
    auto w0=in[0], d0=in[1], q0=in[2];
    if (w0<1 || w0>16 || d0<1 || d0>K || q0<1 || q0>Q || len != 3 + static_cast<std::size_t>(d0+q0)) return -1;
    std::uint32_t limit=1u << static_cast<int>(w0);
    for (int i=0;i<d0;++i) { auto x=in[3+i]; if(x<0 || static_cast<std::uint64_t>(x)>=limit || (i && x<=in[2+i])) return -1; keys[i]=static_cast<std::uint32_t>(x); }
    for (int i=0;i<q0;++i) { auto x=in[3+d0+i]; if(x<0 || static_cast<std::uint64_t>(x)>=limit) return -1; }
    used_nodes=0; build(0,static_cast<int>(d0),static_cast<int>(w0));
    std::array<std::int64_t,OUT> staged{}; std::size_t used=0;
    staged[used++]=d0; staged[used++]=used_nodes; staged[used++]=q0;
    for(int i=0;i<used_nodes;++i){ const auto &n=nodes[i]; staged[used++]=n.bit; staged[used++]=n.left; staged[used++]=n.right; staged[used++]=n.low; staged[used++]=n.high; }
    for(int i=0;i<q0;++i) staged[used++]=rank_key(static_cast<std::uint32_t>(in[3+d0+i]),static_cast<int>(w0));
    auto required=used*8; if(!out || cap<required) return -2;
    for(std::size_t i=0;i<used;++i) put(out,i*8,staged[i]);
    return static_cast<std::int64_t>(required);
}
