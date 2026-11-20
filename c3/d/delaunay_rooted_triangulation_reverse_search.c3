module delaunay_rooted_triangulation_reverse_search;

const usz MAX_N = 8, MAX_D = 20, MAX_STATES = 132;

fn long orient(long* p, usz a, usz b, usz c) {
    return (p[2*b]-p[2*a])*(p[2*c+1]-p[2*a+1]) - (p[2*b+1]-p[2*a+1])*(p[2*c]-p[2*a]);
}
fn long incircle(long* p, usz a, usz b, usz c, usz d) {
    long ax=p[2*a]-p[2*d], ay=p[2*a+1]-p[2*d+1], bx=p[2*b]-p[2*d], by=p[2*b+1]-p[2*d+1], cx=p[2*c]-p[2*d], cy=p[2*c+1]-p[2*d+1];
    long al=ax*ax+ay*ay, bl=bx*bx+by*by, cl=cx*cx+cy*cy;
    return al*(bx*cy-by*cx)-bl*(ax*cy-ay*cx)+cl*(ax*by-ay*bx);
}
fn bool boundary(usz n, usz u, usz v) { return v==u+1 || (u==0 && v==n-1); }
fn long edge_index(long* diags, usz d, usz u, usz v) {
    for (usz i=0;i<d;i++) if ((usz)diags[2*i]==u && (usz)diags[2*i+1]==v) return (long)i;
    return -1;
}
fn bool crosses(usz a, usz b, usz c, usz d) {
    return (a<c && c<b && b<d) || (c<a && a<d && d<b);
}
fn void build_adjacency(ulong* rows, long* diags, usz n, usz d, ulong mask) {
    for (usz i=0;i<n;i++) rows[i]=0;
    for (usz u=0;u<n;u++) { usz v=(u+1)%n; rows[u]|=1ul<<v; rows[v]|=1ul<<u; }
    for (usz i=0;i<d;i++) if ((mask&(1ul<<i))!=0) { usz u=(usz)diags[2*i],v=(usz)diags[2*i+1]; rows[u]|=1ul<<v; rows[v]|=1ul<<u; }
}
fn long triangle_count(long* diags, usz n, usz d, ulong mask) {
    ulong[8] rows={}; build_adjacency(&rows[0],diags,n,d,mask); long count=0;
    for (usz a=0;a<n;a++) for (usz b=a+1;b<n;b++) for (usz z=b+1;z<n;z++)
        if ((rows[a]&(1ul<<b))!=0 && (rows[b]&(1ul<<z))!=0 && (rows[a]&(1ul<<z))!=0) count++;
    return count;
}
fn bool common_opposites(long* diags, usz n, usz d, ulong mask, usz edge, long* inside, long* outside) {
    ulong[8] rows={}; build_adjacency(&rows[0],diags,n,d,mask);
    usz u=(usz)diags[2*edge],v=(usz)diags[2*edge+1]; ulong common=rows[u]&rows[v]; long found=0; *inside=-1; *outside=-1;
    for (usz w=0;w<n;w++) if ((common&(1ul<<w))!=0) { if (u<w && w<v) *inside=(long)w; else *outside=(long)w; found++; }
    return found==2 && *inside>=0 && *outside>=0;
}
fn long flip_state(long* p,long* diags,usz n,usz d,ulong mask,usz edge,bool require_lawson) {
    long inside=-1,outside=-1;
    if (!common_opposites(diags,n,d,mask,edge,&inside,&outside)) return -1;
    usz u=(usz)diags[2*edge],v=(usz)diags[2*edge+1],c=(usz)inside,o=(usz)outside;
    if (require_lawson && incircle(p,u,c,v,o)<=0) return -1;
    usz lo=c<o?c:o, hi=c<o?o:c; long opposite=edge_index(diags,d,lo,hi);
    if (opposite<0) return -1;
    return (long)((mask&~(1ul<<edge))|(1ul<<(usz)opposite));
}
fn long parent_state(long* p,long* diags,usz n,usz d,ulong mask) {
    for (usz edge=0;edge<d;edge++) if ((mask&(1ul<<edge))!=0) { long next=flip_state(p,diags,n,d,mask,edge,true); if (next>=0) return next; }
    return -1;
}
fn bool valid_root(long* p,long* diags,usz n,usz d,ulong mask) {
    if (triangle_count(diags,n,d,mask)!=(long)n-2) return false;
    ulong[8] rows={}; build_adjacency(&rows[0],diags,n,d,mask);
    for (usz a=0;a<n;a++) for (usz b=a+1;b<n;b++) for (usz z=b+1;z<n;z++)
        if ((rows[a]&(1ul<<b))!=0 && (rows[b]&(1ul<<z))!=0 && (rows[a]&(1ul<<z))!=0)
            for (usz q=0;q<n;q++) if (q!=a && q!=b && q!=z && incircle(p,a,b,z,q)>0) return false;
    return true;
}
fn long reverse_search(long* p,long* diags,usz n,usz d,ulong root) {
    ulong[MAX_STATES] states={}; usz[MAX_STATES] cursor={}; usz top=0; long count=1; states[0]=root;
    while (true) {
        if (cursor[top]>=d) { if (top==0) break; top--; continue; }
        usz edge=cursor[top]; cursor[top]++;
        if ((states[top]&(1ul<<edge))==0) continue;
        ulong current=states[top]; long child=flip_state(p,diags,n,d,current,edge,false);
        if (child<0 || parent_state(p,diags,n,d,(ulong)child)!=(long)current) continue;
        if (count>=MAX_STATES) return -1;
        count++; top++; states[top]=(ulong)child; cursor[top]=0;
    }
    return count;
}

