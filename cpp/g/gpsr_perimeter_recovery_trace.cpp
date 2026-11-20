#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <utility>
#include <vector>

namespace {
constexpr int MaxN=8, MaxM=18, MaxInput=57, MaxOutput=896;
struct Point { std::int64_t x, y; };
struct Fraction { std::int64_t n, d; };
struct Frame {
    int n{},m{},source{},target{};
    std::vector<Point> points;
    std::vector<std::pair<int,int>> edges;
    std::vector<std::vector<int>> adjacency, rotation;
};
std::int64_t cross(std::int64_t ax,std::int64_t ay,std::int64_t bx,std::int64_t by) {
    return ax*by-ay*bx;
}
std::int64_t orient(Point a,Point b,Point c) {
    return cross(b.x-a.x,b.y-a.y,c.x-a.x,c.y-a.y);
}
int half(std::int64_t x,std::int64_t y) { return y>0 || (y==0 && x>=0) ? 0 : 1; }
bool angle_less(std::int64_t ax,std::int64_t ay,int ai,
                std::int64_t bx,std::int64_t by,int bi) {
    int ha=half(ax,ay),hb=half(bx,by);
    if (ha!=hb) return ha<hb;
    auto turn=cross(ax,ay,bx,by);
    return turn!=0 ? turn>0 : ai<bi;
}
bool proper_crossing(Point p,Point q,Point a,Point b,Fraction& f) {
    auto rx=q.x-p.x,ry=q.y-p.y,sx=b.x-a.x,sy=b.y-a.y;
    auto den=cross(rx,ry,sx,sy);
    if (den==0) return false;
    auto ax=a.x-p.x,ay=a.y-p.y;
    auto tn=cross(ax,ay,sx,sy),un=cross(ax,ay,rx,ry);
    if (den<0) { den=-den; tn=-tn; un=-un; }
    if (!(tn>0 && tn<den && un>0 && un<den)) return false;
    auto g=std::gcd(tn,den); f={tn/g,den/g}; return true;
}
bool segments_cross(Point a,Point b,Point c,Point d) {
    return orient(a,b,c)*orient(a,b,d)<0 && orient(c,d,a)*orient(c,d,b)<0;
}
bool decode(const std::int64_t* in,std::size_t len,Frame& f) {
    if (!in || len<4 || len>MaxInput) return false;
    auto n=in[0],m=in[1],s=in[2],d=in[3];
    if (n<3 || n>MaxN || m<n-1 || m>3*n-6 || m>MaxM || s<0 || s>=n || d<0 || d>=n || s==d) return false;
    if (len!=static_cast<std::size_t>(4+2*n+2*m)) return false;
    f.n=static_cast<int>(n); f.m=static_cast<int>(m); f.source=static_cast<int>(s); f.target=static_cast<int>(d);
    f.points.resize(f.n);
    for (int i=0;i<f.n;++i) {
        auto x=in[4+i],y=in[4+f.n+i];
        if (x < -16 || x > 16 || y < -16 || y > 16) return false;
        f.points[i]={x,y};
        for (int j=0;j<i;++j) if (f.points[j].x==x && f.points[j].y==y) return false;
    }
    for (int i=0;i<f.n;++i) for (int j=i+1;j<f.n;++j) for (int k=j+1;k<f.n;++k)
        if (orient(f.points[i],f.points[j],f.points[k])==0) return false;
    f.adjacency.assign(f.n,{}); f.edges.clear();
    std::size_t base=4+2*f.n;
    for (int i=0;i<f.m;++i) {
        auto u=in[base+2*i],v=in[base+2*i+1];
        if (u<0 || v>=f.n || u>=v) return false;
        std::pair<int,int> edge{static_cast<int>(u),static_cast<int>(v)};
        if (!f.edges.empty() && !(f.edges.back()<edge)) return false;
        f.edges.push_back(edge); f.adjacency[u].push_back(v); f.adjacency[v].push_back(u);
    }
    std::vector<bool> seen(f.n,false); std::vector<int> queue{f.source}; seen[f.source]=true;
    for (std::size_t h=0;h<queue.size();++h) for (int v:f.adjacency[queue[h]])
        if (!seen[v]) { seen[v]=true; queue.push_back(v); }
    if (queue.size()!=static_cast<std::size_t>(f.n)) return false;
    for (int i=0;i<f.m;++i) for (int j=i+1;j<f.m;++j) {
        auto [a,b]=f.edges[i]; auto [c,d2]=f.edges[j];
        if (a!=c && a!=d2 && b!=c && b!=d2 && segments_cross(f.points[a],f.points[b],f.points[c],f.points[d2])) return false;
    }
    auto dist=[&](int v) { auto dx=f.points[v].x-f.points[f.target].x,dy=f.points[v].y-f.points[f.target].y; return dx*dx+dy*dy; };
    for (int v:f.adjacency[f.source]) if (dist(v)<dist(f.source)) return false;
    f.rotation=f.adjacency;
    for (int u=0;u<f.n;++u) std::sort(f.rotation[u].begin(),f.rotation[u].end(),[&](int a,int b) {
        return angle_less(f.points[a].x-f.points[u].x,f.points[a].y-f.points[u].y,a,
                          f.points[b].x-f.points[u].x,f.points[b].y-f.points[u].y,b);
    });
    return true;
}
int next_ccw(int u,int incoming,const Frame& f) {
    const auto& row=f.rotation[u]; auto it=std::find(row.begin(),row.end(),incoming);
    if (it==row.end()) return -1;
    return row[(static_cast<std::size_t>(it-row.begin())+1)%row.size()];
}
int first_ccw(int u,const Frame& f) {
    auto rx=f.points[f.target].x-f.points[u].x,ry=f.points[f.target].y-f.points[u].y;
    int best=-1; std::int64_t bx=0,by=0;
    for (int v:f.adjacency[u]) {
        auto dx=f.points[v].x-f.points[u].x,dy=f.points[v].y-f.points[u].y;
        auto x=rx*dx+ry*dy,y=cross(rx,ry,dx,dy);
        if (best<0 || angle_less(x,y,v,bx,by,best)) { best=v; bx=x; by=y; }
    }
    return best;
}
int edge_id(int u,int v,const Frame& f) {
    if (u>v) std::swap(u,v);
    auto it=std::lower_bound(f.edges.begin(),f.edges.end(),std::pair<int,int>{u,v});
    return it==f.edges.end() || *it!=std::pair<int,int>{u,v} ? -1 : static_cast<int>(it-f.edges.begin());
}
void append_i64(std::vector<std::uint8_t>& out,std::int64_t value) {
    auto bits=static_cast<std::uint64_t>(value);
    for (int i=0;i<8;++i) out.push_back(static_cast<std::uint8_t>(bits>>(8*i)));
}
}

