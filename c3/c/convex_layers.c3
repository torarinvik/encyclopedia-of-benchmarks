module convex_layers;

const int MAX_POINTS = 64;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_POINTS;
const long COORD_LIMIT = 1000000;

struct Point { long x; long y; }

fn long cross(Point a, Point b, Point c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

fn bool before(Point left, Point right) {
    return left.x < right.x || (left.x == right.x && left.y < right.y);
}

fn void sort_points(Point* points, int count) {
    for (int i = 1; i < count; i += 1) {
        Point key = points[i];
        int j = i;
        while (j > 0 && before(key, points[j - 1])) {
            points[j] = points[j - 1];
            j -= 1;
        }
        points[j] = key;
    }
}

fn bool on_segment(Point point, Point a, Point b) {
    return cross(a, b, point) == 0 && point.x >= (a.x < b.x ? a.x : b.x) &&
        point.x <= (a.x > b.x ? a.x : b.x) && point.y >= (a.y < b.y ? a.y : b.y) &&
        point.y <= (a.y > b.y ? a.y : b.y);
}

fn int mark_boundary(Point* points, int count, bool* boundary) {
    for (int i = 0; i < count; i += 1) boundary[i] = false;
    if (count <= 2) {
        for (int i = 0; i < count; i += 1) boundary[i] = true;
        return count;
    }
    Point[2 * MAX_POINTS] hull = zeroed;
    int hull_count = 0;
    for (int i = 0; i < count; i += 1) {
        while (hull_count >= 2 && cross(hull[hull_count - 2], hull[hull_count - 1], points[i]) <= 0)
            hull_count -= 1;
        hull[hull_count] = points[i];
        hull_count += 1;
    }
    int lower_count = hull_count;
    for (int i = count - 1; i > 0; i -= 1) {
        Point point = points[i - 1];
        while (hull_count > lower_count &&
            cross(hull[hull_count - 2], hull[hull_count - 1], point) <= 0) hull_count -= 1;
        hull[hull_count] = point;
        hull_count += 1;
    }
    if (hull_count > 1) hull_count -= 1;
    if (hull_count <= 2) {
        for (int i = 0; i < count; i += 1) boundary[i] = true;
        return count;
    }
    int marked = 0;
    for (int i = 0; i < count; i += 1) {
        for (int edge = 0; edge < hull_count; edge += 1) {
            if (on_segment(points[i], hull[edge], hull[(edge + 1) % hull_count])) {
                boundary[i] = true;
                marked += 1;
                break;
            }
        }
    }
    return marked;
}

fn long convex_layers(long* input, usz length) @export("convex_layers") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > MAX_POINTS || length != (usz)(1 + 2 * count_value)) return -1;
    int count = 0;
    Point[MAX_POINTS] points = zeroed;
    for (int i = 0; i < (int)count_value; i += 1) {
        long x = input[1 + 2 * i], y = input[2 + 2 * i];
        if (x < -COORD_LIMIT || x > COORD_LIMIT || y < -COORD_LIMIT || y > COORD_LIMIT) return -1;
        bool duplicate = false;
        for (int j = 0; j < count; j += 1)
            if (points[j].x == x && points[j].y == y) duplicate = true;
        if (!duplicate) {
            points[count].x = x;
            points[count].y = y;
            count += 1;
        }
    }
    long layers = 0;
    while (count > 0) {
        sort_points(&points[0], count);
        bool[MAX_POINTS] boundary = zeroed;
        int removed = mark_boundary(&points[0], count, &boundary[0]);
        if (removed == 0) return -1;
        int kept = 0;
        for (int i = 0; i < count; i += 1) {
            if (!boundary[i]) {
                points[kept] = points[i];
                kept += 1;
            }
        }
        count = kept;
        layers += 1;
    }
    return layers;
}
