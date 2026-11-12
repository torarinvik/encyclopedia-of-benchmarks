#include <stddef.h>
#include <stdint.h>

#define MOD INT64_C(998244353)
#define MAX_N 16u
#define MAX_Q 16u
#define MAX_INPUT 115u
#define NODE_CAP 4096u

typedef struct { int64_t sum, mul, add; int32_t left, right; } Node;

static int64_t norm(int64_t x) { x %= MOD; return x < 0 ? x + MOD : x; }
static int32_t clone_node(Node *a, size_t *used, int32_t src) {
    if (src < 0 || *used >= NODE_CAP) return -1;
    int32_t d = (int32_t)(*used); a[*used] = a[(size_t)src]; ++*used; return d;
}
static int32_t new_node(Node *a, size_t *used, int64_t sum, int32_t l, int32_t r) {
    if (*used >= NODE_CAP) return -1;
    int32_t d = (int32_t)(*used); a[*used] = (Node){sum,1,0,l,r}; ++*used; return d;
}
static void apply(Node *a, int32_t x, int64_t m, int64_t b, size_t len) {
    Node *n=&a[(size_t)x]; m=norm(m); b=norm(b);
    n->sum=norm(m*n->sum+b*(int64_t)len);
    n->mul=norm(m*n->mul); n->add=norm(m*n->add+b);
}
static int push(Node *a, size_t *used, int32_t x, size_t l, size_t r) {
    Node *n=&a[(size_t)x];
    if (n->mul==1 && n->add==0) return 1;
    if (l<r) {
        size_t m=l+(r-l)/2;
        int32_t lc=clone_node(a,used,n->left), rc=clone_node(a,used,n->right);
        if(lc<0||rc<0) return 0;
        n=&a[(size_t)x]; n->left=lc; n->right=rc;
        apply(a,lc,n->mul,n->add,m-l+1); apply(a,rc,n->mul,n->add,r-m);
    }
    a[(size_t)x].mul=1; a[(size_t)x].add=0; return 1;
}
static int32_t build(Node *a,size_t *used,const int64_t *v,size_t l,size_t r) {
    if(l==r) return new_node(a,used,v[l],-1,-1);
    size_t m=l+(r-l)/2; int32_t x=build(a,used,v,l,m), y=build(a,used,v,m+1,r);
    if(x<0||y<0) return -1; return new_node(a,used,norm(a[x].sum+a[y].sum),x,y);
}
static int32_t update(Node *a,size_t *used,int32_t root,size_t l,size_t r,size_t ql,size_t qr,int64_t m,int64_t b) {
    if(ql<=l && r<=qr) { int32_t x=clone_node(a,used,root); if(x<0)return -1; apply(a,x,m,b,r-l+1); return x; }
    int32_t x=clone_node(a,used,root); if(x<0||!push(a,used,x,l,r))return -1;
    size_t mid=l+(r-l)/2;
    if(ql<=mid) { int32_t y=update(a,used,a[x].left,l,mid,ql,qr,m,b); if(y<0)return -1; a[x].left=y; }
    if(qr>mid) { int32_t y=update(a,used,a[x].right,mid+1,r,ql,qr,m,b); if(y<0)return -1; a[x].right=y; }
    a[x].sum=norm(a[a[x].left].sum+a[a[x].right].sum); return x;
}
static int32_t logical_child(Node *a,size_t *used,int32_t src,int right,size_t l,size_t r) {
    int32_t c=clone_node(a,used,right?a[src].right:a[src].left); if(c<0)return -1;
    if(a[src].mul!=1||a[src].add!=0) { size_t m=l+(r-l)/2; if(right) apply(a,c,a[src].mul,a[src].add,r-m); else apply(a,c,a[src].mul,a[src].add,m-l+1); }
    return c;
}
static int32_t copy_range(Node *a,size_t *used,int32_t dst,int32_t src,size_t l,size_t r,size_t ql,size_t qr) {
    if(ql<=l&&r<=qr) return src;
    int32_t x=clone_node(a,used,dst); if(x<0||!push(a,used,x,l,r))return -1;
    size_t mid=l+(r-l)/2;
    if(ql<=mid) { int32_t sc=logical_child(a,used,src,0,l,r); if(sc<0)return -1; int32_t y=copy_range(a,used,a[x].left,sc,l,mid,ql,qr); if(y<0)return -1; a[x].left=y; }
    if(qr>mid) { int32_t sc=logical_child(a,used,src,1,l,r); if(sc<0)return -1; int32_t y=copy_range(a,used,a[x].right,sc,mid+1,r,ql,qr); if(y<0)return -1; a[x].right=y; }
    a[x].sum=norm(a[a[x].left].sum+a[a[x].right].sum); return x;
}
static int64_t query(Node *a,int32_t x,size_t l,size_t r,size_t ql,size_t qr,int64_t cm,int64_t ca) {
    if(ql<=l&&r<=qr) return norm(cm*a[x].sum+ca*(int64_t)(r-l+1));
    size_t mid=l+(r-l)/2; int64_t nm=norm(cm*a[x].mul), na=norm(cm*a[x].add+ca), z=0;
    if(ql<=mid) z=query(a,a[x].left,l,mid,ql,qr,nm,na);
    if(qr>mid) z=norm(z+query(a,a[x].right,mid+1,r,ql,qr,nm,na)); return z;
}
static int valid_ref(int64_t k,size_t i,const int64_t *kinds) { return k==-1 || (k>=0&&(size_t)k<i&&(kinds[(size_t)k]==0||kinds[(size_t)k]==1)); }

