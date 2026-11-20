/* Independently authored draft; not compiled or run. */
#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t x, y; } MecPoint;
typedef struct { int64_t x, y, den, radius2; } MecCircle;

static int64_t mec_distance(MecCircle c, MecPoint p) {
    int64_t dx = p.x*c.den - c.x, dy = p.y*c.den - c.y;
    return dx*dx + dy*dy;
}
static MecCircle mec_point(MecPoint p) {
    return (MecCircle){p.x, p.y, 1, 0};
}
static MecCircle mec_pair(MecPoint a, MecPoint b) {
    MecCircle c = {a.x+b.x, a.y+b.y, 2, 0};
    c.radius2 = mec_distance(c, a);
    return c;
}
static MecCircle mec_triple(MecPoint a, MecPoint b, MecPoint c) {
    int64_t den = 2*(a.x*(b.y-c.y) + b.x*(c.y-a.y) + c.x*(a.y-b.y));
    if (den == 0) {
        MecCircle ab = mec_pair(a,b), ac = mec_pair(a,c), bc = mec_pair(b,c);
        if (ab.radius2 >= ac.radius2 && ab.radius2 >= bc.radius2) return ab;
        return ac.radius2 >= bc.radius2 ? ac : bc;
    }
    int64_t aa = a.x*a.x+a.y*a.y, bb = b.x*b.x+b.y*b.y, cc = c.x*c.x+c.y*c.y;
    int64_t x = aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y);
    int64_t y = aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x);
    if (den < 0) { den = -den; x = -x; y = -y; }
    MecCircle circle = {x, y, den, 0};
    circle.radius2 = mec_distance(circle, a);
    return circle;
}

int64_t minimum_enclosing_circle_incremental_boundary(const int64_t *input,
        size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 4 || length > 194 || input[0] < 1 || input[0] > 64) return -1;
    size_t n = (size_t)input[0];
    if (length != 1 + 3*n) return -1;
    MecPoint points[64];
    size_t order[64];
    uint8_t seen[64] = {0};
    for (size_t i = 0; i < n; ++i) {
        int64_t x = input[1+2*i], y = input[2+2*i];
        if (x < -100 || x > 100 || y < -100 || y > 100) return -1;
        points[i] = (MecPoint){x,y};
    }
    for (size_t i = 0; i < n; ++i) {
        int64_t v = input[1+2*n+i];
        if (v < 0 || v >= (int64_t)n || seen[v]) return -1;
        seen[v] = 1; order[i] = (size_t)v;
    }
    if (!output || capacity < n) return -2;
    MecCircle circle = mec_point(points[order[0]]);
    for (size_t i = 1; i < n; ++i) {
        MecPoint a = points[order[i]];
        if (mec_distance(circle, a) <= circle.radius2) continue;
        circle = mec_point(a);
        for (size_t j = 0; j < i; ++j) {
            MecPoint b = points[order[j]];
            if (mec_distance(circle, b) <= circle.radius2) continue;
            circle = mec_pair(a,b);
            for (size_t k = 0; k < j; ++k) {
                MecPoint c = points[order[k]];
                if (mec_distance(circle, c) > circle.radius2) circle = mec_triple(a,b,c);
            }
        }
    }
    for (size_t i = 0; i < n; ++i) output[i] = mec_distance(circle, points[i]) == circle.radius2;
    return (int64_t)n;
}
