module steiner_tree_gain_greedy;

struct Edge { long u; long v; long w; }

fn void put_i64(uint8* out, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) out[word*8+b] = (uint8)(bits >> (8*b));
}
fn long root(long* p, long x) {
    while (p[x] != x) { p[x] = p[p[x]]; x = p[x]; }
    return x;
}
fn bool join(long* p, long a, long b) {
    long ra=root(p,a), rb=root(p,b);
    if (ra==rb) return false;
    p[rb]=ra; return true;
}
fn long group_count(long n,long mask,bool* h) {
    long[4] p; for(long i=0;i<4;i++)p[i]=i;
    for(long i=0;i<n;i++)for(long j=i+1;j<n;j++)if(h[i*4+j])join(p,i,j);
    bool[4] seen;long count=0;
    for(long i=0;i<n;i++)if((mask&(1<<i))!=0){long r=root(p,i);if(!seen[r]){seen[r]=true;count++;}}
    return count;
}
fn bool less_edge(Edge a,Edge b){return a.w<b.w||(a.w==b.w&&(a.u<b.u||(a.u==b.u&&a.v<b.v)));}
fn long metric_mst(long n,long mask,long* w){
    long[4] verts;long vn=0;for(long i=0;i<n;i++)if((mask&(1<<i))!=0){verts[vn]=i;vn++;}
    if(vn<=1)return 0;
    bool[4] used;long[4] best;for(long i=0;i<4;i++)best[i]=9223372036854775807;
    used[verts[0]]=true;for(long x=1;x<vn;x++)best[verts[x]]=w[verts[0]*4+verts[x]];
    long total=0;
    for(long step=1;step<vn;step++){long pick=-1;for(long x=0;x<vn;x++){long v=verts[x];if(!used[v]&&(pick<0||best[v]<best[pick]||(best[v]==best[pick]&&v<pick)))pick=v;}
        total+=best[pick];used[pick]=true;for(long x=0;x<vn;x++){long v=verts[x];if(!used[v]&&w[pick*4+v]<best[v])best[v]=w[pick*4+v];}}
    return total;
}
fn long mst_h(long n,long* w,bool* h,Edge* tree,long* tree_n){
    Edge[6] es;long en=0;for(long i=0;i<n;i++)for(long j=i+1;j<n;j++)if(h[i*4+j]){es[en]=Edge{i,j,w[i*4+j]};en++;}
    for(long i=1;i<en;i++){Edge x=es[i];long j=i;while(j>0&&less_edge(x,es[j-1])){es[j]=es[j-1];j--;}es[j]=x;}
    long[4] p;for(long i=0;i<4;i++)p[i]=i;long cost=0;*tree_n=0;
    for(long i=0;i<en;i++){Edge e=es[i];if(join(p,e.u,e.v)){tree[*tree_n]=e;*tree_n=*tree_n+1;cost+=e.w;}}
    return cost;
}
fn long contracted_mst(long n,long mask,long* w,bool* h){
    long[16] d;long[4] p;for(long i=0;i<4;i++){p[i]=i;for(long j=0;j<4;j++)d[i*4+j]=w[i*4+j];}
    for(long i=0;i<n;i++)for(long j=i+1;j<n;j++)if(h[i*4+j]){d[i*4+j]=0;d[j*4+i]=0;join(p,i,j);}
    for(long k=0;k<n;k++)for(long i=0;i<n;i++)for(long j=0;j<n;j++)if(d[i*4+j]>d[i*4+k]+d[k*4+j])d[i*4+j]=d[i*4+k]+d[k*4+j];
    long[4] roots;long g=0;for(long v=0;v<n;v++)if((mask&(1<<v))!=0){long r=root(p,v);bool found=false;for(long x=0;x<g;x++)if(roots[x]==r)found=true;if(!found){roots[g]=r;g++;}}
    if(g<=1)return 0;
    long[16] q;for(long a=0;a<g;a++)for(long b=a+1;b<g;b++){long best=9223372036854775807;for(long u=0;u<n;u++)if(root(p,u)==roots[a])for(long v=0;v<n;v++)if(root(p,v)==roots[b]&&d[u*4+v]<best)best=d[u*4+v];q[a*4+b]=best;q[b*4+a]=best;}
    bool[4] used;long[4] best;for(long i=0;i<4;i++)best[i]=9223372036854775807;used[0]=true;for(long j=1;j<g;j++)best[j]=q[j];long total=0;
    for(long step=1;step<g;step++){long pick=-1;for(long v=0;v<g;v++)if(!used[v]&&(pick<0||best[v]<best[pick]||(best[v]==best[pick]&&v<pick)))pick=v;total+=best[pick];used[pick]=true;for(long v=0;v<g;v++)if(!used[v]&&q[pick*4+v]<best[v])best[v]=q[pick*4+v];}
    return total;
}

