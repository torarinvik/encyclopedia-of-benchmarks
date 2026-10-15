module convex_hull_quickhull;

const usz MAX_POINTS = 1024;
struct Point { long x; long y; usz id; }

bool before(Point* a, Point* b) {
    if (a.x != b.x) return a.x < b.x;
    if (a.y != b.y) return a.y < b.y;
    return a.id < b.id;
}
long cross(Point* a, Point* b, Point* c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
void sort_points(Point* points, Point* scratch, usz begin, usz end) {
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
void quick_hull(Point* points, usz count, usz left, usz right, bool* on_hull) {
    usz farthest = MAX_POINTS;
    long greatest_area = 0;
    for (usz i = 0; i < count; i++) {
        long area = cross(&points[left], &points[right], &points[i]);
        if (area > greatest_area) { greatest_area = area; farthest = i; }
    }
    if (farthest == MAX_POINTS) return;
    on_hull[farthest] = true;
    quick_hull(points, count, left, farthest, on_hull);
    quick_hull(points, count, farthest, right, on_hull);
}

fn long convex_hull_quickhull(long* values, usz length, char* output, usz output_capacity)
    @export("convex_hull_quickhull") {
    if (length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values == null)) return -1;
    usz input_count = length / 2;
    Point points[MAX_POINTS], scratch[MAX_POINTS];
    for (usz i = 0; i < input_count; i++) {
        long x = values[2 * i], y = values[2 * i + 1];
        if (x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000) return -1;
        points[i] = {x, y, i};
    }
    if (input_count == 0) return 0;
    sort_points(&points[0], &scratch[0], 0, input_count);
    usz count = 0;
    for (usz i = 0; i < input_count; i++) {
        if (count == 0 || points[count - 1].x != points[i].x || points[count - 1].y != points[i].y)
            points[count++] = points[i];
    }
    bool on_hull[MAX_POINTS];
    for (usz i = 0; i < MAX_POINTS; i++) on_hull[i] = false;
    if (count == 1) on_hull[0] = true;
    else {
        on_hull[0] = true;
        on_hull[count - 1] = true;
        quick_hull(&points[0], count, 0, count - 1, &on_hull[0]);
        quick_hull(&points[0], count, count - 1, 0, &on_hull[0]);
    }
    usz hull_count = 0;
    for (usz i = 0; i < count; i++) if (on_hull[i]) hull_count++;
    if (output == null || output_capacity < 4 * hull_count) return -2;
    usz position = 0;
    for (usz i = 0; i < count; i++) {
        if (!on_hull[i]) continue;
        u32 id = (u32)points[i].id;
        for (usz byte = 0; byte < 4; byte++) output[4 * position + byte] = (char)(id >> (8 * byte));
        position++;
    }
    return (long)hull_count;
}
