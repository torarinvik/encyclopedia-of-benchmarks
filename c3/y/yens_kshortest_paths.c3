module yens_kshortest_paths;
const NMAX = 8;
const KMAX = 8;
const QMAX = 64;
struct Path { usz len; long[8] nodes; long cost; }
fn bool path_less(Path* a, Path* b) {
    if (a.cost != b.cost) return a.cost < b.cost;
    usz limit = a.len < b.len ? a.len : b.len;
    for (usz i = 0; i < limit; i++) if (a.nodes[i] != b.nodes[i]) return a.nodes[i] < b.nodes[i];
    return a.len < b.len;
}
fn bool same_path(Path* a, Path* b) {
    if (a.len != b.len) return false;
    for (usz i = 0; i < a.len; i++) if (a.nodes[i] != b.nodes[i]) return false;
    return true;
}
fn bool same_prefix(Path* a, Path* b, usz n) {
    if (a.len < n || b.len < n) return false;
    for (usz i = 0; i < n; i++) if (a.nodes[i] != b.nodes[i]) return false;
    return true;
}
fn bool contains(Path* p, usz v) { for (usz i = 0; i < p.len; i++) if ((usz)p.nodes[i] == v) return true; return false; }
fn void explore_spur(usz n, usz dst, long* graph, bool* banned_vertices, bool* banned_edges, Path* current, Path* best, bool* found) {
    usz u=(usz)current.nodes[current.len-1];
    if(u==dst){if(!*found||path_less(current,best)){*best=*current;*found=true;}return;}
    for(usz v=0;v<n;v++){
        if(graph[u*n+v]<0||banned_vertices[v]||banned_edges[u*NMAX+v]||contains(current,v))continue;
        current.nodes[current.len++]=(long)v;current.cost+=graph[u*n+v];
        explore_spur(n,dst,graph,banned_vertices,banned_edges,current,best,found);
        current.cost-=graph[u*n+v];current.len--;
    }
}
fn bool shortest(usz n, usz src, usz dst, long* graph, bool* banned_vertices, bool* banned_edges, Path* out) {
    Path current;current.len=1;current.nodes[0]=(long)src;current.cost=0;
    bool found=false;Path best;
    explore_spur(n,dst,graph,banned_vertices,banned_edges,&current,&best,&found);
    if(found)*out=best;
    return found;
}
fn void put_i64(char* output, usz offset, long value) { ulong bits = (ulong)value; for (usz i=0;i<8;i++) output[offset+i]=(char)(bits>>(8*i)); }
fn long yens_kshortest_paths(long* input, usz length, char* output, usz output_capacity) @export("yens_kshortest_paths") {
    if (input == null || length < 4) return -1;
    long nval=input[0]; long kval=input[1]; long srcval=input[2]; long dstval=input[3];
    if (nval<1 || nval>NMAX || kval<1 || kval>KMAX || srcval<0 || srcval>=nval || dstval<0 || dstval>=nval) return -1;
    usz n=(usz)nval; usz k=(usz)kval;
    if (length != 4+n*n) return -1;
    long[NMAX*NMAX] graph; for(usz i=0;i<n*n;i++){long w=input[4+i];if(w < -1 || w>1000)return -1;graph[i]=w;}
    Path[KMAX] accepted; Path[QMAX] candidates; usz accepted_count=0; usz candidate_count=0;
    bool[NMAX] banned_vertices; bool[NMAX*NMAX] banned_edges;
    Path first; if(shortest(n,(usz)srcval,(usz)dstval,&graph,&banned_vertices,&banned_edges,&first))accepted[accepted_count++]=first;
    while(accepted_count<k && accepted_count>0){
        Path previous=accepted[accepted_count-1];
        for(usz i=0;i+1<previous.len;i++){
            Path root; root.len=i+1;root.cost=0;
            for(usz j=0;j<=i;j++)root.nodes[j]=previous.nodes[j];
            for(usz j=0;j<i;j++)root.cost+=graph[(usz)root.nodes[j]*n+(usz)root.nodes[j+1]];
            for(usz z=0;z<accepted_count;z++)if(same_prefix(&accepted[z],&root,i+1)&&accepted[z].len>i+1)banned_edges[(usz)accepted[z].nodes[i]*NMAX+(usz)accepted[z].nodes[i+1]]=true;
            for(usz j=0;j<i;j++)banned_vertices[(usz)root.nodes[j]]=true;
            Path spur;
            if(shortest(n,(usz)root.nodes[i],(usz)dstval,&graph,&banned_vertices,&banned_edges,&spur)){
                Path total=root;for(usz j=1;j<spur.len;j++)total.nodes[total.len++]=spur.nodes[j];total.cost+=spur.cost;
                bool found=false;for(usz z=0;z<accepted_count;z++)if(same_path(&total,&accepted[z]))found=true;for(usz z=0;z<candidate_count;z++)if(same_path(&total,&candidates[z]))found=true;
                if(!found && candidate_count<QMAX)candidates[candidate_count++]=total;
            }
            for(usz j=0;j<i;j++)banned_vertices[(usz)root.nodes[j]]=false;
            for(usz z=0;z<accepted_count;z++)if(same_prefix(&accepted[z],&root,i+1)&&accepted[z].len>i+1)banned_edges[(usz)accepted[z].nodes[i]*NMAX+(usz)accepted[z].nodes[i+1]]=false;
        }
        if(candidate_count==0)break;
        usz best=0;for(usz i=1;i<candidate_count;i++)if(path_less(&candidates[i],&candidates[best]))best=i;
        accepted[accepted_count++]=candidates[best];candidate_count--;if(best<candidate_count)candidates[best]=candidates[candidate_count];
    }
    usz bytes=8;for(usz i=0;i<accepted_count;i++)bytes+=(accepted[i].len+2)*8;
    if(output==null||output_capacity<bytes)return -2;
    put_i64(output,0,(long)accepted_count);usz at=8;
    for(usz i=0;i<accepted_count;i++){put_i64(output,at,(long)accepted[i].len);at+=8;for(usz j=0;j<accepted[i].len;j++){put_i64(output,at,accepted[i].nodes[j]);at+=8;}put_i64(output,at,accepted[i].cost);at+=8;}
    return (long)bytes;
}
