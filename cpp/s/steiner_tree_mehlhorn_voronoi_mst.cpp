#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 8, M = 14;
constexpr std::size_t MAX_INPUT_VALUES = 54, MAX_OUTPUT = 72;
constexpr std::int64_t INF = INT64_C(0x3fffffffffffffff);
struct Edge { int u{}, v{}, w{}; };
struct Candidate { int a{}, b{}, left{}, right{}, edge{}; std::int64_t w{}; };
struct Graph { int n{}, m{}, k{}; std::array<int,N> terminals{}; std::array<Edge,M> edges{}; };

int root(std::array<int,N>& p, int x) {
    while (p[x] != x) { p[x] = p[p[x]]; x = p[x]; }
    return x;
}
bool join(std::array<int,N>& p, std::array<int,N>& rank, int a, int b) {
    a = root(p,a); b = root(p,b); if (a == b) return false;
    if (rank[a] < rank[b]) std::swap(a,b);
    p[b] = a; if (rank[a] == rank[b]) ++rank[a]; return true;
}
bool before(const Candidate& a, const Candidate& b) {
    return std::array<std::int64_t,6>{a.w,a.a,a.b,a.left,a.right,a.edge} <
           std::array<std::int64_t,6>{b.w,b.a,b.b,b.left,b.right,b.edge};
}
bool parse(const std::int64_t* in, std::size_t len, Graph& g) {
    if (in == nullptr || len < 3 || len > MAX_INPUT_VALUES) return false;
    if (in[0] < 2 || in[0] > N || in[1] < 1 || in[1] > M || in[2] < 2 || in[2] > in[0]) return false;
    g.n = static_cast<int>(in[0]); g.m = static_cast<int>(in[1]); g.k = static_cast<int>(in[2]);
    if (len < static_cast<std::size_t>(3 + g.k + 3*g.m)) return false;
    std::array<bool,N> term{};
    std::size_t at = 3;
    for (int i=0;i<g.k;++i) {
        auto t=in[at++]; if (t<0 || t>=g.n || term[static_cast<std::size_t>(t)]) return false;
        g.terminals[static_cast<std::size_t>(i)]=static_cast<int>(t); term[static_cast<std::size_t>(t)]=true;
    }
    std::array<std::array<bool,N>,N> seen{};
    for (int e=0;e<g.m;++e) {
        auto u=in[at++],v=in[at++],w=in[at++];
        if (u<0 || u>=v || v>=g.n || w<1 || w>9 || seen[u][v]) return false;
        seen[u][v]=true; g.edges[static_cast<std::size_t>(e)]={static_cast<int>(u),static_cast<int>(v),static_cast<int>(w)};
    }
    if (at!=len) return false;
    std::array<bool,N> visited{}; std::array<int,N> q{}; int h=0,t=0; visited[0]=true;q[t++]=0;
    while(h<t) { int u=q[h++]; for(int e=0;e<g.m;++e) { const auto& x=g.edges[e]; int v=x.u==u?x.v:(x.v==u?x.u:-1); if(v>=0&&!visited[v]){visited[v]=true;q[t++]=v;} } }
    for(int v=0;v<g.n;++v)if(!visited[v])return false;
    return true;
}

