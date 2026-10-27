#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_N = 3, MAX_M = 3, MAX_CUTS = 45;
int popcount(std::uint64_t x) { int n=0; while(x){x&=x-1;++n;} return n; }
std::uint64_t shift_cut(std::uint64_t cut, int n, int delay) {
    std::uint64_t result=0;
    for(int bit=0;bit<3*n;++bit) if(cut&(std::uint64_t{1}<<bit)) {
        const int node=bit/3, old_delay=bit%3, next=old_delay+delay;
        if(next>2) return UINT64_MAX;
        result |= std::uint64_t{1}<<(3*node+next);
    }
    return result;
}
void add_cut(std::uint64_t cuts[MAX_N][MAX_CUTS], int counts[MAX_N], int node,
             std::uint64_t mask, int k) {
    if(popcount(mask)>k) return;
    for(int i=0;i<counts[node];++i) if(cuts[node][i]==mask) return;
    if(counts[node]<MAX_CUTS) cuts[node][counts[node]++]=mask;
}
void put_i64(std::uint8_t *out, std::size_t word, std::int64_t value) {
    const auto bits=static_cast<std::uint64_t>(value);
    for(std::size_t b=0;b<8;++b) out[word*8+b]=static_cast<std::uint8_t>(bits>>(8*b));
}
}

extern "C" std::int64_t sequential_lut_k_cut_enumeration(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if(input==nullptr || length<3 || length>12) return -1;
    const auto n0=input[0], k0=input[1], m0=input[2];
    if(n0<1||n0>3||k0<1||k0>2||m0<0||m0>3||length!=3+3*static_cast<std::size_t>(m0)) return -1;
    const int n=static_cast<int>(n0), k=static_cast<int>(k0), m=static_cast<int>(m0);
    int eu[MAX_M]{}, ev[MAX_M]{}, ed[MAX_M]{};
    for(int e=0;e<m;++e) {
        const auto u=input[3+3*e],v=input[4+3*e],d=input[5+3*e];
        if(u<0||v<0||u>=v||v>=n||(d!=0&&d!=1)) return -1;
        for(int j=0;j<e;++j) if(eu[j]==u&&ev[j]==v&&ed[j]==d) return -1;
        eu[e]=static_cast<int>(u); ev[e]=static_cast<int>(v); ed[e]=static_cast<int>(d);
    }
    int in_u[MAX_N][MAX_M]{}, in_d[MAX_N][MAX_M]{}, in_count[MAX_N]{};
    for(int e=0;e<m;++e) { const int v=ev[e],x=in_count[v]++; in_u[v][x]=eu[e]; in_d[v][x]=ed[e]; }
    std::uint64_t cuts[MAX_N][MAX_CUTS]{}; int counts[MAX_N]{};
    for(int v=0;v<n;++v) {
        add_cut(cuts,counts,v,std::uint64_t{1}<<(3*v),k);
        if(in_count[v]>0) {
            const int c0=counts[in_u[v][0]];
            const int c1=in_count[v]>1?counts[in_u[v][1]]:1;
            const int c2=in_count[v]>2?counts[in_u[v][2]]:1;
            for(int a=0;a<c0;++a) for(int b=0;b<c1;++b) for(int c=0;c<c2;++c) {
                std::uint64_t merged=shift_cut(cuts[in_u[v][0]][a],n,in_d[v][0]);
                if(in_count[v]>1) merged|=shift_cut(cuts[in_u[v][1]][b],n,in_d[v][1]);
                if(in_count[v]>2) merged|=shift_cut(cuts[in_u[v][2]][c],n,in_d[v][2]);
                if(merged!=UINT64_MAX) add_cut(cuts,counts,v,merged,k);
            }
        }
        for(int i=1;i<counts[v];++i) { auto x=cuts[v][i]; int j=i; while(j>0&&cuts[v][j-1]>x){cuts[v][j]=cuts[v][j-1];--j;} cuts[v][j]=x; }
    }
    std::size_t words=1; for(int v=0;v<n;++v) words+=1+static_cast<std::size_t>(counts[v]);
    const auto bytes=8*words;
    if(output==nullptr||capacity<bytes) return -2;
    put_i64(output,0,n); std::size_t at=1;
    for(int v=0;v<n;++v) { put_i64(output,at++,counts[v]); for(int i=0;i<counts[v];++i) put_i64(output,at++,static_cast<std::int64_t>(cuts[v][i])); }
    return static_cast<std::int64_t>(bytes);
}
