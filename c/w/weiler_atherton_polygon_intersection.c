#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 6
#define MAX_CROSSINGS (MAX_VERTICES * MAX_VERTICES)
#define MAX_NODES (MAX_VERTICES + MAX_CROSSINGS)
#define MAX_OUTPUT_WORDS 210

typedef struct { int64_t n, d; } Rat;
typedef struct { int64_t xn, xd, yn, yd; } Point;
typedef struct { Point point; int crossing; } Node;
typedef struct {
    Point point;
    Rat ta, tb;
    int edge_a, edge_b;
    int a_entry, a_exit, b_entry, b_exit;
} Crossing;
typedef struct { Point points[48]; int count; } Ring;

static int64_t abs_i64(int64_t value) { return value < 0 ? -value : value; }

static int64_t gcd_i64(int64_t a, int64_t b) {
    a = abs_i64(a); b = abs_i64(b);
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a == 0 ? 1 : a;
}

static Rat rat_make(int64_t n, int64_t d) {
    if (d < 0) { n = -n; d = -d; }
    int64_t g = gcd_i64(n, d);
    Rat r = { n / g, d / g };
    return r;
}

static Point integer_point(int64_t x, int64_t y) {
    Point p = {x, 1, y, 1}; return p;
}

static int64_t orient(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                      int64_t cx, int64_t cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

static int on_segment(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                      int64_t px, int64_t py) {
    return orient(ax, ay, bx, by, px, py) == 0
        && px >= (ax < bx ? ax : bx) && px <= (ax > bx ? ax : bx)
        && py >= (ay < by ? ay : by) && py <= (ay > by ? ay : by);
}

/* 0 = disjoint, 1 = proper crossing, 2 = touching or collinear overlap. */
static int segment_relation(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                           int64_t cx, int64_t cy, int64_t dx, int64_t dy) {
    int64_t o1 = orient(ax, ay, bx, by, cx, cy);
    int64_t o2 = orient(ax, ay, bx, by, dx, dy);
    int64_t o3 = orient(cx, cy, dx, dy, ax, ay);
    int64_t o4 = orient(cx, cy, dx, dy, bx, by);
    if (((o1 > 0 && o2 < 0) || (o1 < 0 && o2 > 0))
        && ((o3 > 0 && o4 < 0) || (o3 < 0 && o4 > 0))) return 1;
    if ((o1 == 0 && on_segment(ax, ay, bx, by, cx, cy))
        || (o2 == 0 && on_segment(ax, ay, bx, by, dx, dy))
        || (o3 == 0 && on_segment(cx, cy, dx, dy, ax, ay))
        || (o4 == 0 && on_segment(cx, cy, dx, dy, bx, by))) return 2;
    return 0;
}

static int point_less(Point a, Point b) {
    int64_t left = a.xn * b.xd, right = b.xn * a.xd;
    if (left != right) return left < right;
    return a.yn * b.yd < b.yn * a.yd;
}

static int point_equal(Point a, Point b) {
    return a.xn == b.xn && a.xd == b.xd && a.yn == b.yn && a.yd == b.yd;
}

static int point_sequence_less(const Ring *a, const Ring *b) {
    int count = a->count < b->count ? a->count : b->count;
    for (int i = 0; i < count; ++i) {
        if (point_equal(a->points[i], b->points[i])) continue;
        return point_less(a->points[i], b->points[i]);
    }
    return a->count < b->count;
}

static int polygon_valid(int64_t polygon[MAX_VERTICES][2], int n) {
    int64_t area2 = 0;
    for (int i = 0; i < n; ++i) {
        int next = (i + 1) % n;
        area2 += polygon[i][0] * polygon[next][1] - polygon[i][1] * polygon[next][0];
        if (orient(polygon[(i + n - 1) % n][0], polygon[(i + n - 1) % n][1],
                   polygon[i][0], polygon[i][1], polygon[next][0], polygon[next][1]) == 0) return 0;
        for (int j = 0; j < i; ++j)
            if (polygon[i][0] == polygon[j][0] && polygon[i][1] == polygon[j][1]) return 0;
    }
    if (area2 <= 0) return 0;
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {
            if (j == i + 1 || (i == 0 && j == n - 1)) continue;
            int relation = segment_relation(
                polygon[i][0], polygon[i][1], polygon[(i + 1) % n][0], polygon[(i + 1) % n][1],
                polygon[j][0], polygon[j][1], polygon[(j + 1) % n][0], polygon[(j + 1) % n][1]);
            if (relation != 0) return 0;
        }
    }
    return 1;
}

static int inside_integer(int64_t x, int64_t y,
                          int64_t polygon[MAX_VERTICES][2], int n) {
    int winding = 0;
    for (int i = 0; i < n; ++i) {
        int j = (i + 1) % n;
        int64_t side = orient(polygon[i][0], polygon[i][1], polygon[j][0], polygon[j][1], x, y);
        if (polygon[i][1] <= y && y < polygon[j][1] && side > 0) ++winding;
        else if (polygon[j][1] <= y && y < polygon[i][1] && side < 0) --winding;
    }
    return winding != 0;
}

