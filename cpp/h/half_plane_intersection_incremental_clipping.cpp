// Independently authored draft; not compiled or run.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <numeric>

namespace {
struct Line { std::int64_t a,b,c; };
struct Vertex { std::int64_t x,y,den; int incoming; };
std::int64_t gcd(std::int64_t a, std::int64_t b) {
    return std::gcd(a < 0 ? -a : a, b < 0 ? -b : b);
}
bool intersect(Line a, Line b, Vertex& p) {
    auto den=a.a*b.b-b.a*a.b;
    if (!den) return false;
    auto x=a.c*b.b-a.b*b.c, y=a.a*b.c-a.c*b.a;
    if (den<0) { den=-den; x=-x; y=-y; }
    const auto g=gcd(gcd(x,y),den);
    p={x/g,y/g,den/g,0}; return true;
}
std::int64_t side(Line l, Vertex p) { return l.a*p.x+l.b*p.y-l.c*p.den; }
bool same(Vertex a, Vertex b) { return a.x*b.den==b.x*a.den && a.y*b.den==b.y*a.den; }
std::int64_t turn(Vertex a, Vertex b, Vertex c) {
    const auto dx1=b.x*a.den-a.x*b.den, dy1=b.y*a.den-a.y*b.den;
    const auto dx2=c.x*b.den-b.x*c.den, dy2=c.y*b.den-b.y*c.den;
    return dx1*dy2-dy1*dx2;
}
void append(std::array<Vertex,32>& out, int& used, Vertex p) {
    if (!used || !same(out[used-1],p)) out[used++]=p;
}
void put(std::uint8_t* out, std::size_t& offset, std::int64_t value) {
    const auto bits=static_cast<std::uint64_t>(value);
    for (int i=0;i<8;++i) out[offset++]=static_cast<std::uint8_t>(bits>>(8*i));
}
}

extern "C" std::int64_t half_plane_intersection_incremental_clipping(
        const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (!input || length<1 || length>38 || input[0]<0 || input[0]>12) return -1;
    const int n=static_cast<int>(input[0]);
    if (length != 1+3*static_cast<std::size_t>(n)) return -1;
    std::array<Line,16> lines{};
    lines[0]={-1,0,256}; lines[1]={0,-1,256}; lines[2]={1,0,256}; lines[3]={0,1,256};
    for (int i=0;i<n;++i) {
        const auto a=input[1+3*i], b=input[2+3*i], c=input[3+3*i];
        if (a < -16 || a > 16 || b < -16 || b > 16 || c < -128 || c > 128
                || (!a && !b) || gcd(a,b)!=1) return -1;
        lines[4+i]={a,b,c};
    }
    std::array<Vertex,32> polygon{};
    polygon[0]={-256,-256,1,0}; polygon[1]={256,-256,1,1};
    polygon[2]={256,256,1,2}; polygon[3]={-256,256,1,3};
    int count=4;
    for (int line=4;line<4+n && count>=3;++line) {
        std::array<Vertex,32> next{}; int used=0;
        for (int i=0;i<count;++i) {
            const auto s=polygon[(i+count-1)%count], e=polygon[i];
            const bool s_in=side(lines[line],s)<=0, e_in=side(lines[line],e)<=0;
            if (s_in!=e_in) {
                Vertex crossing{};
                if (!intersect(lines[e.incoming],lines[line],crossing)) return -1;
                crossing.incoming=s_in ? e.incoming : line;
                append(next,used,crossing);
            }
            if (e_in) append(next,used,e);
        }
        if (used>1 && same(next[0],next[used-1])) { next[0].incoming=next[used-1].incoming; --used; }
        count=used; polygon=next;
        bool noncollinear=false;
        for (int i=0;i<count && count>=3;++i)
            if (turn(polygon[i],polygon[(i+1)%count],polygon[(i+2)%count])!=0) noncollinear=true;
        if (!noncollinear) count=0;
    }
    bool changed=true;
    while (changed && count>=3) {
        changed=false;
        for (int i=0;i<count;++i) {
            if (turn(polygon[(i+count-1)%count],polygon[i],polygon[(i+1)%count])==0) {
                for (int j=i;j+1<count;++j) polygon[j]=polygon[j+1];
                --count; changed=true; break;
            }
        }
    }
    if (count<3) count=0;
    int first=0;
    for (int i=1;i<count;++i) {
        const auto yi=polygon[i].y*polygon[first].den, yf=polygon[first].y*polygon[i].den;
        if (yi<yf || (yi==yf && polygon[i].x*polygon[first].den<polygon[first].x*polygon[i].den)) first=i;
    }
    const auto needed=static_cast<std::size_t>(1+4*count)*8;
    if (!output || capacity<needed) return -2;
    std::size_t offset=0; put(output,offset,count);
    for (int i=0;i<count;++i) {
        const auto p=polygon[(first+i)%count];
        const auto gx=gcd(p.x,p.den), gy=gcd(p.y,p.den);
        put(output,offset,p.x/gx); put(output,offset,p.den/gx);
        put(output,offset,p.y/gy); put(output,offset,p.den/gy);
    }
    return static_cast<std::int64_t>(needed);
}