extern "C" std::int64_t gpsr_perimeter_recovery_trace(const std::int64_t* input,std::size_t length,
    std::uint8_t* output,std::size_t capacity) noexcept {
    Frame f;
    if (!decode(input,length,f)) return -1;
    if (!output || capacity<MaxOutput) return -2;
    std::vector<int> path{f.source};
    struct Event { int step,edge; Fraction t; };
    std::vector<Event> events;
    int current=f.source,previous=-1,e0u=-1,e0v=-1,status=0;
    Fraction lf{0,1};
    auto start_dx=f.points[f.source].x-f.points[f.target].x;
    auto start_dy=f.points[f.source].y-f.points[f.target].y;
    auto start_distance=start_dx*start_dx+start_dy*start_dy;
    for (;;) {
        if (current==f.target) { status=2; break; }
        auto dx=f.points[current].x-f.points[f.target].x,dy=f.points[current].y-f.points[f.target].y;
        if (dx*dx+dy*dy<start_distance) { status=1; break; }
        if (static_cast<int>(path.size())-1>=2*f.m) { status=0; break; }
        int candidate=previous<0 ? first_ccw(current,f) : next_ccw(current,previous,f);
        bool changed=false;
        for (;;) {
            Fraction t{};
            if (!proper_crossing(f.points[f.source],f.points[f.target],f.points[current],f.points[candidate],t) ||
                t.n*lf.d<=lf.n*t.d) break;
            int id=edge_id(current,candidate,f);
            if (id<0 || events.size()>=MaxM) { status=0; goto done; }
            events.push_back({static_cast<int>(path.size())-1,id,t}); lf=t; changed=true;
            candidate=next_ccw(current,candidate,f);
        }
        if (changed || e0u<0) { e0u=current; e0v=candidate; }
        else if (e0u==current && e0v==candidate) { status=0; break; }
        previous=current; current=candidate; path.push_back(current);
    }
done:
    std::vector<std::uint8_t> staged; staged.reserve(MaxOutput);
    append_i64(staged,status); append_i64(staged,static_cast<std::int64_t>(path.size())-1);
    for (int v:path) append_i64(staged,v);
    append_i64(staged,static_cast<std::int64_t>(events.size()));
    for (const auto& event:events) {
        append_i64(staged,event.step); append_i64(staged,event.edge);
        append_i64(staged,event.t.n); append_i64(staged,event.t.d);
    }
    std::copy(staged.begin(),staged.end(),output);
    return static_cast<std::int64_t>(staged.size());
}
