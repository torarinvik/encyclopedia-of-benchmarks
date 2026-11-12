#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <numeric>

namespace {
constexpr std::size_t max_lines = 16, max_input = 37;
constexpr std::int64_t box_limit = 256;
struct Halfplane { std::int64_t a, b, c; };
struct Point { std::int64_t x, y, den; };
std::int64_t abs64(std::int64_t x) { return x < 0 ? -x : x; }
std::int64_t gcd64(std::int64_t a, std::int64_t b) { return std::gcd(abs64(a), abs64(b)); }
int angle_half(Halfplane h) { return h.b > 0 || (h.b == 0 && h.a >= 0) ? 0 : 1; }
bool angle_less(Halfplane x, Halfplane y) {
    int hx = angle_half(x), hy = angle_half(y);
    if (hx != hy) return hx < hy;
    auto turn = x.a * y.b - x.b * y.a;
    if (turn != 0) return turn > 0;
    return x.c < y.c;
}
bool intersect(Halfplane x, Halfplane y, Point& p) {
    auto det = x.a * y.b - y.a * x.b;
    if (det == 0) return false;
    auto xn = x.c * y.b - x.b * y.c, yn = x.a * y.c - x.c * y.a;
    if (det < 0) { det = -det; xn = -xn; yn = -yn; }
    auto g = gcd64(gcd64(xn, yn), det);
    p = {xn / g, yn / g, det / g};
    return true;
}
bool outside(Halfplane h, Point p) { return h.a * p.x + h.b * p.y > h.c * p.den; }
bool same(Point x, Point y) { return x.x * y.den == y.x * x.den && x.y * y.den == y.y * x.den; }
std::int64_t orient(Point a, Point b, Point c) {
    auto dx1 = b.x * a.den - a.x * b.den, dy1 = b.y * a.den - a.y * b.den;
    auto dx2 = c.x * b.den - b.x * c.den, dy2 = c.y * b.den - b.y * c.den;
    return dx1 * dy2 - dy1 * dx2;
}
bool less_yx(Point a, Point b) {
    auto y1 = a.y * b.den, y2 = b.y * a.den;
    return y1 == y2 ? a.x * b.den < b.x * a.den : y1 < y2;
}
void put_i64(std::uint8_t* out, std::size_t& offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[offset++] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t half_plane_intersection(const std::int64_t* v, std::size_t n,
        std::uint8_t* out, std::size_t cap) noexcept {
    if (!v || n < 1 || n > max_input || v[0] < 0 || v[0] > 12) return -1;
    auto count = static_cast<std::size_t>(v[0]);
    if (n != 1 + 3 * count) return -1;
    Halfplane lines[max_lines], queue[max_lines];
    Point points[max_lines], clean[max_lines];
    std::size_t line_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        auto a = v[1 + 3 * i], b = v[2 + 3 * i], c = v[3 + 3 * i];
        if (a < -16 || a > 16 || b < -16 || b > 16 || c < -128 || c > 128
                || (a == 0 && b == 0) || gcd64(a, b) != 1) return -1;
        lines[line_count++] = {a, b, c};
    }
    lines[line_count++] = {1, 0, box_limit}; lines[line_count++] = {0, 1, box_limit};
    lines[line_count++] = {-1, 0, box_limit}; lines[line_count++] = {0, -1, box_limit};
    std::sort(lines, lines + line_count, angle_less);
    std::size_t reduced = 0;
    for (std::size_t i = 0; i < line_count; ++i) {
        if (reduced && lines[i].a == lines[reduced - 1].a && lines[i].b == lines[reduced - 1].b) continue;
        lines[reduced++] = lines[i];
    }
    std::size_t head = 0, tail = 0;
    for (std::size_t i = 0; i < reduced; ++i) {
        auto h = lines[i]; Point p;
        while (tail - head > 1 && intersect(queue[tail - 2], queue[tail - 1], p) && outside(h, p)) --tail;
        while (tail - head > 1 && intersect(queue[head], queue[head + 1], p) && outside(h, p)) ++head;
        if (tail > head) {
            auto last = queue[tail - 1];
            if (last.a * h.b - last.b * h.a == 0) {
                if (last.a * h.a + last.b * h.b < 0) { head = tail = 0; break; }
                if (h.c < last.c) queue[tail - 1] = h;
                continue;
            }
        }
        queue[tail++] = h;
    }
    if (tail - head >= 3) {
        Point p;
        while (tail - head > 2 && intersect(queue[tail - 2], queue[tail - 1], p) && outside(queue[head], p)) --tail;
        while (tail - head > 2 && intersect(queue[head], queue[head + 1], p) && outside(queue[tail - 1], p)) ++head;
    }
    std::size_t point_count = 0;
    if (tail - head >= 3) for (std::size_t i = head; i < tail; ++i) {
        Point p;
        if (!intersect(queue[i], queue[i + 1 == tail ? head : i + 1], p)) { point_count = 0; break; }
        points[point_count++] = p;
    }
    std::size_t clean_count = 0;
    for (std::size_t i = 0; i < point_count; ++i)
        if (!clean_count || !same(clean[clean_count - 1], points[i])) clean[clean_count++] = points[i];
    if (clean_count > 1 && same(clean[0], clean[clean_count - 1])) --clean_count;
    bool changed = true;
    while (changed && clean_count >= 3) {
        changed = false;
        for (std::size_t i = 0; i < clean_count; ++i) {
            auto prev = (i + clean_count - 1) % clean_count, next = (i + 1) % clean_count;
            if (orient(clean[prev], clean[i], clean[next]) == 0) {
                for (std::size_t j = i; j + 1 < clean_count; ++j) clean[j] = clean[j + 1];
                --clean_count; changed = true; break;
            }
        }
    }
    if (clean_count < 3) clean_count = 0;
    if (clean_count) {
        std::size_t first = 0;
        for (std::size_t i = 1; i < clean_count; ++i) if (less_yx(clean[i], clean[first])) first = i;
        Point rotated[max_lines];
        for (std::size_t i = 0; i < clean_count; ++i) rotated[i] = clean[(first + i) % clean_count];
        for (std::size_t i = 0; i < clean_count; ++i) clean[i] = rotated[i];
    }
    auto needed = (1 + 4 * clean_count) * 8;
    if (needed > cap || !out) return -2;
    std::size_t offset = 0; put_i64(out, offset, static_cast<std::int64_t>(clean_count));
    for (std::size_t i = 0; i < clean_count; ++i) {
        auto gx = gcd64(clean[i].x, clean[i].den), gy = gcd64(clean[i].y, clean[i].den);
        put_i64(out, offset, clean[i].x / gx); put_i64(out, offset, clean[i].den / gx);
        put_i64(out, offset, clean[i].y / gy); put_i64(out, offset, clean[i].den / gy);
    }
    return static_cast<std::int64_t>(needed);
}
