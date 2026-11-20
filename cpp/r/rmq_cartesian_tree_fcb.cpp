#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 64, Q = 64, E = 127, B = 127, L = 8, M = 4;
using Micro = std::array<std::array<std::array<std::uint8_t, M>, M>, 8>;
using Macro = std::array<std::array<std::uint16_t, B>, L>;
std::uint16_t shallower(std::uint16_t a, std::uint16_t b, const std::array<std::uint16_t,E>& d) {
    return d[a] != d[b] ? (d[a] < d[b] ? a : b) : (a < b ? a : b);
}
std::uint16_t rmq(std::size_t a, std::size_t z, std::size_t ec, std::size_t bs,
    const std::array<std::uint16_t,E>& d, const std::array<std::uint8_t,B>& pat,
    const Micro& micro, const Macro& macro, const std::array<std::uint8_t,B+1>& logs) {
    const std::size_t ba=a/bs, bz=z/bs, oa=a%bs, oz=z%bs;
    if (ba==bz) return static_cast<std::uint16_t>(ba*bs+micro[pat[ba]][oa][oz]);
    const std::size_t xa=ba*bs, xz=bz*bs, na=std::min(bs,ec-xa);
    auto best=static_cast<std::uint16_t>(xa+micro[pat[ba]][oa][na-1]);
    best=shallower(best,static_cast<std::uint16_t>(xz+micro[pat[bz]][0][oz]),d);
    if (bz>ba+1) { const auto lo=ba+1, hi=bz-1, k=static_cast<std::size_t>(logs[hi-lo+1]);
        const auto span=std::size_t{1}<<k;
        best=shallower(best,macro[k][lo],d); best=shallower(best,macro[k][hi-span+1],d); }
    return best;
}
}

extern "C" std::int64_t rmq_cartesian_tree_fcb(const std::int64_t* in, std::size_t len,
    std::uint8_t* out, std::size_t cap) noexcept {
    if (!in || len<2 || len>195 || in[0]<1 || in[0]>64 || in[1]<0 || in[1]>64) return -1;
    const auto n=static_cast<std::size_t>(in[0]), q=static_cast<std::size_t>(in[1]), qo=2+n;
    if (len!=2+n+2*q) return -1;
    std::array<std::int64_t,N> val{};
    for (std::size_t i=0;i<n;++i) { val[i]=in[2+i]; if(val[i]<-1000||val[i]>1000)return -1; }
    for(std::size_t i=0;i<q;++i) if(in[qo+2*i]<0||in[qo+2*i]>in[qo+2*i+1]||in[qo+2*i+1]>=static_cast<std::int64_t>(n)) return -1;
    if(!out||cap<q+1)return -2;

    std::array<int,N> left,right,parent,mono;
    left.fill(-1); right.fill(-1); parent.fill(-1);
    std::size_t top=0;
    for(std::size_t i=0;i<n;++i){int last=-1;while(top&&val[mono[top-1]]>val[i])last=mono[--top];
        if(top){int p=mono[top-1];right[p]=static_cast<int>(i);parent[i]=p;}
        if(last>=0){left[i]=last;parent[last]=static_cast<int>(i);} mono[top++]=static_cast<int>(i);}
    int root=0;while(parent[root]>=0)++root;
    std::array<std::uint16_t,E> euler{},depth{},node_depth{},first{};
    std::array<int,N> fn{}; std::array<std::uint8_t,N> fs{};
    std::size_t ec=1, sp=1; euler[0]=static_cast<std::uint16_t>(root); depth[0]=0; first[root]=0; node_depth[root]=0; fn[0]=root;
    while(sp){auto slot=sp-1;int v=fn[slot];
        if(fs[slot]==0){if(left[v]>=0){int c=left[v];fs[slot]=1;node_depth[c]=node_depth[v]+1;first[c]=static_cast<std::uint16_t>(ec);euler[ec]=static_cast<std::uint16_t>(c);depth[ec++]=node_depth[c];fn[sp]=c;fs[sp++]=0;}
            else if(right[v]>=0){int c=right[v];fs[slot]=2;node_depth[c]=node_depth[v]+1;first[c]=static_cast<std::uint16_t>(ec);euler[ec]=static_cast<std::uint16_t>(c);depth[ec++]=node_depth[c];fn[sp]=c;fs[sp++]=0;}else --sp;}
        else if(fs[slot]==1){euler[ec]=static_cast<std::uint16_t>(v);depth[ec++]=node_depth[v];if(right[v]>=0){int c=right[v];fs[slot]=2;node_depth[c]=node_depth[v]+1;first[c]=static_cast<std::uint16_t>(ec);euler[ec]=static_cast<std::uint16_t>(c);depth[ec++]=node_depth[c];fn[sp]=c;fs[sp++]=0;}else --sp;}
        else{euler[ec]=static_cast<std::uint16_t>(v);depth[ec++]=node_depth[v];--sp;}}

    std::size_t lg=0;for(auto x=ec;x>1;x>>=1)++lg;const std::size_t bs=std::max<std::size_t>(1,lg/2), blocks=(ec+bs-1)/bs;
    Micro micro{}; std::array<std::uint8_t,B> pat{}; std::array<std::uint8_t,B+1> logs{}; Macro macro{};
    for(std::size_t s=0;s<(std::size_t{1}<<(bs-1));++s){std::array<int,M> rel{};for(std::size_t j=0;j+1<bs;++j)rel[j+1]=rel[j]+(((s>>j)&1)?1:-1);
        for(std::size_t a=0;a<bs;++a)for(std::size_t z=a;z<bs;++z){auto b=a;for(std::size_t k=a+1;k<=z;++k)if(rel[k]<rel[b])b=k;micro[s][a][z]=static_cast<std::uint8_t>(b);}}
    for(std::size_t b=0;b<blocks;++b){const std::size_t base=b*bs,end=std::min(ec,base+bs); auto best=static_cast<std::uint16_t>(base);
        for(auto j=base;j+1<end;++j){if(depth[j+1]>depth[j])pat[b]|=static_cast<std::uint8_t>(1u<<(j-base));best=shallower(best,static_cast<std::uint16_t>(j+1),depth);}macro[0][b]=best;}
    for(std::size_t c=2;c<=blocks;++c)logs[c]=static_cast<std::uint8_t>(logs[c/2]+1);
    for(std::size_t k=1;(std::size_t{1}<<k)<=blocks&&k<L;++k){auto half=std::size_t{1}<<(k-1),span=2*half;for(std::size_t b=0;b+span<=blocks;++b)macro[k][b]=shallower(macro[k-1][b],macro[k-1][b+half],depth);}
    std::array<std::uint8_t,Q> ans{};
    for(std::size_t i=0;i<q;++i){auto a=static_cast<std::size_t>(first[static_cast<std::size_t>(in[qo+2*i])]),z=static_cast<std::size_t>(first[static_cast<std::size_t>(in[qo+2*i+1])]);auto at=rmq(std::min(a,z),std::max(a,z),ec,bs,depth,pat,micro,macro,logs);ans[i]=static_cast<std::uint8_t>(euler[at]);}
    out[0]=static_cast<std::uint8_t>(q);for(std::size_t i=0;i<q;++i)out[i+1]=ans[i];return static_cast<std::int64_t>(q+1);
}