fn long delaunay_rooted_triangulation_reverse_search(long* input, usz length)
        @export("delaunay_rooted_triangulation_reverse_search") {
    if (input==null || length<2 || length>29) return -1;
    long n_value=input[0]; if (n_value<3 || n_value>8 || length!=(usz)(4*n_value-4)) return -1;
    usz n=(usz)n_value; long[16] points={};
    for (usz i=0;i<n;i++) { long x=input[1+2*i],y=input[2+2*i]; if (x< -50 || x>50 || y< -50 || y>50) return -1; points[2*i]=x;points[2*i+1]=y; }
    for (usz a=0;a<n;a++) for (usz b=a+1;b<n;b++) for (usz z=b+1;z<n;z++) if (orient(&points[0],a,b,z)<=0) return -1;
    for (usz a=0;a<n;a++) for (usz b=a+1;b<n;b++) for (usz z=b+1;z<n;z++) for (usz q=z+1;q<n;q++) if (incircle(&points[0],a,b,z,q)==0) return -1;
    long[40] diags={}; usz d=0;
    for (usz u=0;u<n;u++) for (usz v=u+1;v<n;v++) if (!boundary(n,u,v)) { diags[2*d]=(long)u;diags[2*d+1]=(long)v;d++; }
    usz at=1+2*n; if (input[at]!=(long)n-3) return -1; ulong root=0; long prev_u=-1,prev_v=-1;
    for (usz i=0;i<n-3;i++) { long u=input[at+1+2*i],v=input[at+2+2*i]; if (u<0 || u>=v || v>=n_value || boundary(n,(usz)u,(usz)v) || (i>0 && (u<prev_u || (u==prev_u && v<=prev_v)))) return -1; long ix=edge_index(&diags[0],d,(usz)u,(usz)v);if(ix<0)return -1;root|=1ul<<(usz)ix;prev_u=u;prev_v=v; }
    for (usz i=0;i<d;i++) if ((root&(1ul<<i))!=0) for (usz j=i+1;j<d;j++) if ((root&(1ul<<j))!=0) if (crosses((usz)diags[2*i],(usz)diags[2*i+1],(usz)diags[2*j],(usz)diags[2*j+1])) return -1;
    if (!valid_root(&points[0],&diags[0],n,d,root)) return -1;
    return reverse_search(&points[0],&diags[0],n,d,root);
}
