// Independently authored draft; not compiled or run.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <numeric>

namespace {
constexpr std::int64_t scale=32768;
struct Line { std::int64_t a,b,c,norm; };
struct Point { std::int64_t x,y,den; };
int half(Line l) { return l.b>0 || (l.b==0 && l.a>=0) ? 0 : 1; }
bool before(Line a,Line b) {
    const auto ha=half(a), hb=half(b);
    if (ha!=hb) return ha<hb;
    const auto cross=a.a*b.b-a.b*b.a;
    return cross ? cross>0 : a.c<b.c;
}
bool intersect(Line a,Line b,Point& p) {
    auto d=a.a*b.b-b.a*a.b;
    if (!d) return false;
    auto x=a.c*b.b-a.b*b.c, y=a.a*b.c-a.c*b.a;
    if (d<0) { d=-d; x=-x; y=-y; }
    p={x,y,d}; return true;
}
bool outside(Line l,Point p) { return l.a*p.x+l.b*p.y>l.c*p.den; }
bool feasible(const std::array<Line,16>& lines,int count,int radius) {
    std::array<Line,16> queue{}; int head=0,tail=0;
    for (int i=0;i<count;++i) {
        auto h=lines[i]; h.c=h.c*scale-(radius*scale-1)*h.norm;
        if (tail>head && queue[tail-1].a==h.a && queue[tail-1].b==h.b) {
            if (h.c>=queue[tail-1].c) continue;
            --tail;
        }
        Point p{};
        while (tail-head>1 && intersect(queue[tail-2],queue[tail-1],p) && outside(h,p)) --tail;
        while (tail-head>1 && intersect(queue[head],queue[head+1],p) && outside(h,p)) ++head;
        if (tail>head && queue[tail-1].a*h.b-queue[tail-1].b*h.a==0) return false;
        queue[tail++]=h;
    }
    Point p{};
    while (tail-head>2 && intersect(queue[tail-2],queue[tail-1],p) && outside(queue[head],p)) --tail;
    while (tail-head>2 && intersect(queue[head],queue[head+1],p) && outside(queue[tail-1],p)) ++head;
    if (tail-head<3) return false;
    for (int i=head;i<tail;++i)
        if (!intersect(queue[i],queue[i+1==tail ? head : i+1],p)) return false;
    return true;
}
}

extern "C" std::int64_t convex_polygon_integer_inradius(const std::int64_t* values,std::size_t length) {
    if (!values || length<1 || length>38 || values[0]<0 || values[0]>12) return -1;
    int n=static_cast<int>(values[0]);
    if (length!=static_cast<std::size_t>(1+3*n)) return -1;
    std::array<Line,16> lines{};
    for (int i=0;i<n;++i) {
        auto a=values[1+3*i],b=values[2+3*i],c=values[3+3*i];
        if (a < -15 || a > 15 || b < -15 || b > 15 || c < -128 || c > 128) return -1;
        auto squared=a*a+b*b; std::int64_t norm=0;
        while (norm*norm<squared) ++norm;
        if (!norm || norm*norm!=squared || std::gcd(a,b)!=1) return -1;
        lines[i]={a,b,c,norm};
    }
    lines[n++]={1,0,256,1}; lines[n++]={0,1,256,1};
    lines[n++]={-1,0,256,1}; lines[n++]={0,-1,256,1};
    std::sort(lines.begin(),lines.begin()+n,before);
    if (!feasible(lines,n,0)) return -2;
    int low=0,high=257;
    while (high-low>1) {
        int middle=(low+high)/2;
        if (feasible(lines,n,middle)) low=middle; else high=middle;
    }
    return low;
}
