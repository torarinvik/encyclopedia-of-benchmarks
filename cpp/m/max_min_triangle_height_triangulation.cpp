#include <cstddef>
#include <cstdint>

namespace {
constexpr int min_n = 3, max_n = 5, max_length = 12, dp_size = 10, max_triangles = 3;
struct Point { std::int64_t x, y; };
struct Score { std::int64_t numerator, denominator; };
struct Cell { Score minimum; int count, valid, split; };
struct Triangle { int a, b, c; };
struct Triangles { Triangle items[max_triangles]; int count; };
struct Objective { Score minimum; int count; };

std::int64_t abs64(std::int64_t x) { return x < 0 ? -x : x; }
std::int64_t gcd64(std::int64_t a, std::int64_t b) {
    while (b != 0) { const auto r = a % b; a = b; b = r; }
    return a;
}
std::int64_t orient(Point a, Point b, Point c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
int compare(Score a, Score b) {
    const auto left = a.numerator * b.denominator;
    const auto right = b.numerator * a.denominator;
    return left < right ? -1 : left > right ? 1 : 0;
}
Score fraction(std::int64_t numerator, std::int64_t denominator) {
    const auto divisor = gcd64(numerator, denominator);
    return {numerator / divisor, denominator / divisor};
}
Score triangle_score(const Point points[max_n], int n, int a, int b, int c) {
    const Point p = points[a % n], q = points[b % n], r = points[c % n];
    const auto area2 = abs64(orient(p, q, r));
    const std::int64_t lengths[3] = {
        (p.x-q.x)*(p.x-q.x)+(p.y-q.y)*(p.y-q.y),
        (q.x-r.x)*(q.x-r.x)+(q.y-r.y)*(q.y-r.y),
        (r.x-p.x)*(r.x-p.x)+(r.y-p.y)*(r.y-p.y)};
    auto best = fraction(area2 * area2, lengths[0]);
    for (int i = 1; i < 3; ++i) {
        const auto candidate = fraction(area2 * area2, lengths[i]);
        if (compare(candidate, best) < 0) best = candidate;
    }
    return best;
}
Objective join(Cell left, Cell right, Score triangle) {
    Objective out{triangle, 1};
    const Cell children[2] = {left, right};
    for (const auto child : children) {
        if (!child.valid) continue;
        const int cmp = compare(child.minimum, out.minimum);
        if (cmp < 0) { out.minimum = child.minimum; out.count = child.count; }
        else if (cmp == 0) out.count += child.count;
    }
    return out;
}
bool better(Objective candidate, Objective current) {
    const int cmp = compare(candidate.minimum, current.minimum);
    return cmp > 0 || (cmp == 0 && candidate.count < current.count);
}
Objective evaluate(const Point points[max_n], int n, const Triangles &triangles) {
    auto t = triangles.items[0];
    Objective out{triangle_score(points, n, t.a, t.b, t.c), 1};
    for (int i = 1; i < triangles.count; ++i) {
        t = triangles.items[i];
        const auto score = triangle_score(points, n, t.a, t.b, t.c);
        const int cmp = compare(score, out.minimum);
        if (cmp < 0) { out.minimum = score; out.count = 1; }
        else if (cmp == 0) ++out.count;
    }
    return out;
}
void collect(int start, int end, const Cell *table, int n, Triangles &out) {
    if (end - start < 2) return;
    const int middle = table[start * dp_size + end].split;
    out.items[out.count++] = {start % n, middle % n, end % n};
    collect(start, middle, table, n, out);
    collect(middle, end, table, n, out);
}
bool has_edge(const Triangles &triangles, int left, int right) {
    for (int i = 0; i < triangles.count; ++i) {
        const auto t = triangles.items[i];
        const int pairs[3][2] = {{t.a,t.b},{t.b,t.c},{t.c,t.a}};
        for (const auto &pair : pairs) {
            const int a = pair[0] < pair[1] ? pair[0] : pair[1];
            const int b = pair[0] < pair[1] ? pair[1] : pair[0];
            if (a == left && b == right) return true;
        }
    }
    return false;
}
std::int64_t solve(const Point points[max_n], int n) {
    Cell table[dp_size * dp_size]{};
    for (int span = 2; span <= n - 2; ++span) {
        for (int start = 0; start < n; ++start) {
            const int end = start + span;
            Objective best_value{{0,1},0};
            int best_middle = -1;
            for (int middle = start + 1; middle < end; ++middle) {
                const auto candidate = join(table[start*dp_size+middle], table[middle*dp_size+end],
                                            triangle_score(points,n,start,middle,end));
                if (best_middle < 0 || better(candidate,best_value)) {
                    best_value = candidate; best_middle = middle;
                }
            }
            table[start*dp_size+end] = {best_value.minimum,best_value.count,1,best_middle};
        }
    }
    Triangles current{};
    for (int middle = 1; middle < n - 1; ++middle)
        current.items[current.count++] = {0,middle,middle+1};
    auto current_value = evaluate(points,n,current);
    int improvements = 0;
    for (;;) {
        bool changed = false;
        for (int left = 0; left < n && !changed; ++left) {
            for (int right = left + 2; right < n; ++right) {
                if (left == 0 && right == n - 1) continue;
                if (has_edge(current,left,right)) continue;
                Triangles candidate{};
                collect(left,right,table,n,candidate);
                collect(right,left+n,table,n,candidate);
                const auto value = evaluate(points,n,candidate);
                if (better(value,current_value)) {
                    current = candidate; current_value = value;
                    if (++improvements > 30) return -1;
                    changed = true; break;
                }
            }
        }
        if (!changed) return current_value.minimum.numerator * 513 + current_value.minimum.denominator;
    }
}
}

extern "C" std::int64_t max_min_triangle_height_triangulation(const std::int64_t *input,
                                                               std::size_t length) {
    if (input == nullptr || length < 1 || length > max_length) return -1;
    if (input[0] < min_n || input[0] > max_n) return -1;
    const int n = static_cast<int>(input[0]);
    if (length != static_cast<std::size_t>(1 + 2*n)) return -1;
    Point points[max_n]{};
    for (int i = 0; i < n; ++i) {
        points[i] = {input[1+2*i],input[2+2*i]};
        if (points[i].x < -8 || points[i].x > 8 || points[i].y < -8 || points[i].y > 8) return -1;
        for (int j = 0; j < i; ++j)
            if (points[i].x == points[j].x && points[i].y == points[j].y) return -1;
    }
    std::int64_t area2 = 0;
    for (int i = 0; i < n; ++i) {
        const int next = (i+1)%n;
        area2 += points[i].x*points[next].y-points[i].y*points[next].x;
    }
    if (area2 <= 0) return -1;
    for (int a=0;a<n;++a) for (int b=a+1;b<n;++b) for (int c=b+1;c<n;++c)
        if (orient(points[a],points[b],points[c]) == 0) return -1;
    for (int edge=0;edge<n;++edge) {
        const int next=(edge+1)%n;
        for (int v=0;v<n;++v)
            if (v!=edge && v!=next && orient(points[edge],points[next],points[v])<=0) return -1;
    }
    return solve(points,n);
}
