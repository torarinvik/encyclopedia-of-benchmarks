module astar_csharp_spatial;

extern fn double sqrt(double value);
const usz MAX_NODES = 16;
struct Node { double x; double y; double multiplier; double current; double estimated; int traversable; int state; int parent; }

fn double distance(Node* nodes, usz a, usz b) {
    double dx = nodes[a].x - nodes[b].x, dy = nodes[a].y - nodes[b].y;
    return sqrt(dx * dx + dy * dy);
}
fn double total(Node* nodes, usz i) { return nodes[i].current + nodes[i].estimated; }
fn void enqueue(usz* heap, usz* count, usz value, Node* nodes) {
    usz i = *count; *count = *count + 1;
    while (i > 0) { usz p = (i - 1) / 2; if (total(nodes, heap[p]) <= total(nodes, value)) break; heap[i] = heap[p]; i = p; }
    heap[i] = value;
}
fn usz dequeue(usz* heap, usz* count, Node* nodes) {
    usz target = heap[0]; *count = *count - 1; usz root = heap[*count], i = 0;
    while (i * 2 + 1 < *count) { usz l = i * 2 + 1, r = i * 2 + 2; usz child = r < *count && total(nodes, heap[r]) < total(nodes, heap[l]) ? r : l;
        if (total(nodes, heap[child]) >= total(nodes, root)) break; heap[i] = heap[child]; i = child; }
    if (*count > 0) heap[i] = root; return target;
}
fn void put_i64(char* output, usz offset, long value) { ulong bits = (ulong)value; for (usz b = 0; b < 8; b++) output[offset + b] = (char)((bits >> (b * 8)) & 255); }

fn long astar_csharp_spatial(long* input, usz length, char* output, usz capacity) @export("astar_csharp_spatial") {
    if (input == null || length < 4) return -1;
    long n64=input[0], m64=input[1], s64=input[2], g64=input[3];
    if (n64 < 2 || n64 > 16 || m64 != n64 - 1 || s64 < 0 || s64 >= n64 || g64 < 0 || g64 >= n64) return -1;
    usz n=(usz)n64, m=(usz)m64, start=(usz)s64, goal=(usz)g64, edge=4+4*n;
    if (length != 4 + 4*n + 2*m) return -1;
    Node[16] nodes; usz[16] parents; usz[16] seen; usz[16] stack;
    for (usz i=0;i<16;i++) { parents[i]=0; seen[i]=0; }
    for (usz i=0;i<n;i++) { usz o=4+4*i; long x=input[o], y=input[o+1], t=input[o+2], mult=input[o+3];
        if(x < -1000 || x > 1000 || y < -1000 || y > 1000 || (t != 0 && t != 1) || mult < 1 || mult > 4) return -1;
        nodes[i] = {(double)x,(double)y,(double)mult,0.0,0.0,(int)t,0,-1};
        for(usz j=0;j<i;j++) if(nodes[i].x==nodes[j].x && nodes[i].y==nodes[j].y) return -1;
    }
    for(usz e=0;e<m;e++){long u=input[edge+2*e],v=input[edge+2*e+1];if(u<0||u>=n64||v<0||v>=n64||u==v)return -1;parents[v]=(usz)(parents[v]+1);if(parents[v]>1)return -1;for(usz p=0;p<e;p++)if(input[edge+2*p]==u&&input[edge+2*p+1]==v)return -1;}
    if(parents[start]!=0)return -1;for(usz i=0;i<n;i++)if(i!=start&&parents[i]!=1)return -1;
    usz top=0,visited=0;stack[top++]=start;while(top>0){usz u=stack[--top];if(seen[u])continue;seen[u]=1;visited++;for(usz e=0;e<m;e++)if(input[edge+2*e]==(long)u)stack[top++]=(usz)input[edge+2*e+1];}if(visited!=n)return -1;
    usz[16] heap;usz hc=0;for(usz e=0;e<m;e++)if(input[edge+2*e]==(long)start){usz v=(usz)input[edge+2*e+1];if(nodes[v].traversable){nodes[v].current=distance(&nodes,start,v)*nodes[v].multiplier;nodes[v].estimated=distance(&nodes,v,goal);enqueue(&heap,&hc,v,&nodes);}}
    usz[16] path;usz pc=0;while(hc>0){usz u=dequeue(&heap,&hc,&nodes);nodes[u].state=2;if(total(&nodes,u)==total(&nodes,goal)){long q=(long)goal;while(q>=0&&pc<16){path[pc++]=(usz)q;q=nodes[q].parent;}break;}
        for(usz e=0;e<m;e++)if(input[edge+2*e]==(long)u){usz v=(usz)input[edge+2*e+1];if(!nodes[v].traversable||nodes[v].state==2)continue;if(nodes[v].state==0){nodes[v].parent=(int)u;nodes[v].current=nodes[u].current+distance(&nodes,u,v)*nodes[v].multiplier;nodes[v].estimated=nodes[v].current+distance(&nodes,v,goal);nodes[v].state=1;enqueue(&heap,&hc,v,&nodes);}else if(total(&nodes,u)!=total(&nodes,v)){double ng=nodes[u].current+distance(&nodes,u,v),nf=ng+nodes[u].estimated;if(nf<total(&nodes,v)){nodes[v].parent=(int)u;nodes[v].current=ng;}}else return -1;}}
    usz bytes=pc*8;if(bytes==0)return 0;if(output==null||capacity<bytes)return -2;for(usz i=0;i<pc;i++)put_i64(output,i*8,(long)path[pc-1-i]);return (long)bytes;
}