static int rat_less(Rat a, Rat b) { return a.n * b.d < b.n * a.d; }

static Point crossing_point(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                            int64_t cx, int64_t cy, int64_t dx, int64_t dy,
                            Rat *ta, Rat *tb) {
    int64_t rx = bx - ax, ry = by - ay, sx = dx - cx, sy = dy - cy;
    int64_t den = rx * sy - ry * sx;
    int64_t tnum = (cx - ax) * sy - (cy - ay) * sx;
    int64_t unum = (cx - ax) * ry - (cy - ay) * rx;
    if (den < 0) { den = -den; tnum = -tnum; unum = -unum; }
    *ta = rat_make(tnum, den); *tb = rat_make(unum, den);
    Point p = {0};
    Rat x = rat_make(ax * den + rx * tnum, den);
    Rat y = rat_make(ay * den + ry * tnum, den);
    p.xn = x.n; p.xd = x.d; p.yn = y.n; p.yd = y.d;
    return p;
}

static void build_nodes(int64_t polygon[MAX_VERTICES][2], int n,
                        Crossing crossings[MAX_CROSSINGS], int count,
                        int is_a, Node nodes[MAX_NODES], int *node_count,
                        int index[MAX_CROSSINGS], int events[MAX_VERTICES][MAX_VERTICES],
                        int event_counts[MAX_VERTICES]) {
    *node_count = 0;
    for (int edge = 0; edge < n; ++edge) {
        nodes[*node_count].point = integer_point(polygon[edge][0], polygon[edge][1]);
        nodes[*node_count].crossing = -1;
        ++*node_count;
        for (int i = 1; i < event_counts[edge]; ++i) {
            int key = events[edge][i], j = i - 1;
            Rat kt = is_a ? crossings[key].ta : crossings[key].tb;
            while (j >= 0) {
                int prior = events[edge][j];
                Rat pt = is_a ? crossings[prior].ta : crossings[prior].tb;
                if (!rat_less(kt, pt)) break;
                events[edge][j + 1] = prior; --j;
            }
            events[edge][j + 1] = key;
        }
        for (int i = 0; i < event_counts[edge]; ++i) {
            int cid = events[edge][i];
            nodes[*node_count].point = crossings[cid].point;
            nodes[*node_count].crossing = cid;
            index[cid] = *node_count;
            ++*node_count;
        }
    }
    (void)count;
}

