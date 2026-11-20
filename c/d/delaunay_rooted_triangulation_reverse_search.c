#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_D = 20, MAX_STATES = 132, MAX_INPUT = 29 };
typedef struct { int64_t x, y; } Point;
typedef struct { int u, v; } Diagonal;
typedef struct { int n, d; Point p[MAX_N]; Diagonal diag[MAX_D]; } Context;

static int64_t orient(Point a, Point b, Point c) {
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
}
static int64_t incircle(Point a, Point b, Point c, Point d) {
    const int64_t ax=a.x-d.x, ay=a.y-d.y, bx=b.x-d.x, by=b.y-d.y, cx=c.x-d.x, cy=c.y-d.y;
    const int64_t al=ax*ax+ay*ay, bl=bx*bx+by*by, cl=cx*cx+cy*cy;
    return al*(bx*cy-by*cx) - bl*(ax*cy-ay*cx) + cl*(ax*by-ay*bx);
}
static int is_boundary(int n, int u, int v) { return v==u+1 || (u==0 && v==n-1); }
static int diagonal_index(const Context *c, int u, int v) {
    for (int i=0;i<c->d;i++) if (c->diag[i].u==u && c->diag[i].v==v) return i;
    return -1;
}
static int crosses(Diagonal a, Diagonal b) {
    return (a.u<b.u && b.u<a.v && a.v<b.v) || (b.u<a.u && a.u<b.v && b.v<a.v);
}
static void adjacency(const Context *c, uint32_t mask, uint16_t rows[MAX_N]) {
    for (int i=0;i<c->n;i++) rows[i]=0;
    for (int u=0;u<c->n;u++) {
        int v=(u+1)%c->n;
        rows[u]|=(uint16_t)(1u<<v); rows[v]|=(uint16_t)(1u<<u);
    }
    for (int i=0;i<c->d;i++) if (mask&(UINT32_C(1)<<i)) {
        int u=c->diag[i].u,v=c->diag[i].v;
        rows[u]|=(uint16_t)(1u<<v); rows[v]|=(uint16_t)(1u<<u);
    }
}
static int triangle_count(const Context *c, uint32_t mask) {
    uint16_t rows[MAX_N]; adjacency(c,mask,rows); int count=0;
    for (int a=0;a<c->n;a++) for (int b=a+1;b<c->n;b++) for (int d=b+1;d<c->n;d++)
        if ((rows[a]&(1u<<b)) && (rows[b]&(1u<<d)) && (rows[a]&(1u<<d))) count++;
    return count;
}
static int common_opposites(const Context *c, uint32_t mask, int edge, int *inside, int *outside) {
    uint16_t rows[MAX_N]; adjacency(c,mask,rows);
    const int u=c->diag[edge].u,v=c->diag[edge].v;
    const uint16_t common=(uint16_t)(rows[u]&rows[v]);
    int found=0;
    for (int w=0;w<c->n;w++) if (common&(1u<<w)) {
        if (u<w && w<v) *inside=w; else *outside=w;
        found++;
    }
    return found==2 && *inside>=0 && *outside>=0;
}
static int flip_state(const Context *c, uint32_t mask, int edge, uint32_t *result, int require_lawson) {
    int inside=-1,outside=-1;
    if (!common_opposites(c,mask,edge,&inside,&outside)) return 0;
    if (require_lawson && incircle(c->p[c->diag[edge].u],c->p[inside],c->p[c->diag[edge].v],c->p[outside])<=0) return 0;
    int lo=inside<outside?inside:outside, hi=inside<outside?outside:inside;
    const int opposite=diagonal_index(c,lo,hi);
    if (opposite<0) return 0;
    *result=(mask&~(UINT32_C(1)<<edge))|(UINT32_C(1)<<opposite);
    return 1;
}
static int parent_state(const Context *c, uint32_t mask, uint32_t *parent) {
    for (int edge=0;edge<c->d;edge++) if (mask&(UINT32_C(1)<<edge)) {
        uint32_t next;
        if (flip_state(c,mask,edge,&next,1)) { *parent=next; return 1; }
    }
    return 0;
}
static int valid_delaunay_root(const Context *c, uint32_t mask) {
    if (triangle_count(c,mask)!=c->n-2) return 0;
    uint16_t rows[MAX_N]; adjacency(c,mask,rows);
    for (int a=0;a<c->n;a++) for (int b=a+1;b<c->n;b++) for (int d=b+1;d<c->n;d++) {
        if (!(rows[a]&(1u<<b)) || !(rows[b]&(1u<<d)) || !(rows[a]&(1u<<d))) continue;
        for (int q=0;q<c->n;q++) if (q!=a && q!=b && q!=d && incircle(c->p[a],c->p[b],c->p[d],c->p[q])>0) return 0;
    }
    return 1;
}
static int reverse_search(const Context *c, uint32_t root) {
    uint32_t states[MAX_STATES]; uint8_t next_edge[MAX_STATES]={0};
    int top=0,count=1; states[0]=root;
    while (top>=0) {
        if (next_edge[top]>=c->d) { top--; continue; }
        int edge=next_edge[top]++;
        if (!(states[top]&(UINT32_C(1)<<edge))) continue;
        uint32_t child,parent;
        if (!flip_state(c,states[top],edge,&child,0) || !parent_state(c,child,&parent) || parent!=states[top]) continue;
        if (count>=MAX_STATES) return -1;
        count++; top++; states[top]=child; next_edge[top]=0;
    }
    return count;
}

