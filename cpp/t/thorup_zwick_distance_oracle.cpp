#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t N = 12, M = 66, Q = 32, MAX_INPUT = 266;
constexpr std::int64_t INF = INT64_C(0x3fffffffffffffff);
void put64(std::uint8_t *out, std::size_t at, std::int64_t x) {
    auto bits = static_cast<std::uint64_t>(x);
    for (unsigned b = 0; b < 8; ++b) out[at + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t thorup_zwick_distance_oracle(const std::int64_t *in, std::size_t len,
                                                        std::uint8_t *out, std::size_t cap) {
    if (!in || len < 4 || len > MAX_INPUT) return -1;
    if (in[0] < 1 || in[0] > static_cast<std::int64_t>(N) || in[1] < 0 || in[1] > static_cast<std::int64_t>(M)) return -1;
    const int n = static_cast<int>(in[0]), m = static_cast<int>(in[1]);
    const std::uint64_t mask = static_cast<std::uint64_t>(in[2]);
    if (in[2] <= 0 || (mask >> n) != 0) return -1;
    const std::size_t q_at = 3 + 3 * static_cast<std::size_t>(m);
    if (q_at >= len || in[q_at] < 0 || in[q_at] > static_cast<std::int64_t>(Q)) return -1;
    const int q = static_cast<int>(in[q_at]);
    if (len != q_at + 1 + 2 * static_cast<std::size_t>(q)) return -1;
    std::array<std::array<std::int64_t,N>,N> d{};
    for (int i=0;i<n;++i) for(int j=0;j<n;++j) d[i][j]=(i==j?0:INF);
    for(int e=0;e<m;++e){
        auto u=in[3+3*e],v=in[4+3*e],w=in[5+3*e];
        if(u<0||v<=u||v>=n||w<1||w>1000||d[u][v]!=INF)return -1;
        d[u][v]=d[v][u]=w;
    }
    for(int k=0;k<n;++k)for(int i=0;i<n;++i)for(int j=0;j<n;++j)
        if(d[i][k]!=INF&&d[k][j]!=INF&&d[i][k]+d[k][j]<d[i][j])d[i][j]=d[i][k]+d[k][j];
    for(int i=0;i<n;++i)for(int j=0;j<n;++j)if(d[i][j]==INF)return -1;
    std::array<int,N> nearest{}; std::array<std::int64_t,N> near_d{};
    for(int v=0;v<n;++v){nearest[v]=-1;near_d[v]=INF;for(int a=0;a<n;++a)if((mask>>a)&1u)
        if(d[v][a]<near_d[v]||(d[v][a]==near_d[v]&&(nearest[v]<0||a<nearest[v]))){nearest[v]=a;near_d[v]=d[v][a];}}
    std::array<std::array<bool,N>,N> bunch{};
    for(int u=0;u<n;++u)for(int x=0;x<n;++x)bunch[u][x]=((mask>>x)&1u)||d[u][x]<near_d[u];
    std::array<std::int64_t,Q+1> staged{}; staged[0]=q;
    for(int z=0;z<q;++z){
        auto a=in[q_at+1+2*z],b=in[q_at+2+2*z]; if(a<0||a>=n||b<0||b>=n)return -1;
        int u=static_cast<int>(a),v=static_cast<int>(b); bool found=false;
        for(int level=0;level<2;++level){int pivot=level==0?v:nearest[v];if(bunch[u][pivot]){staged[z+1]=d[u][pivot]+d[v][pivot];found=true;break;}std::swap(u,v);}
        if(!found)return -1;
    }
    const std::size_t bytes=8u*static_cast<std::size_t>(q+1); if(!out||cap<bytes)return -2;
    for(std::size_t i=0;i<static_cast<std::size_t>(q+1);++i)put64(out,8*i,staged[i]);
    return static_cast<std::int64_t>(bytes);
}