static int canonicalize(Ring rings[16], int ring_count) {
    for (int r = 0; r < ring_count; ++r) {
        int pivot = 0;
        for (int i = 1; i < rings[r].count; ++i)
            if (point_less(rings[r].points[i], rings[r].points[pivot])) pivot = i;
        if (pivot != 0) {
            Point temp[48];
            for (int i = 0; i < rings[r].count; ++i)
                temp[i] = rings[r].points[(pivot + i) % rings[r].count];
            for (int i = 0; i < rings[r].count; ++i) rings[r].points[i] = temp[i];
        }
    }
    for (int i = 1; i < ring_count; ++i) {
        Ring key = rings[i]; int j = i - 1;
        while (j >= 0 && point_sequence_less(&key, &rings[j])) {
            rings[j + 1] = rings[j]; --j;
        }
        rings[j + 1] = key;
    }
    return ring_count;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t weiler_atherton_polygon_intersection(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 27) return -1;
    int64_t na_word = input[0], nb_word = input[1];
    if (na_word < 3 || na_word > MAX_VERTICES || nb_word < 3 || nb_word > MAX_VERTICES
        || length != (size_t)(2 + 2 * na_word + 2 * nb_word)) return -1;
    int na = (int)na_word, nb = (int)nb_word;
    int64_t a[MAX_VERTICES][2] = {{0}}, b[MAX_VERTICES][2] = {{0}};
    size_t at = 2;
    for (int i = 0; i < na; ++i) for (int axis = 0; axis < 2; ++axis) {
        int64_t value = input[at++]; if (value < -16 || value > 16) return -1; a[i][axis] = value;
    }
    for (int i = 0; i < nb; ++i) for (int axis = 0; axis < 2; ++axis) {
        int64_t value = input[at++]; if (value < -16 || value > 16) return -1; b[i][axis] = value;
    }
    if (!polygon_valid(a, na) || !polygon_valid(b, nb)) return -1;

    Crossing crossings[MAX_CROSSINGS] = {0}; int crossing_count = 0;
    int events_a[MAX_VERTICES][MAX_VERTICES] = {{0}}, events_b[MAX_VERTICES][MAX_VERTICES] = {{0}};
    int count_a[MAX_VERTICES] = {0}, count_b[MAX_VERTICES] = {0};
    for (int i = 0; i < na; ++i) for (int j = 0; j < nb; ++j) {
        int relation = segment_relation(a[i][0], a[i][1], a[(i + 1) % na][0], a[(i + 1) % na][1],
                                       b[j][0], b[j][1], b[(j + 1) % nb][0], b[(j + 1) % nb][1]);
        if (relation == 2) return -1;
        if (relation == 1) {
            Crossing *c = &crossings[crossing_count];
            c->edge_a = i; c->edge_b = j;
            c->point = crossing_point(a[i][0], a[i][1], a[(i + 1) % na][0], a[(i + 1) % na][1],
                                      b[j][0], b[j][1], b[(j + 1) % nb][0], b[(j + 1) % nb][1], &c->ta, &c->tb);
            int64_t a_before = orient(b[j][0], b[j][1], b[(j + 1) % nb][0], b[(j + 1) % nb][1], a[i][0], a[i][1]);
            int64_t a_after = orient(b[j][0], b[j][1], b[(j + 1) % nb][0], b[(j + 1) % nb][1], a[(i + 1) % na][0], a[(i + 1) % na][1]);
            int64_t b_before = orient(a[i][0], a[i][1], a[(i + 1) % na][0], a[(i + 1) % na][1], b[j][0], b[j][1]);
            int64_t b_after = orient(a[i][0], a[i][1], a[(i + 1) % na][0], a[(i + 1) % na][1], b[(j + 1) % nb][0], b[(j + 1) % nb][1]);
            c->a_entry = a_before < 0 && a_after > 0; c->a_exit = a_before > 0 && a_after < 0;
            c->b_entry = b_before < 0 && b_after > 0; c->b_exit = b_before > 0 && b_after < 0;
            if ((!c->a_entry && !c->a_exit) || (!c->b_entry && !c->b_exit)
                || c->a_entry == c->b_entry) return -1;
            events_a[i][count_a[i]++] = crossing_count;
            events_b[j][count_b[j]++] = crossing_count;
            ++crossing_count;
        }
    }

    Ring rings[16] = {0}; int ring_count = 0;
    if (crossing_count == 0) {
        if (inside_integer(a[0][0], a[0][1], b, nb)) {
            rings[0].count = na; for (int i = 0; i < na; ++i) rings[0].points[i] = integer_point(a[i][0], a[i][1]); ring_count = 1;
        } else if (inside_integer(b[0][0], b[0][1], a, na)) {
            rings[0].count = nb; for (int i = 0; i < nb; ++i) rings[0].points[i] = integer_point(b[i][0], b[i][1]); ring_count = 1;
        }
    } else {
        Node nodes_a[MAX_NODES], nodes_b[MAX_NODES]; int node_count_a, node_count_b;
        int index_a[MAX_CROSSINGS] = {0}, index_b[MAX_CROSSINGS] = {0};
        build_nodes(a, na, crossings, crossing_count, 1, nodes_a, &node_count_a, index_a, events_a, count_a);
        build_nodes(b, nb, crossings, crossing_count, 0, nodes_b, &node_count_b, index_b, events_b, count_b);
        int visited[MAX_CROSSINGS] = {0};
        for (int start = 0; start < node_count_a; ++start) {
            int start_id = nodes_a[start].crossing;
            if (start_id < 0 || !crossings[start_id].a_entry || visited[start_id]) continue;
            if (ring_count >= 16) return -1;
            Ring *ring = &rings[ring_count]; ring->points[ring->count++] = nodes_a[start].point;
            visited[start_id] = 1; int active = 0, index = start, guard = 0;
            for (;;) {
                if (++guard > 2 * crossing_count + na + nb + 1) return -1;
                Node *nodes = active == 0 ? nodes_a : nodes_b;
                int node_count = active == 0 ? node_count_a : node_count_b;
                int next = (index + 1) % node_count;
                Node current = nodes[next];
                if (current.crossing >= 0) {
                    int cid = current.crossing; Crossing *c = &crossings[cid]; visited[cid] = 1;
                    if (active == 0 && cid == start_id) break;
                    int exits = active == 0 ? c->a_exit : c->b_exit;
                    if (exits) {
                        if (cid == start_id) break;
                        active = 1 - active;
                        index = active == 0 ? index_a[cid] : index_b[cid];
                        continue;
                    }
                }
                if (ring->count >= 48) return -1;
                ring->points[ring->count++] = current.point;
                index = next;
            }
            if (ring->count < 3) return -1;
            ++ring_count;
        }
        for (int i = 0; i < crossing_count; ++i) if (!visited[i]) return -1;
    }

    canonicalize(rings, ring_count);
    int64_t staged[MAX_OUTPUT_WORDS] = {0}; int word_count = 0;
    staged[word_count++] = ring_count;
    for (int r = 0; r < ring_count; ++r) {
        staged[word_count++] = rings[r].count;
        for (int i = 0; i < rings[r].count; ++i) {
            Point p = rings[r].points[i];
            if (word_count + 4 > MAX_OUTPUT_WORDS) return -1;
            staged[word_count++] = p.xn; staged[word_count++] = p.xd;
            staged[word_count++] = p.yn; staged[word_count++] = p.yd;
        }
    }
    size_t output_bytes = (size_t)word_count * 8;
    if (output_bytes > 1680) return -1;
    if (output == NULL || capacity < output_bytes) return -2;
    for (int i = 0; i < word_count; ++i) store_i64_le(output, (size_t)i * 8, staged[i]);
    return (int64_t)output_bytes;
}
