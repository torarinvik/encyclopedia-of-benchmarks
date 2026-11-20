#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 8;
constexpr std::size_t max_length = 19;
struct Point { std::int64_t x, y; };

std::int64_t floor_div(std::int64_t a, std::int64_t b) {
    const auto q = a / b, r = a % b;
    return q - (r < 0 ? 1 : 0);
}
std::int64_t ceil_div(std::int64_t a, std::int64_t b) { return -floor_div(-a, b); }

std::int64_t floor_sum(std::int64_t n, std::int64_t m,
                       std::int64_t a, std::int64_t b) {
    const auto aq = floor_div(a, m), bq = floor_div(b, m);
    std::int64_t answer = aq*n*(n-1)/2 + bq*n;
    a -= aq*m; b -= bq*m;
    for (;;) {
        if (a >= m) { answer += (n-1)*n*(a/m)/2; a %= m; }
        if (b >= m) { answer += n*(b/m); b %= m; }
        const auto top = a*n+b;
        if (top < m) return answer;
        n = top/m; b = top%m;
        const auto t = m; m = a; a = t;
    }
}

std::int64_t edge_chunk(std::int64_t scale, Point a, std::int64_t dx,
                        std::int64_t dy, std::int64_t start,
                        std::int64_t columns) {
    if (columns <= 0) return 0;
    auto aa=dy*scale, bb=a.y*dx-dy*a.x, den=scale*dx;
    if (den<0) { aa=-aa; bb=-bb; den=-den; }
    const auto base=aa*start+bb;
    if (dx>0) return -floor_sum(columns,den,aa,base);
    return -floor_sum(columns,den,-aa,-base)-columns;
}

bool strictly_inside(const Point* p, std::int64_t n, std::int64_t scale,
                     std::int64_t x, std::int64_t y) {
    const auto px=x*scale, py=y*scale;
    bool inside=false;
    for (std::int64_t i=0; i<n; ++i) {
        const auto a=p[i], b=p[(i+1)%n];
        const auto cross=(b.x-a.x)*(py-a.y)-(b.y-a.y)*(px-a.x);
        if (cross==0 && px>=(a.x<b.x?a.x:b.x) && px<=(a.x>b.x?a.x:b.x) &&
            py>=(a.y<b.y?a.y:b.y) && py<=(a.y>b.y?a.y:b.y)) return false;
        if ((a.y>py)!=(b.y>py)) {
            const auto dy=b.y-a.y, dx=b.x-a.x;
            const auto left=a.x*dy+(py-a.y)*dx, right=px*dy;
            if ((dy>0 && left>right) || (dy<0 && left<right)) inside=!inside;
        }
    }
    return inside;
}

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > max_length) return -1;
    const auto scale = input[0], n = input[1];
    if (scale < 2 || scale > 8 || n < 3 || n > max_n || length != static_cast<std::size_t>(2+2*n)) return -1;
    Point p[max_n]; bool fractional = false;
    for (std::int64_t i=0; i<n; ++i) {
        p[i] = {input[2+2*i], input[3+2*i]};
        if (p[i].x < -32 || p[i].x > 32 || p[i].y < -32 || p[i].y > 32) return -1;
        if (p[i].x < -4*scale || p[i].x > 4*scale || p[i].y < -4*scale || p[i].y > 4*scale) return -1;
        fractional |= p[i].x%scale != 0 || p[i].y%scale != 0;
        for (std::int64_t j=0; j<i; ++j)
            if (p[i].x == p[j].x && p[i].y == p[j].y) return -1;
    }
    if (!fractional) return -1;
    std::int64_t area2 = 0;
    for (std::int64_t i=0; i<n; ++i) {
        const auto a=p[i], b=p[(i+1)%n]; area2 += a.x*b.y-a.y*b.x;
    }
    if (area2 == 0) return -1;
    const std::int64_t orientation = area2 > 0 ? 1 : -1;
    for (std::int64_t i=0; i<n; ++i) {
        const auto a=p[i], b=p[(i+1)%n];
        for (std::int64_t j=0; j<n; ++j) {
            if (j==i || j==(i+1)%n) continue;
            const auto c=p[j];
            const auto cross=(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
            if (cross*orientation <= 0) return -1;
        }
    }
    std::int64_t signed_count=0;
    for (std::int64_t i=0; i<n; ++i) {
        const auto a=p[i], b=p[(i+1)%n];
        const auto dx=b.x-a.x, dy=b.y-a.y;
        if (dx==0) continue;
        const auto lo=a.x<b.x?a.x:b.x, hi=a.x>b.x?a.x:b.x;
        const auto start=ceil_div(lo,scale), columns=ceil_div(hi,scale)-start;
        const auto stop=start+columns;
        auto cursor=start;
        for (auto col=start; col<stop; ++col) {
            bool event=false;
            for (std::int64_t k=0; k<n; ++k) if (p[k].x==col*scale) event=true;
            if (event) { signed_count+=edge_chunk(scale,a,dx,dy,cursor,col-cursor); cursor=col+1; }
        }
        signed_count+=edge_chunk(scale,a,dx,dy,cursor,stop-cursor);
    }
    for (std::int64_t i=0; i<n; ++i) {
        if (p[i].x%scale!=0) continue;
        bool first=true;
        for (std::int64_t j=0; j<i; ++j) if (p[j].x==p[i].x) first=false;
        if (!first) continue;
        const auto x=p[i].x/scale;
        std::int64_t count=0;
        for (std::int64_t y=-4; y<=4; ++y) count+=strictly_inside(p,n,scale,x,y);
        signed_count+=orientation*count;
    }
    const auto result=signed_count*orientation;
    return result>=0?result:-1;
}
} // namespace

extern "C" std::int64_t rational_polygon_lattice_points(
    const std::int64_t* input, std::size_t length) noexcept {
    return solve(input, length);
}