bool solve(const Graph& g, std::int64_t& out_cost, std::array<int,M>& out_edges, int& out_count) {
    std::array<std::int64_t,N> d{}; d.fill(INF);
    std::array<int,N> owner{}, pred{}, pred_edge{}; owner.fill(g.n); pred.fill(-1); pred_edge.fill(-1);
    std::array<bool,N> settled{};
    for(int i=0;i<g.k;++i){int s=g.terminals[i];d[s]=0;owner[s]=s;}
    for(int step=0;step<g.n;++step){
        int u=-1;
        for(int v=0;v<g.n;++v)if(!settled[v]&&(u<0||d[v]<d[u]||(d[v]==d[u]&&(owner[v]<owner[u]||(owner[v]==owner[u]&&v<u)))))u=v;
        if(u<0||d[u]==INF)break;settled[u]=true;
        for(int e=0;e<g.m;++e){const auto& edge=g.edges[e];int v=edge.u==u?edge.v:(edge.v==u?edge.u:-1);if(v<0)continue;
            auto nd=d[u]+edge.w;
            if(nd<d[v]||(nd==d[v]&&owner[u]<owner[v])){d[v]=nd;owner[v]=owner[u];pred[v]=u;pred_edge[v]=e;}
            else if(nd==d[v]&&owner[u]==owner[v]&&!settled[v]&&(pred[v]<0||u<pred[v]||(u==pred[v]&&e<pred_edge[v]))){pred[v]=u;pred_edge[v]=e;}
        }
    }
    for(int v=0;v<g.n;++v)if(d[v]==INF||owner[v]==g.n)return false;
    std::array<std::array<bool,N>,N> has{}; std::array<std::array<Candidate,N>,N> best{};
    for(int e=0;e<g.m;++e){int u=g.edges[e].u,v=g.edges[e].v,a=owner[u],b=owner[v];if(a==b)continue;int left=u,right=v;if(a>b){std::swap(a,b);left=v;right=u;}
        Candidate c{a,b,left,right,e,d[u]+g.edges[e].w+d[v]};const auto& old=best[a][b];
        if(!has[a][b]||before(c,old)){best[a][b]=c;has[a][b]=true;}
    }
    std::array<Candidate,M> candidates{};int cn=0;
    for(int a=0;a<g.n;++a)for(int b=a+1;b<g.n;++b)if(has[a][b])candidates[cn++]=best[a][b];
    std::sort(candidates.begin(),candidates.begin()+cn,before);
    std::array<int,N> p{},rank{};for(int v=0;v<g.n;++v)p[v]=v;
    std::array<int,N> chosen{};int ch=0;
    for(int i=0;i<cn&&ch<g.k-1;++i)if(join(p,rank,candidates[i].a,candidates[i].b))chosen[ch++]=i;
    if(ch!=g.k-1)return false;
    std::array<bool,M> used{};
    for(int i=0;i<ch;++i){const auto& c=candidates[chosen[i]];used[c.edge]=true;
        for(int x=c.left;x!=c.a;x=pred[x]){if(pred_edge[x]<0)return false;used[pred_edge[x]]=true;}
        for(int x=c.right;x!=c.b;x=pred[x]){if(pred_edge[x]<0)return false;used[pred_edge[x]]=true;}
    }
    std::array<int,M> order{};int on=0;for(int e=0;e<g.m;++e)if(used[e])order[on++]=e;
    std::sort(order.begin(),order.begin()+on,[&](int a,int b){return g.edges[a].w!=g.edges[b].w?g.edges[a].w<g.edges[b].w:a<b;});
    p={};rank={};for(int v=0;v<g.n;++v)p[v]=v;std::array<bool,M> tree{};
    for(int i=0;i<on;++i){int e=order[i];if(join(p,rank,g.edges[e].u,g.edges[e].v))tree[e]=true;}
    int r=root(p,g.terminals[0]);for(int i=1;i<g.k;++i)if(root(p,g.terminals[i])!=r)return false;
    std::array<bool,N> is_terminal{};for(int i=0;i<g.k;++i)is_terminal[g.terminals[i]]=true;
    std::array<int,N> degree{};for(int e=0;e<g.m;++e)if(tree[e]){++degree[g.edges[e].u];++degree[g.edges[e].v];}
    std::array<int,N> queue{};int h=0,t=0;std::array<bool,N> queued{};
    for(int v=0;v<g.n;++v)if(!is_terminal[v]&&degree[v]<=1){queue[t++]=v;queued[v]=true;}
    while(h<t){int u=queue[h++];if(degree[u]>1)continue;for(int e=0;e<g.m;++e)if(tree[e]&&(g.edges[e].u==u||g.edges[e].v==u)){
        tree[e]=false;int v=g.edges[e].u==u?g.edges[e].v:g.edges[e].u;--degree[u];--degree[v];if(!is_terminal[v]&&degree[v]<=1&&!queued[v]){queue[t++]=v;queued[v]=true;}
    }}
    out_count=0;out_cost=0;for(int e=0;e<g.m;++e)if(tree[e]){out_edges[out_count++]=e;out_cost+=g.edges[e].w;}
    return out_count>0&&out_count<=g.n-1;
}
void put(std::uint8_t* out,std::size_t at,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(int b=0;b<8;++b){out[at+b]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}}
}

extern "C" std::int64_t steiner_tree_mehlhorn_voronoi_mst(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    Graph g;if(!parse(input,length,g))return -1;std::int64_t cost=0;std::array<int,M> result{};int count=0;
    if(!solve(g,cost,result,count))return -1;std::size_t bytes=static_cast<std::size_t>(2+count)*8;
    if(output==nullptr||capacity<bytes||bytes>MAX_OUTPUT)return -2;put(output,0,cost);put(output,8,count);
    for(int i=0;i<count;++i)put(output,16+static_cast<std::size_t>(i)*8,result[i]);return static_cast<std::int64_t>(bytes);
}
