// Independently authored draft; not compiled or run.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
struct Point { std::int64_t x, y; };
struct Circle { std::int64_t x, y, den, radius2; };
std::int64_t distance(Circle c, Point p) {
    const auto dx = p.x*c.den-c.x, dy = p.y*c.den-c.y;
    return dx*dx + dy*dy;
}
Circle point_circle(Point p) { return {p.x, p.y, 1, 0}; }
Circle pair_circle(Point a, Point b) {
    Circle result{a.x+b.x, a.y+b.y, 2, 0};
    result.radius2 = distance(result, a);
    return result;
}
Circle triple_circle(Point a, Point b, Point c) {
    auto den = 2*(a.x*(b.y-c.y) + b.x*(c.y-a.y) + c.x*(a.y-b.y));
    if (den == 0) {
        const auto ab = pair_circle(a,b), ac = pair_circle(a,c), bc = pair_circle(b,c);
        if (ab.radius2 >= ac.radius2 && ab.radius2 >= bc.radius2) return ab;
        return ac.radius2 >= bc.radius2 ? ac : bc;
    }
    const auto aa = a.x*a.x+a.y*a.y, bb = b.x*b.x+b.y*b.y, cc = c.x*c.x+c.y*c.y;
    auto x = aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y);
    auto y = aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x);
    if (den < 0) { den = -den; x = -x; y = -y; }
    Circle result{x,y,den,0};
    result.radius2 = distance(result, a);
    return result;
}
}

extern "C" std::int64_t minimum_enclosing_circle_incremental_boundary(
        const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 4 || length > 194 || input[0] < 1 || input[0] > 64) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 3*n) return -1;
    std::array<Point,64> points{};
    std::array<std::size_t,64> order{};
    std::array<bool,64> seen{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto x = input[1+2*i], y = input[2+2*i];
        if (x < -100 || x > 100 || y < -100 || y > 100) return -1;
        points[i] = {x,y};
    }
    for (std::size_t i = 0; i < n; ++i) {
        const auto v = input[1+2*n+i];
        if (v < 0 || v >= static_cast<std::int64_t>(n) || seen[static_cast<std::size_t>(v)]) return -1;
        order[i] = static_cast<std::size_t>(v); seen[order[i]] = true;
    }
    if (!output || capacity < n) return -2;
    auto circle = point_circle(points[order[0]]);
    for (std::size_t i = 1; i < n; ++i) {
        const auto a = points[order[i]];
        if (distance(circle, a) <= circle.radius2) continue;
        circle = point_circle(a);
        for (std::size_t j = 0; j < i; ++j) {
            const auto b = points[order[j]];
            if (distance(circle, b) <= circle.radius2) continue;
            circle = pair_circle(a,b);
            for (std::size_t k = 0; k < j; ++k) {
                const auto c = points[order[k]];
                if (distance(circle,c) > circle.radius2) circle = triple_circle(a,b,c);
            }
        }
    }
    for (std::size_t i = 0; i < n; ++i) output[i] = distance(circle, points[i]) == circle.radius2;
    return static_cast<std::int64_t>(n);
}
