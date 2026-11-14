#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
struct Tree {
    std::array<int64_t,256> minimum{},lazy{};
    void build(const int64_t *v,int node,int l,int r) {
        if (r-l==1) { minimum[node]=v[l]; return; }
        int m=(l+r)/2; build(v,2*node,l,m); build(v,2*node+1,m,r);
        minimum[node]=std::min(minimum[2*node],minimum[2*node+1]);
    }
    void push(int node) {
        for (int c=2*node;c<=2*node+1;++c) { minimum[c]+=lazy[node]; lazy[c]+=lazy[node]; }
        lazy[node]=0;
    }
    void add(int node,int l,int r,int ql,int qr,int64_t delta) {
        if (qr<=l || r<=ql) return;
        if (ql<=l && r<=qr) { minimum[node]+=delta; lazy[node]+=delta; return; }
        push(node); int m=(l+r)/2;
        add(2*node,l,m,ql,qr,delta); add(2*node+1,m,r,ql,qr,delta);
        minimum[node]=std::min(minimum[2*node],minimum[2*node+1]);
    }
    int64_t query(int node,int l,int r,int ql,int qr) {
        if (qr<=l || r<=ql) return std::numeric_limits<int64_t>::max();
        if (ql<=l && r<=qr) return minimum[node];
        push(node); int m=(l+r)/2;
        auto left=query(2*node,l,m,ql,qr); auto right=query(2*node+1,m,r,ql,qr);
        return std::min(left,right);
    }
};
extern "C" int64_t range_add_range_min(const int64_t *f,size_t length,uint8_t *output,size_t capacity) {
    if (!f || length<2 || length>322 || f[0]<1 || f[0]>64 || f[1]<1 || f[1]>64) return -1;
    int n=static_cast<int>(f[0]), q=static_cast<int>(f[1]), queries=0;
    if (length!=2+static_cast<size_t>(n)+4*static_cast<size_t>(q)) return -1;
    for (int i=0;i<n;++i) if (f[2+i]<-1000000 || f[2+i]>1000000) return -1;
    for (int i=0;i<q;++i) {
        int b=2+n+4*i; auto op=f[b], l=f[b+1], r=f[b+2], d=f[b+3];
        if (l<0 || l>=r || r>n) return -1;
        if (op==0) { if (d < -100000 || d > 100000) return -1; }
        else if (op==1) { if (d!=0) return -1; ++queries; }
        else return -1;
    }
    if (!queries) return -1;
    if (!output || capacity<8*static_cast<size_t>(queries)) return -2;
    Tree tree; tree.build(f+2,1,0,n); int written=0;
    for (int i=0;i<q;++i) {
        int b=2+n+4*i, l=static_cast<int>(f[b+1]), r=static_cast<int>(f[b+2]);
        if (f[b]==0) tree.add(1,0,n,l,r,f[b+3]);
        else {
            auto bits=static_cast<uint64_t>(tree.query(1,0,n,l,r));
            for (size_t byte=0;byte<8;++byte) output[8*static_cast<size_t>(written)+byte]=static_cast<uint8_t>(bits >> (8*byte));
            ++written;
        }
    }
    return 8*written;
}
