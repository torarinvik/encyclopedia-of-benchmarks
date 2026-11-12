#include <stddef.h>
#include <stdint.h>

#define MAX_CONSTRAINTS 12
#define MAX_LINES 16
#define MAX_INPUT 37
#define MAX_OUTPUT_BYTES 520
#define BOX_LIMIT INT64_C(256)

typedef struct { int64_t a, b, c; } halfplane;
typedef struct { int64_t x, y, den; } rational_point;

static int64_t abs64(int64_t x) { return x < 0 ? -x : x; }
static int64_t gcd64(int64_t a, int64_t b) {
    a = abs64(a); b = abs64(b);
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a;
}
static int angle_half(halfplane h) { return h.b > 0 || (h.b == 0 && h.a >= 0) ? 0 : 1; }
static int line_compare(halfplane x, halfplane y) {
    int hx = angle_half(x), hy = angle_half(y);
    if (hx != hy) return hx < hy ? -1 : 1;
    int64_t turn = x.a * y.b - x.b * y.a;
    if (turn != 0) return turn > 0 ? -1 : 1;
    return x.c < y.c ? -1 : (x.c > y.c ? 1 : 0);
}
static int intersect(halfplane x, halfplane y, rational_point *p) {
    int64_t det = x.a * y.b - y.a * x.b;
    if (det == 0) return 0;
    int64_t xn = x.c * y.b - x.b * y.c;
    int64_t yn = x.a * y.c - x.c * y.a;
    if (det < 0) { det = -det; xn = -xn; yn = -yn; }
    int64_t g = gcd64(gcd64(xn, yn), det);
    p->x = xn / g; p->y = yn / g; p->den = det / g;
    return 1;
}
static int outside(halfplane h, rational_point p) {
    return h.a * p.x + h.b * p.y > h.c * p.den;
}
static int same_point(rational_point x, rational_point y) {
    return x.x * y.den == y.x * x.den && x.y * y.den == y.y * x.den;
}
static int64_t orient(rational_point a, rational_point b, rational_point c) {
    int64_t dx1 = b.x * a.den - a.x * b.den;
    int64_t dy1 = b.y * a.den - a.y * b.den;
    int64_t dx2 = c.x * b.den - b.x * c.den;
    int64_t dy2 = c.y * b.den - b.y * c.den;
    return dx1 * dy2 - dy1 * dx2;
}
static int less_yx(rational_point a, rational_point b) {
    int64_t y1 = a.y * b.den, y2 = b.y * a.den;
    if (y1 != y2) return y1 < y2;
    return a.x * b.den < b.x * a.den;
}
static void put_i64(uint8_t *out, size_t *offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[(*offset)++] = (uint8_t)(bits >> (8 * b));
}