fn long steiner_tree_gain_greedy(long* input,usz length,uint8* output,usz capacity) @export("steiner_tree_gain_greedy"){
    if(input==null||length<4||length>37)return -1;
    long n0=input[0],mask=input[1],count0=input[2];if(n0<2||n0>4||mask<=0||(mask>>n0)!=0||count0<1||count0>4)return -1;
    long n=n0,count=count0,terms=0;for(long i=0;i<n;i++)if((mask&(1<<i))!=0)terms++;if(terms<2)return -1;
    long[16] w;usz at=3;for(long i=0;i<n;i++)for(long j=i+1;j<n;j++){if(at>=length||input[at]<0||input[at]>1000)return -1;w[i*4+j]=input[at];w[j*4+i]=input[at];at++;}
    for(long i=0;i<n;i++)for(long j=0;j<n;j++)for(long k=0;k<n;k++)if(w[i*4+j]>w[i*4+k]+w[k*4+j])return -1;
    long[12] fu;long[12] fv;long[4] sizes;bool[16] fh;
    for(long c=0;c<count;c++){if(at>=length)return -1;long ec0=input[at];at++;if(ec0<1||ec0>n0-1||at+2*(usz)ec0>length)return -1;long ec=ec0;long[4] p;long[4] degree;for(long i=0;i<4;i++)p[i]=i;
        for(long e=0;e<ec;e++){long u0=input[at],v0=input[at+1];at+=2;if(u0<0||u0>=n||v0<0||v0>=n||u0==v0)return -1;long u=u0,v=v0;if(!join(p,u,v))return -1;if(u>v){long t=u;u=v;v=t;}for(long x=0;x<e;x++)if(fu[c*3+x]==u&&fv[c*3+x]==v)return -1;fu[c*3+e]=u;fv[c*3+e]=v;fh[u*4+v]=true;fh[v*4+u]=true;degree[u]++;degree[v]++;}
        long seen=0,leaves=0,first=-1;for(long v=0;v<n;v++)if(degree[v]>0){seen++;if(first<0)first=root(p,v);else if(root(p,v)!=first)return -1;if(degree[v]==1){if((mask&(1<<v))==0)return -1;leaves++;}else if((mask&(1<<v))!=0)return -1;}if(seen!=ec+1||leaves<2||leaves>3)return -1;sizes[c]=ec;
    }
    if(at!=length||group_count(n,mask,fh)!=1)return -1;
    long baseline=metric_mst(n,mask,w);bool[16] h;bool[4] selected;
    while(group_count(n,mask,h)>1){long before=group_count(n,mask,h),best=-1,best_gain=-9223372036854775807;
        for(long c=0;c<count;c++)if(!selected[c]){bool[16] trial=h;for(long e=0;e<sizes[c];e++){long u=fu[c*3+e],v=fv[c*3+e];trial[u*4+v]=true;trial[v*4+u]=true;}if(group_count(n,mask,trial)>=before)continue;Edge[3] scratch;long scratch_n=0;long gain=baseline-contracted_mst(n,mask,w,trial)-mst_h(n,w,trial,scratch,&scratch_n);if(best<0||gain>best_gain){best=c;best_gain=gain;}}
        if(best<0)return -1;selected[best]=true;for(long e=0;e<sizes[best];e++){long u=fu[best*3+e],v=fv[best*3+e];h[u*4+v]=true;h[v*4+u]=true;}}
    Edge[3] tree;long tree_n=0;long cost=mst_h(n,w,h,tree,&tree_n);usz bytes=8*(3+2*(usz)tree_n);if(output==null||capacity<bytes)return -2;
    put_i64(output,0,1);put_i64(output,1,cost);put_i64(output,2,tree_n);for(long i=0;i<tree_n;i++){put_i64(output,3+2*(usz)i,tree[i].u);put_i64(output,4+2*(usz)i,tree[i].v);}return (long)bytes;
}
