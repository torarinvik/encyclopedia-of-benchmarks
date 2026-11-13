module convex_polygon_minimax_length_triangulation;

const int MIN_VERTICES = 3;
const int MAX_VERTICES = 12;
const usz MAX_PARSEABLE_LENGTH = 26;
const long COORD_LIMIT = 1000;

struct Point { long x; long y; }

fn long cross(Point a, Point b, Point c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

fn long squared_length(Point[MAX_VERTICES] points, usz left, usz right) {
    long dx = points[left].x - points[right].x;
    long dy = points[left].y - points[right].y;
    return dx * dx + dy * dy;
}

fn long convex_polygon_minimax_length_triangulation(long* input, usz length)
    @export("convex_polygon_minimax_length_triangulation") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (input[0] < MIN_VERTICES || input[0] > MAX_VERTICES) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 2 * n) return -1;
    Point[MAX_VERTICES] points = zeroed;
    for (usz i = 0; i < n; i++) {
        points[i] = Point{input[1 + 2 * i], input[2 + 2 * i]};
        if (points[i].x < -COORD_LIMIT || points[i].x > COORD_LIMIT ||
            points[i].y < -COORD_LIMIT || points[i].y > COORD_LIMIT) return -1;
    }
    long area2 = 0;
    for (usz i = 0; i < n; i++) {
        usz next = (i + 1) % n;
        area2 += points[i].x * points[next].y - points[i].y * points[next].x;
    }
    if (area2 == 0) return -1;
    long orientation = area2 > 0 ? 1 : -1;
    for (usz edge = 0; edge < n; edge++) {
        usz next = (edge + 1) % n;
        for (usz vertex = 0; vertex < n; vertex++) {
            if (vertex == edge || vertex == next) continue;
            if (orientation * cross(points[edge], points[next], points[vertex]) <= 0) return -1;
        }
    }

    long[MAX_VERTICES][MAX_VERTICES] best = zeroed;
    for (usz left = 0; left + 1 < n; left++)
        best[left][left + 1] = squared_length(points, left, left + 1);
    for (usz span = 2; span < n; span++) {
        for (usz left = 0; left + span < n; left++) {
            usz right = left + span;
            long boundary = squared_length(points, left, right);
            long optimum = 8000001;
            for (usz middle = left + 1; middle < right; middle++) {
                long candidate = best[left][middle];
                if (best[middle][right] > candidate) candidate = best[middle][right];
                if (boundary > candidate) candidate = boundary;
                if (candidate < optimum) optimum = candidate;
            }
            best[left][right] = optimum;
        }
    }
    return best[0][n - 1];
}