int64_t half_plane_intersection(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n < 1 || n > MAX_INPUT || v[0] < 0 || v[0] > MAX_CONSTRAINTS) return -1;
    size_t count = (size_t)v[0];
    if (n != 1 + 3 * count) return -1;
    halfplane lines[MAX_LINES], queue[MAX_LINES];
    rational_point points[MAX_LINES], clean[MAX_LINES];
    size_t line_count = 0;
    for (size_t i = 0; i < count; ++i) {
        int64_t a = v[1 + 3 * i], b = v[2 + 3 * i], c = v[3 + 3 * i];
        if (a < -16 || a > 16 || b < -16 || b > 16 || c < -128 || c > 128) return -1;
        if ((a == 0 && b == 0) || gcd64(a, b) != 1) return -1;
        lines[line_count++] = (halfplane){a, b, c};
    }
    lines[line_count++] = (halfplane){1, 0, BOX_LIMIT};
    lines[line_count++] = (halfplane){0, 1, BOX_LIMIT};
    lines[line_count++] = (halfplane){-1, 0, BOX_LIMIT};
    lines[line_count++] = (halfplane){0, -1, BOX_LIMIT};
    for (size_t i = 1; i < line_count; ++i) {
        halfplane key = lines[i]; size_t j = i;
        while (j > 0 && line_compare(key, lines[j - 1]) < 0) { lines[j] = lines[j - 1]; --j; }
        lines[j] = key;
    }
    size_t reduced = 0;
    for (size_t i = 0; i < line_count; ++i) {
        if (reduced && lines[i].a == lines[reduced - 1].a && lines[i].b == lines[reduced - 1].b) continue;
        lines[reduced++] = lines[i];
    }
    size_t head = 0, tail = 0;
    for (size_t i = 0; i < reduced; ++i) {
        halfplane h = lines[i]; rational_point p;
        while (tail - head > 1) {
            if (!intersect(queue[tail - 2], queue[tail - 1], &p) || !outside(h, p)) break;
            --tail;
        }
        while (tail - head > 1) {
            if (!intersect(queue[head], queue[head + 1], &p) || !outside(h, p)) break;
            ++head;
        }
        if (tail > head) {
            halfplane last = queue[tail - 1];
            int64_t turn = last.a * h.b - last.b * h.a;
            if (turn == 0) {
                if (last.a * h.a + last.b * h.b < 0) { head = tail = 0; break; }
                if (h.c < last.c) queue[tail - 1] = h;
                continue;
            }
        }
        queue[tail++] = h;
    }
    if (tail - head >= 3) {
        rational_point p;
        while (tail - head > 2 && intersect(queue[tail - 2], queue[tail - 1], &p) && outside(queue[head], p)) --tail;
        while (tail - head > 2 && intersect(queue[head], queue[head + 1], &p) && outside(queue[tail - 1], p)) ++head;
    }
    size_t point_count = 0;
    if (tail - head >= 3) {
        for (size_t i = head; i < tail; ++i) {
            rational_point p;
            if (!intersect(queue[i], queue[(i + 1 == tail) ? head : i + 1], &p)) { point_count = 0; break; }
            points[point_count++] = p;
        }
    }
    size_t clean_count = 0;
    for (size_t i = 0; i < point_count; ++i)
        if (!clean_count || !same_point(clean[clean_count - 1], points[i])) clean[clean_count++] = points[i];
    if (clean_count > 1 && same_point(clean[0], clean[clean_count - 1])) --clean_count;
    int changed = 1;
    while (changed && clean_count >= 3) {
        changed = 0;
        for (size_t i = 0; i < clean_count; ++i) {
            size_t prev = (i + clean_count - 1) % clean_count, next = (i + 1) % clean_count;
            if (orient(clean[prev], clean[i], clean[next]) == 0) {
                for (size_t j = i; j + 1 < clean_count; ++j) clean[j] = clean[j + 1];
                --clean_count; changed = 1; break;
            }
        }
    }
    if (clean_count < 3) clean_count = 0;
    if (clean_count) {
        size_t first = 0;
        for (size_t i = 1; i < clean_count; ++i) if (less_yx(clean[i], clean[first])) first = i;
        rational_point rotated[MAX_LINES];
        for (size_t i = 0; i < clean_count; ++i) rotated[i] = clean[(first + i) % clean_count];
        for (size_t i = 0; i < clean_count; ++i) clean[i] = rotated[i];
    }
    size_t needed = (1 + 4 * clean_count) * 8;
    if (needed > cap || !out) return -2;
    size_t offset = 0; put_i64(out, &offset, (int64_t)clean_count);
    for (size_t i = 0; i < clean_count; ++i) {
        int64_t gx = gcd64(clean[i].x, clean[i].den), gy = gcd64(clean[i].y, clean[i].den);
        put_i64(out, &offset, clean[i].x / gx); put_i64(out, &offset, clean[i].den / gx);
        put_i64(out, &offset, clean[i].y / gy); put_i64(out, &offset, clean[i].den / gy);
    }
    return (int64_t)needed;
}
