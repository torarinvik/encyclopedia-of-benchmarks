module convex_hull_graham_scan;

const usz MAX_POINTS = 1024;

struct Point { long x; long y; usz id; }

long cross(Point* a, Point* b, Point* c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

long radius_squared(Point* pivot, Point* point) {
    long dx = point.x - pivot.x;
    long dy = point.y - pivot.y;
    return dx * dx + dy * dy;
}

bool before_xy(usz left, usz right, Point* points) {
    if (points[left].x != points[right].x) return points[left].x < points[right].x;
    if (points[left].y != points[right].y) return points[left].y < points[right].y;
    return points[left].id < points[right].id;
}

bool before_angle(usz left, usz right, Point* points, usz pivot_index) {
    Point* pivot = &points[pivot_index];
    long turn = cross(pivot, &points[left], &points[right]);
    if (turn != 0) return turn > 0;
    long left_radius = radius_squared(pivot, &points[left]);
    long right_radius = radius_squared(pivot, &points[right]);
    if (left_radius != right_radius) return left_radius < right_radius;
    return points[left].id < points[right].id;
}

void merge_sort(usz* items, usz* scratch, usz begin, usz end, Point* points,
                usz pivot_index, bool by_angle) {
    if (end - begin < 2) return;
    usz middle = begin + (end - begin) / 2;
    merge_sort(items, scratch, begin, middle, points, pivot_index, by_angle);
    merge_sort(items, scratch, middle, end, points, pivot_index, by_angle);
    usz left = begin, right = middle, out = begin;
    while (left < middle && right < end) {
        bool right_before = by_angle
            ? before_angle(items[right], items[left], points, pivot_index)
            : before_xy(items[right], items[left], points);
        scratch[out++] = right_before ? items[right++] : items[left++];
    }
    while (left < middle) scratch[out++] = items[left++];
    while (right < end) scratch[out++] = items[right++];
    for (usz i = begin; i < end; i++) items[i] = scratch[i];
}

void write_index(char* output, usz position, usz id) {
    u32 value = (u32)id;
    for (usz byte = 0; byte < 4; byte++) output[4 * position + byte] = (char)(value >> (8 * byte));
}

fn long convex_hull_graham_scan(long* values, usz length, char* output, usz output_capacity)
    @export("convex_hull_graham_scan") {
    if (length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values == null)) return -1;
    usz point_count = length / 2;
    Point input_points[MAX_POINTS];
    Point points[MAX_POINTS];
    usz order[MAX_POINTS], scratch[MAX_POINTS], hull[MAX_POINTS];
    for (usz i = 0; i < point_count; i++) {
        long x = values[2 * i], y = values[2 * i + 1];
        if (x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000) return -1;
        input_points[i] = {x, y, i};
        order[i] = i;
    }
    if (point_count == 0) return 0;
    merge_sort(&order[0], &scratch[0], 0, point_count, &input_points[0], 0, false);
    usz unique_count = 0;
    for (usz i = 0; i < point_count; i++) {
        Point point = input_points[order[i]];
        if (unique_count == 0 || points[unique_count - 1].x != point.x || points[unique_count - 1].y != point.y)
            points[unique_count++] = point;
    }
    if (unique_count == 1) {
        if (output == null || output_capacity < 4) return -2;
        write_index(output, 0, points[0].id);
        return 1;
    }
    usz pivot_index = 0;
    for (usz i = 1; i < unique_count; i++) {
        if (points[i].y < points[pivot_index].y ||
            (points[i].y == points[pivot_index].y && points[i].x < points[pivot_index].x)) pivot_index = i;
    }
    for (usz i = 0; i < unique_count; i++) order[i] = i;
    merge_sort(&order[0], &scratch[0], 0, unique_count, &points[0], pivot_index, true);
    bool all_collinear = true;
    for (usz i = 2; i < unique_count; i++)
        if (cross(&points[pivot_index], &points[order[1]], &points[order[i]]) != 0) all_collinear = false;
    if (!all_collinear) {
        usz ray_begin = unique_count - 1;
        while (ray_begin > 1 && cross(&points[pivot_index], &points[order[ray_begin - 1]],
                                      &points[order[unique_count - 1]]) == 0) ray_begin--;
        usz left = ray_begin, right = unique_count - 1;
        while (left < right) {
            usz temporary = order[left]; order[left++] = order[right]; order[right--] = temporary;
        }
    }
    usz hull_count = 0;
    for (usz i = 0; i < unique_count; i++) {
        usz point = order[i];
        while (hull_count >= 2 && cross(&points[hull[hull_count - 2]], &points[hull[hull_count - 1]], &points[point]) < 0)
            hull_count--;
        hull[hull_count++] = point;
    }
    if (output == null || output_capacity < 4 * hull_count) return -2;
    for (usz i = 0; i < hull_count; i++) write_index(output, i, points[hull[i]].id);
    return (long)hull_count;
}
