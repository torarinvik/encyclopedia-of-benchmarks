module rotating_calipers;

extern fn double sqrt(double value);
const usz MAX_POINTS = 1024;
const long MAX_COORDINATE = 1000000000;
const double INVALID_RESULT = -1.0e300;
struct Point { long x; long y; }

fn bool before(Point* a, Point* b) {
    return a.x < b.x || (a.x == b.x && a.y < b.y);
}
fn long cross(Point* origin, Point* a, Point* b) {
    return (a.x - origin.x) * (b.y - origin.y) - (a.y - origin.y) * (b.x - origin.x);
}
fn long distance_squared(Point* a, Point* b) {
    long dx = a.x - b.x, dy = a.y - b.y;
    return dx * dx + dy * dy;
}
fn void sort_points(Point* points, Point* scratch, usz begin, usz end) {
    if (end - begin < 2) return;
    usz middle = begin + (end - begin) / 2;
    sort_points(points, scratch, begin, middle);
    sort_points(points, scratch, middle, end);
    usz left = begin, right = middle, out = begin;
    while (left < middle && right < end)
        scratch[out++] = before(&points[right], &points[left]) ? points[right++] : points[left++];
    while (left < middle) scratch[out++] = points[left++];
    while (right < end) scratch[out++] = points[right++];
    for (usz i = begin; i < end; i++) points[i] = scratch[i];
}

fn double rotating_calipers(long* values, usz length) @export("rotating_calipers") {
    if (values == null || length < 5 || length > 2 * MAX_POINTS + 1 || length % 2 == 0)
        return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 2 || count_value > (long)MAX_POINTS || length != 1 + 2 * (usz)count_value)
        return INVALID_RESULT;
    usz count = (usz)count_value;
    Point[MAX_POINTS] points, scratch, lower, upper;
    for (usz i = 0; i < count; i++) {
        long x = values[1 + 2 * i], y = values[2 + 2 * i];
        if (x < -MAX_COORDINATE || x > MAX_COORDINATE || y < -MAX_COORDINATE || y > MAX_COORDINATE)
            return INVALID_RESULT;
        points[i] = {x, y};
    }
    sort_points(&points[0], &scratch[0], 0, count);
    usz unique_count = 0;
    for (usz i = 0; i < count; i++) {
        if (unique_count == 0 || points[i].x != points[unique_count - 1].x || points[i].y != points[unique_count - 1].y)
            points[unique_count++] = points[i];
    }
    if (unique_count == 1) return 0.0;

    usz lower_count = 0;
    for (usz i = 0; i < unique_count; i++) {
        while (lower_count >= 2 && cross(&lower[lower_count - 2], &lower[lower_count - 1], &points[i]) <= 0)
            lower_count--;
        lower[lower_count++] = points[i];
    }
    usz upper_count = 0;
    for (usz i = unique_count; i-- > 0;) {
        while (upper_count >= 2 && cross(&upper[upper_count - 2], &upper[upper_count - 1], &points[i]) <= 0)
            upper_count--;
        upper[upper_count++] = points[i];
    }
    Point[2 * MAX_POINTS] hull;
    usz hull_count = 0;
    for (usz i = 0; i + 1 < lower_count; i++) hull[hull_count++] = lower[i];
    for (usz i = 0; i + 1 < upper_count; i++) hull[hull_count++] = upper[i];
    if (hull_count == 2) return sqrt((double)distance_squared(&hull[0], &hull[1]));

    usz antipodal = 1, advances = 0;
    while (advances < hull_count &&
        cross(&hull[0], &hull[1], &hull[(antipodal + 1) % hull_count]) >
        cross(&hull[0], &hull[1], &hull[antipodal])) {
        antipodal = (antipodal + 1) % hull_count;
        advances++;
    }
    long maximum_squared = 0;
    for (usz current = 0; current < hull_count; current++) {
        usz next = (current + 1) % hull_count;
        advances = 0;
        while (advances < hull_count &&
            cross(&hull[current], &hull[next], &hull[(antipodal + 1) % hull_count]) >
            cross(&hull[current], &hull[next], &hull[antipodal])) {
            antipodal = (antipodal + 1) % hull_count;
            advances++;
        }
        usz after = (antipodal + 1) % hull_count;
        long[4] candidates = {
            distance_squared(&hull[current], &hull[antipodal]),
            distance_squared(&hull[next], &hull[antipodal]),
            distance_squared(&hull[current], &hull[after]),
            distance_squared(&hull[next], &hull[after])
        };
        for (usz i = 0; i < 4; i++) if (candidates[i] > maximum_squared) maximum_squared = candidates[i];
    }
    return sqrt((double)maximum_squared);
}
