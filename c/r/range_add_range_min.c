#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t minimum[256], lazy[256]; } Tree;
static void build(Tree *t, const int64_t *values, int node, int l, int r) {
    if (r-l==1) { t->minimum[node]=values[l]; return; }
    int m=(l+r)/2;
    build(t,values,2*node,l,m); build(t,values,2*node+1,m,r);
    int64_t a=t->minimum[2*node], b=t->minimum[2*node+1];
    t->minimum[node]=a<b?a:b;
}
static void push(Tree *t, int node) {
    for (int child=2*node;child<=2*node+1;++child) {
        t->minimum[child]+=t->lazy[node]; t->lazy[child]+=t->lazy[node];
    }
    t->lazy[node]=0;
}
static void add(Tree *t, int node, int l, int r, int ql, int qr, int64_t delta) {
    if (qr<=l || r<=ql) return;
    if (ql<=l && r<=qr) { t->minimum[node]+=delta; t->lazy[node]+=delta; return; }
    push(t,node);
    int m=(l+r)/2;
    add(t,2*node,l,m,ql,qr,delta); add(t,2*node+1,m,r,ql,qr,delta);
    int64_t a=t->minimum[2*node], b=t->minimum[2*node+1];
    t->minimum[node]=a<b?a:b;
}
static int64_t query(Tree *t, int node, int l, int r, int ql, int qr) {
    if (qr<=l || r<=ql) return INT64_MAX;
    if (ql<=l && r<=qr) return t->minimum[node];
    push(t,node);
    int m=(l+r)/2;
    int64_t a=query(t,2*node,l,m,ql,qr), b=query(t,2*node+1,m,r,ql,qr);
    return a<b?a:b;
}
int64_t range_add_range_min(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    if (!input || length<2 || length>322 || input[0]<1 || input[0]>64 || input[1]<1 || input[1]>64) return -1;
    int n=(int)input[0], q=(int)input[1], queries=0;
    if (length != 2+(size_t)n+4*(size_t)q) return -1;
    for (int i=0;i<n;++i) if (input[2+i]<-1000000 || input[2+i]>1000000) return -1;
    for (int i=0;i<q;++i) {
        size_t b=2+(size_t)n+4*(size_t)i;
        int64_t op=input[b], l=input[b+1], r=input[b+2], delta=input[b+3];
        if (l<0 || l>=r || r>n) return -1;
        if (op==0) { if (delta < -100000 || delta > 100000) return -1; }
        else if (op==1) { if (delta!=0) return -1; ++queries; }
        else return -1;
    }
    if (!queries) return -1;
    if (!output || capacity<8*(size_t)queries) return -2;
    Tree t={0}; build(&t,input+2,1,0,n);
    int written=0;
    for (int i=0;i<q;++i) {
        size_t b=2+(size_t)n+4*(size_t)i;
        int l=(int)input[b+1], r=(int)input[b+2];
        if (input[b]==0) add(&t,1,0,n,l,r,input[b+3]);
        else {
            uint64_t bits=(uint64_t)query(&t,1,0,n,l,r);
            for (size_t byte=0;byte<8;++byte) output[8*(size_t)written+byte]=(uint8_t)(bits >> (8*byte));
            ++written;
        }
    }
    return 8*written;
}
