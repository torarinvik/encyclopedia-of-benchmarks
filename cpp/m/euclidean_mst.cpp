#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxPoints = 8;
constexpr int kMaxEdges = kMaxPoints * (kMaxPoints - 1) / 2;
constexpr std::size_t kMaxInputLength = 1 + 2 * kMaxPoints + 1;
constexpr std::size_t kMaxOutputWords = 2 * kMaxPoints - 1;
struct Point { std::int64_t x, y; };
struct Edge { int u, v; std::int64_t weight; };

std::int64_t orientation(Point a, Point b, Point c) noexcept {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
std::int64_t incircle(Point a, Point b, Point c, Point d) noexcept {
    const auto ax=a.x-d.x, ay=a.y-d.y, bx=b.x-d.x, by=b.y-d.y, cx=c.x-d.x, cy=c.y-d.y;
    return (ax*ax+ay*ay)*(bx*cy-by*cx) - (bx*bx+by*by)*(ax*cy-ay*cx)
         + (cx*cx+cy*cy)*(ax*by-ay*bx);
}
bool general_position(const std::array<Point, kMaxPoints>& points, int n) noexcept {
    for (int a=0;a<n;++a) for (int b=a+1;b<n;++b)
        if (points[a].x==points[b].x && points[a].y==points[b].y) return false;
    for (int a=0;a<n;++a) for (int b=a+1;b<n;++b) for (int c=b+1;c<n;++c) {
        if (orientation(points[a],points[b],points[c])==0) return false;
        for (int d=0;d<n;++d)
            if (d!=a && d!=b && d!=c && incircle(points[a],points[b],points[c],points[d])==0) return false;
    }
    return true;
}
int find_root(std::array<int, kMaxPoints>& parent, int v) noexcept {
    while (parent[v]!=v) { parent[v]=parent[parent[v]]; v=parent[v]; }
    return v;
}
void store_i64_le(std::uint8_t* out,std::size_t offset,std::int64_t value) noexcept {
    const auto bits=static_cast<std::uint64_t>(value);
    for (std::size_t byte=0;byte<8;++byte) out[offset+byte]=static_cast<std::uint8_t>(bits>>(8*byte));
}
} // namespace

extern "C" std::int64_t euclidean_mst(const std::int64_t* input,std::size_t length,
    std::uint8_t* output,std::size_t output_capacity) noexcept {
    if (input==nullptr || length<1 || length>kMaxInputLength) return -1;
    const auto raw_n=input[0];
    if (raw_n<1 || raw_n>kMaxPoints || length!=static_cast<std::size_t>(1+2*raw_n)) return -1;
    const int n=static_cast<int>(raw_n);
    std::array<Point,kMaxPoints> points{};
    for (int i=0;i<n;++i) {
        points[i]={input[1+2*i],input[2+2*i]};
        if (points[i].x < -10 || points[i].x > 10 || points[i].y < -10 || points[i].y > 10) return -1;
    }
    if (!general_position(points,n)) return -1;
    const std::size_t output_words=static_cast<std::size_t>(2*n-1), output_bytes=8*output_words;
    if (output==nullptr || output_capacity<output_bytes) return -2;

    std::array<std::array<bool,kMaxPoints>,kMaxPoints> candidate{};
    if (n==2) candidate[0][1]=candidate[1][0]=true;
    for (int a=0;a<n;++a) for (int b=a+1;b<n;++b) for (int c=b+1;c<n;++c) {
        const auto turn=orientation(points[a],points[b],points[c]);
        bool empty=true;
        for (int d=0;d<n;++d) {
            if (d==a || d==b || d==c) continue;
            const auto determinant=incircle(points[a],points[b],points[c],points[d]);
            if ((determinant>0)==(turn>0)) { empty=false; break; }
        }
        if (empty) candidate[a][b]=candidate[b][a]=candidate[a][c]=candidate[c][a]=candidate[b][c]=candidate[c][b]=true;
    }
    std::array<Edge,kMaxEdges> edges{};
    int edge_count=0;
    for (int u=0;u<n;++u) for (int v=u+1;v<n;++v) if (candidate[u][v]) {
        const auto dx=points[u].x-points[v].x, dy=points[u].y-points[v].y;
        Edge edge{u,v,dx*dx+dy*dy};
        int at=edge_count++;
        while (at>0) {
            const auto previous=edges[at-1];
            if (previous.weight<edge.weight || (previous.weight==edge.weight &&
                (previous.u<edge.u || (previous.u==edge.u && previous.v<=edge.v)))) break;
            edges[at]=previous; --at;
        }
        edges[at]=edge;
    }
    std::array<int,kMaxPoints> parent{}, size{};
    for (int i=0;i<n;++i) { parent[i]=i; size[i]=1; }
    std::array<std::int64_t,kMaxOutputWords> words{};
    words[0]=n-1;
    int selected=0;
    for (int i=0;i<edge_count && selected<n-1;++i) {
        int left=find_root(parent,edges[i].u),right=find_root(parent,edges[i].v);
        if (left==right) continue;
        if (size[left]<size[right]) { const int temporary=left; left=right; right=temporary; }
        parent[right]=left; size[left]+=size[right];
        words[1+2*selected]=edges[i].u; words[2+2*selected]=edges[i].v; ++selected;
    }
    if (selected!=n-1) return -1;
    for (std::size_t i=0;i<output_words;++i) store_i64_le(output,8*i,words[i]);
    return static_cast<std::int64_t>(output_bytes);
}