int64_t persistent_range_affine_range_sum(const int64_t *in,size_t len,uint8_t *out,size_t cap) {
    if(!in||len<2||len>MAX_INPUT) return -1;
    int64_t n0=in[0],q0=in[1]; if(n0<1||n0>MAX_N||q0<1||q0>MAX_Q)return -1;
    size_t n=(size_t)n0,q=(size_t)q0,off=2+n;
    if(len<off)return -1;
    for(size_t j=0;j<n;j++) if(in[2+j]<0||in[2+j]>=MOD)return -1;
    int64_t kinds[MAX_Q], refs[MAX_Q], srcs[MAX_Q], ls[MAX_Q],rs[MAX_Q],ms[MAX_Q],bs[MAX_Q];
    for(size_t i=0;i<q;i++) {
        if(off>=len)return -1; int64_t op=in[off]; size_t w=op==0?6u:op==1?5u:op==2?4u:0u;
        if(!w||len-off<w)return -1;
        int64_t k=in[off+1]; if(!valid_ref(k,i,kinds))return -1;
        kinds[i]=op; refs[i]=k; srcs[i]=0; ms[i]=1; bs[i]=0;
        if(op==0 || op==2) { ls[i]=in[off+2]; rs[i]=in[off+3]; if(ls[i]<0||rs[i]<=ls[i]||rs[i]>n0)return -1; }
        if(op==0){ms[i]=in[off+4];bs[i]=in[off+5];if(ms[i]<1||ms[i]>=MOD||bs[i]<0||bs[i]>=MOD)return -1;}
        if(op==1){srcs[i]=in[off+2];ls[i]=in[off+3];rs[i]=in[off+4]; if(!valid_ref(srcs[i],i,kinds)||ls[i]<0||rs[i]<=ls[i]||rs[i]>n0)return -1;}
        off+=w;
    }
    if(off!=len)return -1;
    Node nodes[NODE_CAP]; size_t used=0; int32_t roots[MAX_Q]; int64_t answers[MAX_Q]; size_t nq=0;
    int32_t initial=build(nodes,&used,in+2,0,n-1); if(initial<0)return -1;
    for(size_t i=0;i<q;i++) {
        int32_t base=refs[i]<0?initial:roots[(size_t)refs[i]];
        if(kinds[i]==0) { roots[i]=update(nodes,&used,base,0,n-1,(size_t)ls[i],(size_t)rs[i]-1,(size_t)ms[i],bs[i]); if(roots[i]<0)return -1; }
        else if(kinds[i]==1) { int32_t source=srcs[i]<0?initial:roots[(size_t)srcs[i]]; roots[i]=copy_range(nodes,&used,base,source,0,n-1,(size_t)ls[i],(size_t)rs[i]-1); if(roots[i]<0)return -1; }
        else { answers[nq++]=query(nodes,base,0,n-1,(size_t)ls[i],(size_t)rs[i]-1,1,0); }
    }
    size_t bytes=8*nq; if(!out||cap<bytes)return -2;
    for(size_t i=0;i<nq;i++){uint64_t x=(uint64_t)answers[i];for(size_t b=0;b<8;b++)out[8*i+b]=(uint8_t)(x>>(8*b));}
    return (int64_t)bytes;
}