int64_t delaunay_rooted_triangulation_reverse_search(const int64_t *input, size_t length) {
    if (!input || length<2 || length>MAX_INPUT) return -1;
    const int64_t n64=input[0];
    if (n64<3 || n64>MAX_N || length!=(size_t)(4*n64-4)) return -1;
    Context c={0}; c.n=(int)n64;
    for (int i=0;i<c.n;i++) {
        c.p[i]=(Point){input[1+2*i],input[2+2*i]};
        if (c.p[i].x < -50 || c.p[i].x > 50 || c.p[i].y < -50 || c.p[i].y > 50) return -1;
    }
    for (int a=0;a<c.n;a++) for (int b=a+1;b<c.n;b++) for (int d=b+1;d<c.n;d++)
        if (orient(c.p[a],c.p[b],c.p[d])<=0) return -1;
    for (int a=0;a<c.n;a++) for (int b=a+1;b<c.n;b++) for (int d=b+1;d<c.n;d++) for (int q=d+1;q<c.n;q++)
        if (incircle(c.p[a],c.p[b],c.p[d],c.p[q])==0) return -1;

    for (int u=0;u<c.n;u++) for (int v=u+1;v<c.n;v++) if (!is_boundary(c.n,u,v)) c.diag[c.d++]=(Diagonal){u,v};
    const size_t count_at=1+(size_t)(2*c.n);
    if (input[count_at]!=c.n-3) return -1;
    uint32_t root=0; Diagonal previous={-1,-1};
    for (int i=0;i<c.n-3;i++) {
        const int64_t u64=input[count_at+1+2*(size_t)i],v64=input[count_at+2+2*(size_t)i];
        if (u64<0 || u64>=v64 || v64>=c.n) return -1;
        Diagonal edge={(int)u64,(int)v64};
        if (is_boundary(c.n,edge.u,edge.v) || (i>0 && (edge.u<previous.u || (edge.u==previous.u && edge.v<=previous.v)))) return -1;
        const int index=diagonal_index(&c,edge.u,edge.v); if (index<0) return -1;
        root|=UINT32_C(1)<<index;
        previous=edge;
    }
    int seen=0;
    for (int i=0;i<c.d;i++) if (root&(UINT32_C(1)<<i)) {
        seen++;
        for (int j=i+1;j<c.d;j++) if (root&(UINT32_C(1)<<j))
            if (crosses(c.diag[i],c.diag[j])) return -1;
    }
    if (seen!=c.n-3 || !valid_delaunay_root(&c,root)) return -1;
    return reverse_search(&c,root);
}
