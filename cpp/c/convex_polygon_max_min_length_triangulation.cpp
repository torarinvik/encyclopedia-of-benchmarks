#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int min_n = 3, max_n = 6, max_length = 14;
struct Point { std::int64_t x, y; };

std::int64_t orient(Point a, Point b, Point c) {
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
}
std::int64_t distance_squared(Point a, Point b) {
    const auto dx=a.x-b.x, dy=a.y-b.y;
    return dx*dx+dy*dy;
}
int diagonal_bit(int n, int a, int b) {
    if (a>b) { const int temporary=a; a=b; b=temporary; }
    int bit=0;
    for (int left=0;left<n;++left) {
        for (int right=left+2;right<n;++right) {
            if (left==0 && right==n-1) continue;
            if (left==a && right==b) return bit;
            ++bit;
        }
    }
    return -1;
}
bool angle_at_least_sixty(Point p, Point q, Point r) {
    const auto ux=p.x-q.x, uy=p.y-q.y, vx=r.x-q.x, vy=r.y-q.y;
    const auto dot=ux*vx+uy*vy;
    if (dot<=0) return true;
    const auto norm_u=ux*ux+uy*uy, norm_v=vx*vx+vy*vy;
    return 4*dot*dot<=norm_u*norm_v;
}
std::int64_t greedy(const Point points[max_n], int n) {
    int next[max_n];
    for (int i=0;i<n;++i) next[i]=(i+1)%n;
    auto shortest=std::numeric_limits<std::int64_t>::max();
    for (int i=0;i<n;++i) {
        const auto edge=distance_squared(points[i],points[(i+1)%n]);
        if (edge<shortest) shortest=edge;
    }
    int active=n, p=0, q=next[0], r=next[q], steps=0;
    std::int64_t diagonal_mask=0;
    while (active>3) {
        if (++steps>4*n) return -1;
        if (angle_at_least_sixty(points[p],points[q],points[r])) {
            const auto chord=distance_squared(points[p],points[r]);
            if (chord<shortest) shortest=chord;
            const int bit=diagonal_bit(n,p,r);
            if (bit<0) return -1;
            diagonal_mask |= std::int64_t{1} << bit;
            next[p]=r;
            --active;
            q=r;
            r=next[r];
        } else {
            p=q;
            q=r;
            r=next[r];
        }
    }
    return shortest*512+diagonal_mask;
}
}

extern "C" std::int64_t convex_polygon_max_min_length_triangulation(const std::int64_t *input,
                                                       std::size_t length) {
    if (input==nullptr || length<1 || length>max_length) return -1;
    if (input[0]<min_n || input[0]>max_n) return -1;
    const int n=static_cast<int>(input[0]);
    if (length!=static_cast<std::size_t>(1+2*n)) return -1;
    Point points[max_n]{};
    for (int i=0;i<n;++i) {
        points[i]={input[1+2*i],input[2+2*i]};
        if (points[i].x < -8 || points[i].x > 8 || points[i].y < -8 || points[i].y > 8) return -1;
        for (int j=0;j<i;++j)
            if (points[i].x==points[j].x && points[i].y==points[j].y) return -1;
    }
    std::int64_t area2=0;
    for (int i=0;i<n;++i) {
        const int following=(i+1)%n;
        area2+=points[i].x*points[following].y-points[i].y*points[following].x;
    }
    if (area2<=0) return -1;
    for (int a=0;a<n;++a) for (int b=a+1;b<n;++b) for (int c=b+1;c<n;++c)
        if (orient(points[a],points[b],points[c])==0) return -1;
    for (int edge=0;edge<n;++edge) {
        const int following=(edge+1)%n;
        for (int vertex=0;vertex<n;++vertex)
            if (vertex!=edge && vertex!=following && orient(points[edge],points[following],points[vertex])<=0) return -1;
    }
    return greedy(points,n);
}
