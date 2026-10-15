#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_NODES = 16;
struct Node { double x=0, y=0, multiplier=1, current=0, estimated=0; int traversable=0, state=0, parent=-1; };
double distance_between(const Node &a, const Node &b) { const double dx=a.x-b.x, dy=a.y-b.y; return std::sqrt(dx*dx + dy*dy); }
double total_cost(const Node *nodes, int i) { return nodes[i].current + nodes[i].estimated; }
void enqueue(int *heap, int &count, int value, const Node *nodes) {
    int i = count++;
    while (i > 0) { const int p=(i-1)/2; if (total_cost(nodes,heap[p]) <= total_cost(nodes,value)) break; heap[i]=heap[p]; i=p; }
    heap[i]=value;
}
int dequeue(int *heap, int &count, const Node *nodes) {
    const int target=heap[0], root=heap[--count]; int i=0;
    while (i*2+1 < count) { const int left=i*2+1, right=i*2+2; const int child=right<count && total_cost(nodes,heap[right])<total_cost(nodes,heap[left]) ? right:left;
        if (total_cost(nodes,heap[child]) >= total_cost(nodes,root)) break; heap[i]=heap[child]; i=child; }
    if (count>0) heap[i]=root; return target;
}
void store_i64_le(std::int64_t value, std::uint8_t *out, std::size_t offset) {
    const auto bits=static_cast<std::uint64_t>(value); for (std::size_t b=0;b<8;++b) out[offset+b]=static_cast<std::uint8_t>(bits>>(8*b));
}
}

extern "C" std::int64_t astar_csharp_spatial(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length<4) return -1;
    const auto n64=input[0], m64=input[1], s64=input[2], g64=input[3];
    if (n64<2 || n64>MAX_NODES || m64!=n64-1 || s64<0 || s64>=n64 || g64<0 || g64>=n64) return -1;
    const int n=static_cast<int>(n64), m=static_cast<int>(m64), start=static_cast<int>(s64), goal=static_cast<int>(g64);
    if (length!=static_cast<std::size_t>(4+4*n+2*m)) return -1;
    Node nodes[MAX_NODES]{}; int parents[MAX_NODES]{}, seen[MAX_NODES]{}, stack[MAX_NODES]{}; const std::size_t eo=4+4*n;
    for (int i=0;i<n;++i) { const std::size_t o=4+4*i; const auto x=input[o],y=input[o+1],t=input[o+2],mul=input[o+3];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000 || (t!=0 && t!=1) || mul<1 || mul>4) return -1;
        nodes[i].x=static_cast<double>(x); nodes[i].y=static_cast<double>(y); nodes[i].traversable=static_cast<int>(t); nodes[i].multiplier=static_cast<double>(mul);
        for (int j=0;j<i;++j) if (nodes[i].x==nodes[j].x && nodes[i].y==nodes[j].y) return -1;
    }
    for (int e=0;e<m;++e) { const auto u=input[eo+2*e],v=input[eo+2*e+1]; if (u<0||u>=n||v<0||v>=n||u==v||++parents[v]>1) return -1;
        for (int p=0;p<e;++p) if (input[eo+2*p]==u && input[eo+2*p+1]==v) return -1; }
    if (parents[start]!=0) return -1; for(int i=0;i<n;++i) if(i!=start&&parents[i]!=1) return -1;
    int top=0, visited=0; stack[top++]=start; while(top){int u=stack[--top]; if(seen[u])continue; seen[u]=1;++visited; for(int e=0;e<m;++e)if(input[eo+2*e]==u)stack[top++]=static_cast<int>(input[eo+2*e+1]);} if(visited!=n)return -1;
    int heap[MAX_NODES], hc=0; for(int e=0;e<m;++e)if(input[eo+2*e]==start){int v=static_cast<int>(input[eo+2*e+1]);if(nodes[v].traversable){nodes[v].current=distance_between(nodes[start],nodes[v])*nodes[v].multiplier;nodes[v].estimated=distance_between(nodes[v],nodes[goal]);enqueue(heap,hc,v,nodes);}}
    int path[MAX_NODES], pc=0; while(hc){int u=dequeue(heap,hc,nodes);nodes[u].state=2;if(total_cost(nodes,u)==total_cost(nodes,goal)){for(int v=goal;v>=0&&pc<MAX_NODES;v=nodes[v].parent)path[pc++]=v;break;}
        for(int e=0;e<m;++e)if(input[eo+2*e]==u){int v=static_cast<int>(input[eo+2*e+1]);if(!nodes[v].traversable||nodes[v].state==2)continue;if(nodes[v].state==0){nodes[v].parent=u;nodes[v].current=nodes[u].current+distance_between(nodes[u],nodes[v])*nodes[v].multiplier;nodes[v].estimated=nodes[v].current+distance_between(nodes[v],nodes[goal]);nodes[v].state=1;enqueue(heap,hc,v,nodes);}else if(total_cost(nodes,u)!=total_cost(nodes,v)){const double ng=nodes[u].current+distance_between(nodes[u],nodes[v]), nf=ng+nodes[u].estimated;if(nf<total_cost(nodes,v)){nodes[v].parent=u;nodes[v].current=ng;}}else return -1;}}
    const std::size_t bytes=static_cast<std::size_t>(pc)*8;if(bytes==0)return 0;if(!output||capacity<bytes)return -2;for(int i=0;i<pc;++i)store_i64_le(path[pc-1-i],output,static_cast<std::size_t>(i)*8);return static_cast<std::int64_t>(bytes);
}
