#include <stddef.h>
#include <stdint.h>

enum { MIN_N = 3, MAX_N = 5, MAX_LENGTH = 12, DP_SIZE = 10, MAX_TRIANGLES = 3 };

typedef struct { int64_t x, y; } Point;
typedef struct { int64_t num, den; } Score;
typedef struct { Score minimum; int count; int valid; int split; } Cell;
typedef struct { int a, b, c; } Triangle;
typedef struct { Triangle item[MAX_TRIANGLES]; int count; } Triangles;
typedef struct { Score minimum; int count; } Objective;

static int64_t absolute64(int64_t value) { return value < 0 ? -value : value; }

static int64_t gcd64(int64_t a, int64_t b) {
    while (b != 0) { const int64_t remainder = a % b; a = b; b = remainder; }
    return a;
}

static int64_t orient(Point a, Point b, Point c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

static int compare_score(Score a, Score b) {
    const int64_t left = a.num * b.den;
    const int64_t right = b.num * a.den;
    return left < right ? -1 : left > right ? 1 : 0;
}

static Score reduced_score(int64_t numerator, int64_t denominator) {
    const int64_t divisor = gcd64(numerator, denominator);
    return (Score){numerator / divisor, denominator / divisor};
}

static Score triangle_score(const Point points[MAX_N], int n, int a, int b, int c) {
    const Point pa = points[a % n], pb = points[b % n], pc = points[c % n];
    const int64_t area2 = absolute64(orient(pa, pb, pc));
    const int64_t lengths[3] = {
        (pa.x - pb.x) * (pa.x - pb.x) + (pa.y - pb.y) * (pa.y - pb.y),
        (pb.x - pc.x) * (pb.x - pc.x) + (pb.y - pc.y) * (pb.y - pc.y),
        (pc.x - pa.x) * (pc.x - pa.x) + (pc.y - pa.y) * (pc.y - pa.y)
    };
    Score best = reduced_score(area2 * area2, lengths[0]);
    for (int i = 1; i < 3; ++i) {
        const Score candidate = reduced_score(area2 * area2, lengths[i]);
        if (compare_score(candidate, best) < 0) best = candidate;
    }
    return best;
}

static Objective join_objective(Cell left, Cell right, Score triangle) {
    Objective result = {triangle, 1};
    const Cell children[2] = {left, right};
    for (int i = 0; i < 2; ++i) {
        if (!children[i].valid) continue;
        const int comparison = compare_score(children[i].minimum, result.minimum);
        if (comparison < 0) {
            result.minimum = children[i].minimum;
            result.count = children[i].count;
        } else if (comparison == 0) {
            result.count += children[i].count;
        }
    }
    return result;
}

static int better(Objective candidate, Objective current) {
    const int comparison = compare_score(candidate.minimum, current.minimum);
    return comparison > 0 || (comparison == 0 && candidate.count < current.count);
}

static Objective triangles_objective(const Point points[MAX_N], int n, const Triangles *triangles) {
    Objective result = {triangle_score(points, n, triangles->item[0].a,
                                       triangles->item[0].b, triangles->item[0].c), 1};
    for (int i = 1; i < triangles->count; ++i) {
        const Triangle triangle = triangles->item[i];
        const Score score = triangle_score(points, n, triangle.a, triangle.b, triangle.c);
        const int comparison = compare_score(score, result.minimum);
        if (comparison < 0) { result.minimum = score; result.count = 1; }
        else if (comparison == 0) ++result.count;
    }
    return result;
}

static void collect(int start, int end, const Cell table[DP_SIZE][DP_SIZE], int n,
                    Triangles *out) {
    if (end - start < 2) return;
    const int middle = table[start][end].split;
    out->item[out->count++] = (Triangle){start % n, middle % n, end % n};
    collect(start, middle, table, n, out);
    collect(middle, end, table, n, out);
}

static int edge_present(const Triangles *triangles, int left, int right) {
    for (int i = 0; i < triangles->count; ++i) {
        const Triangle t = triangles->item[i];
        const int pairs[3][2] = {{t.a, t.b}, {t.b, t.c}, {t.c, t.a}};
        for (int j = 0; j < 3; ++j) {
            int a = pairs[j][0], b = pairs[j][1];
            if (a > b) { const int temporary = a; a = b; b = temporary; }
            if (a == left && b == right) return 1;
        }
    }
    return 0;
}

static int64_t edge_insertion(const Point points[MAX_N], int n) {
    Cell table[DP_SIZE][DP_SIZE] = {{{0}}};
    for (int span = 2; span <= n - 2; ++span) {
        for (int start = 0; start < n; ++start) {
            const int end = start + span;
            Objective best = {{0, 1}, 0};
            int best_middle = -1;
            for (int middle = start + 1; middle < end; ++middle) {
                const Objective candidate = join_objective(
                    table[start][middle], table[middle][end],
                    triangle_score(points, n, start, middle, end));
                if (best_middle < 0 || better(candidate, best)) {
                    best = candidate;
                    best_middle = middle;
                }
            }
            table[start][end] = (Cell){best.minimum, best.count, 1, best_middle};
        }
    }

    Triangles current = {0};
    for (int middle = 1; middle < n - 1; ++middle)
        current.item[current.count++] = (Triangle){0, middle, middle + 1};
    Objective current_objective = triangles_objective(points, n, &current);
    int improvements = 0;
    for (;;) {
        int changed = 0;
        for (int left = 0; left < n && !changed; ++left) {
            for (int right = left + 2; right < n; ++right) {
                if (left == 0 && right == n - 1) continue;
                if (edge_present(&current, left, right)) continue;
                Triangles candidate_triangles = {0};
                collect(left, right, table, n, &candidate_triangles);
                collect(right, left + n, table, n, &candidate_triangles);
                const Objective candidate = triangles_objective(points, n, &candidate_triangles);
                if (better(candidate, current_objective)) {
                    current = candidate_triangles;
                    current_objective = candidate;
                    if (++improvements > 30) return -1;
                    changed = 1;
                    break;
                }
            }
        }
        if (!changed) return current_objective.minimum.num * 513 + current_objective.minimum.den;
    }
}

int64_t max_min_triangle_height_triangulation(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_LENGTH) return -1;
    if (input[0] < MIN_N || input[0] > MAX_N) return -1;
    const int n = (int)input[0];
    if (length != (size_t)(1 + 2 * n)) return -1;
    Point points[MAX_N] = {{0, 0}};
    for (int i = 0; i < n; ++i) {
        points[i] = (Point){input[1 + 2 * i], input[2 + 2 * i]};
        if (points[i].x < -8 || points[i].x > 8 || points[i].y < -8 || points[i].y > 8) return -1;
        for (int j = 0; j < i; ++j)
            if (points[i].x == points[j].x && points[i].y == points[j].y) return -1;
    }
    int64_t area2 = 0;
    for (int i = 0; i < n; ++i) {
        const int next = (i + 1) % n;
        area2 += points[i].x * points[next].y - points[i].y * points[next].x;
    }
    if (area2 <= 0) return -1;
    for (int a = 0; a < n; ++a) for (int b = a + 1; b < n; ++b) for (int c = b + 1; c < n; ++c)
        if (orient(points[a], points[b], points[c]) == 0) return -1;
    for (int edge = 0; edge < n; ++edge) {
        const int next = (edge + 1) % n;
        for (int vertex = 0; vertex < n; ++vertex)
            if (vertex != edge && vertex != next && orient(points[edge], points[next], points[vertex]) <= 0) return -1;
    }
    return edge_insertion(points, n);
}
