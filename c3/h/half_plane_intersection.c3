module half_plane_intersection;

const usz MAX_LINES = 16;
const usz MAX_INPUT = 37;
const long BOX_LIMIT = 256;
struct Halfplane { long a; long b; long c; }
struct Point { long x; long y; long den; }

fn long abs64(long x) { return x < 0 ? -x : x; }
fn long gcd64(long a, long b) {
    a = abs64(a); b = abs64(b);
    while (b != 0) { long r = a % b; a = b; b = r; }
    return a;
}
fn int angle_half(Halfplane h) { return h.b > 0 || (h.b == 0 && h.a >= 0) ? 0 : 1; }
fn int line_compare(Halfplane x, Halfplane y) {
    int hx = angle_half(x), hy = angle_half(y);
    if (hx != hy) return hx < hy ? -1 : 1;
    long turn = x.a * y.b - x.b * y.a;
    if (turn != 0) return turn > 0 ? -1 : 1;
    return x.c < y.c ? -1 : (x.c > y.c ? 1 : 0);
}
fn bool intersect(Halfplane x, Halfplane y, Point* p) {
    long det = x.a * y.b - y.a * x.b;
    if (det == 0) return false;
    long xn = x.c * y.b - x.b * y.c;
    long yn = x.a * y.c - x.c * y.a;
    if (det < 0) { det = -det; xn = -xn; yn = -yn; }
    long g = gcd64(gcd64(xn, yn), det);
    p.x = xn / g; p.y = yn / g; p.den = det / g;
    return true;
}
fn bool outside(Halfplane h, Point p) { return h.a * p.x + h.b * p.y > h.c * p.den; }
fn bool same_point(Point x, Point y) { return x.x * y.den == y.x * x.den && x.y * y.den == y.y * x.den; }
fn long orient(Point a, Point b, Point c) {
    long dx1 = b.x * a.den - a.x * b.den, dy1 = b.y * a.den - a.y * b.den;
    long dx2 = c.x * b.den - b.x * c.den, dy2 = c.y * b.den - b.y * c.den;
    return dx1 * dy2 - dy1 * dx2;
}
fn bool less_yx(Point a, Point b) {
    long y1 = a.y * b.den, y2 = b.y * a.den;
    if (y1 != y2) return y1 < y2;
    return a.x * b.den < b.x * a.den;
}
fn void put_i64(char* out, usz* offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) { out[*offset] = (char)(bits >> (8 * b)); (*offset)++; }
}

fn long half_plane_intersection(long* v, usz n, char* out, usz cap)
    @export("half_plane_intersection") {
    if (v == null || n < 1 || n > MAX_INPUT || v[0] < 0 || v[0] > 12) return -1;
    usz count = (usz)v[0];
    if (n != 1 + 3 * count) return -1;
    Halfplane[MAX_LINES] lines = {}, queue = {};
    Point[MAX_LINES] points = {}, clean = {};
    usz line_count = 0;
    for (usz i = 0; i < count; i++) {
        long a = v[1 + 3 * i], b = v[2 + 3 * i], c = v[3 + 3 * i];
        if (a < -16 || a > 16 || b < -16 || b > 16 || c < -128 || c > 128
            || (a == 0 && b == 0) || gcd64(a, b) != 1) return -1;
        lines[line_count++] = Halfplane{a, b, c};
    }
    lines[line_count++] = Halfplane{1, 0, BOX_LIMIT};
    lines[line_count++] = Halfplane{0, 1, BOX_LIMIT};
    lines[line_count++] = Halfplane{-1, 0, BOX_LIMIT};
    lines[line_count++] = Halfplane{0, -1, BOX_LIMIT};
    for (usz i = 1; i < line_count; i++) {
        Halfplane key = lines[i]; usz j = i;
        while (j > 0 && line_compare(key, lines[j - 1]) < 0) { lines[j] = lines[j - 1]; j--; }
        lines[j] = key;
    }
    usz reduced = 0;
    for (usz i = 0; i < line_count; i++) {
        if (reduced > 0 && lines[i].a == lines[reduced - 1].a && lines[i].b == lines[reduced - 1].b) continue;
        lines[reduced++] = lines[i];
    }
    usz head = 0, tail = 0;
    for (usz i = 0; i < reduced; i++) {
        Halfplane h = lines[i]; Point p;
        while (tail - head > 1) {
            if (!intersect(queue[tail - 2], queue[tail - 1], &p) || !outside(h, p)) break;
            tail--;
        }
        while (tail - head > 1) {
            if (!intersect(queue[head], queue[head + 1], &p) || !outside(h, p)) break;
            head++;
        }
        if (tail > head) {
            Halfplane last = queue[tail - 1];
            if (last.a * h.b - last.b * h.a == 0) {
                if (last.a * h.a + last.b * h.b < 0) { head = 0; tail = 0; break; }
                if (h.c < last.c) queue[tail - 1] = h;
                continue;
            }
        }
        queue[tail++] = h;
    }
    if (tail - head >= 3) {
        Point p;
        while (tail - head > 2 && intersect(queue[tail - 2], queue[tail - 1], &p) && outside(queue[head], p)) tail--;
        while (tail - head > 2 && intersect(queue[head], queue[head + 1], &p) && outside(queue[tail - 1], p)) head++;
    }
    usz point_count = 0;
    if (tail - head >= 3) for (usz i = head; i < tail; i++) {
        Point p;
        if (!intersect(queue[i], queue[i + 1 == tail ? head : i + 1], &p)) { point_count = 0; break; }
        points[point_count++] = p;
    }
    usz clean_count = 0;
    for (usz i = 0; i < point_count; i++)
        if (clean_count == 0 || !same_point(clean[clean_count - 1], points[i])) clean[clean_count++] = points[i];
    if (clean_count > 1 && same_point(clean[0], clean[clean_count - 1])) clean_count--;
    bool changed = true;
    while (changed && clean_count >= 3) {
        changed = false;
        for (usz i = 0; i < clean_count; i++) {
            usz prev = (i + clean_count - 1) % clean_count, next = (i + 1) % clean_count;
            if (orient(clean[prev], clean[i], clean[next]) == 0) {
                for (usz j = i; j + 1 < clean_count; j++) clean[j] = clean[j + 1];
                clean_count--; changed = true; break;
            }
        }
    }
    if (clean_count < 3) clean_count = 0;
    if (clean_count > 0) {
        usz first = 0;
        for (usz i = 1; i < clean_count; i++) if (less_yx(clean[i], clean[first])) first = i;
        Point[MAX_LINES] rotated = {};
        for (usz i = 0; i < clean_count; i++) rotated[i] = clean[(first + i) % clean_count];
        for (usz i = 0; i < clean_count; i++) clean[i] = rotated[i];
    }
    usz needed = (1 + 4 * clean_count) * 8;
    if (needed > cap || out == null) return -2;
    usz offset = 0; put_i64(out, &offset, (long)clean_count);
    for (usz i = 0; i < clean_count; i++) {
        long gx = gcd64(clean[i].x, clean[i].den), gy = gcd64(clean[i].y, clean[i].den);
        put_i64(out, &offset, clean[i].x / gx); put_i64(out, &offset, clean[i].den / gx);
        put_i64(out, &offset, clean[i].y / gy); put_i64(out, &offset, clean[i].den / gy);
    }
    return (long)needed;
}
