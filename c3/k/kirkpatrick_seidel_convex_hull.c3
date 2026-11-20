module kirkpatrick_seidel_convex_hull;

const int MAX_POINTS = 32;
const usz MAX_INPUT_VALUES = 66;
const long MAX_COORDINATE = 1000;

struct Point { long x; long y; }
struct Slope { long dy; long dx; }

fn int compare_slope(Slope a, Slope b) {
    long left = a.dy * b.dx, right = b.dy * a.dx;
    return left > right ? 1 : left < right ? -1 : 0;
}

fn void sort_ids_by_x(int* ids, usz count, Point* points) {
    for (usz i = 1; i < count; i++) {
        int value = ids[i];
        usz j = i;
        while (j > 0 && points[ids[j - 1]].x > points[value].x) {
            ids[j] = ids[j - 1];
            j--;
        }
        ids[j] = value;
    }
}

fn int select_id_by_x(int* ids, usz count, usz rank, Point* points) {
    if (count <= 5) {
        sort_ids_by_x(ids, count, points);
        return ids[rank];
    }
    int[MAX_POINTS] medians = zeroed;
    usz median_count = 0;
    for (usz start = 0; start < count; start += 5) {
        usz group = count - start < 5 ? count - start : 5;
        sort_ids_by_x(&ids[start], group, points);
        medians[median_count++] = ids[start + (group - 1) / 2];
    }
    int pivot = select_id_by_x(&medians[0], median_count, (median_count - 1) / 2, points);
    usz lower = 0, cursor = 0, upper = count;
    while (cursor < upper) {
        if (points[ids[cursor]].x < points[pivot].x) {
            int temp = ids[lower]; ids[lower] = ids[cursor]; ids[cursor] = temp;
            lower++; cursor++;
        } else if (points[ids[cursor]].x > points[pivot].x) {
            upper--;
            int temp = ids[upper]; ids[upper] = ids[cursor]; ids[cursor] = temp;
        } else cursor++;
    }
    if (rank < lower) return select_id_by_x(ids, lower, rank, points);
    if (rank < upper) return pivot;
    return select_id_by_x(&ids[upper], count - upper, rank - upper, points);
}

fn void sort_slopes(Slope* values, usz count) {
    for (usz i = 1; i < count; i++) {
        Slope value = values[i];
        usz j = i;
        while (j > 0 && compare_slope(values[j - 1], value) > 0) {
            values[j] = values[j - 1];
            j--;
        }
        values[j] = value;
    }
}

fn Slope select_slope(Slope* values, usz count, usz rank) {
    if (count <= 5) {
        sort_slopes(values, count);
        return values[rank];
    }
    Slope[MAX_POINTS] medians = zeroed;
    usz median_count = 0;
    for (usz start = 0; start < count; start += 5) {
        usz group = count - start < 5 ? count - start : 5;
        sort_slopes(&values[start], group);
        medians[median_count++] = values[start + (group - 1) / 2];
    }
    Slope pivot = select_slope(&medians[0], median_count, (median_count - 1) / 2);
    usz lower = 0, cursor = 0, upper = count;
    while (cursor < upper) {
        int order = compare_slope(values[cursor], pivot);
        if (order < 0) {
            Slope temp = values[lower]; values[lower] = values[cursor]; values[cursor] = temp;
            lower++; cursor++;
        } else if (order > 0) {
            upper--;
            Slope temp = values[upper]; values[upper] = values[cursor]; values[cursor] = temp;
        } else cursor++;
    }
    if (rank < lower) return select_slope(values, lower, rank);
    if (rank < upper) return pivot;
    return select_slope(&values[upper], count - upper, rank - upper);
}

fn Slope pair_slope(int first, int second, Point* points) {
    if (points[first].x > points[second].x) {
        int temp = first; first = second; second = temp;
    }
    return {points[second].y - points[first].y, points[second].x - points[first].x};
}

fn void upper_bridge(Point* points, int* candidates, usz* candidate_count,
        long separator, int* left_out, int* right_out) {
    usz count = *candidate_count;
    while (count > 2) {
        usz pair_count = count / 2;
        Slope[MAX_POINTS] slopes = zeroed;
        for (usz pair = 0; pair < pair_count; pair++)
            slopes[pair] = pair_slope(candidates[2 * pair], candidates[2 * pair + 1], points);
        Slope median = select_slope(&slopes[0], pair_count, (pair_count - 1) / 2);
        long maximum = -5000000;
        for (usz i = 0; i < count; i++) {
            Point p = points[candidates[i]];
            long score = p.y * median.dx - median.dy * p.x;
            if (score > maximum) maximum = score;
        }
        int left = -1, right = -1;
        for (usz i = 0; i < count; i++) {
            int id = candidates[i];
            Point p = points[id];
            if (p.y * median.dx - median.dy * p.x == maximum) {
                if (left < 0 || p.x < points[left].x) left = id;
                if (right < 0 || p.x > points[right].x) right = id;
            }
        }
        if (points[left].x <= separator && separator < points[right].x) {
            *left_out = left; *right_out = right; *candidate_count = count;
            return;
        }
        bool support_is_left = points[right].x <= separator;
        int[MAX_POINTS] next = zeroed;
        usz next_count = 0;
        for (usz pair = 0; pair < pair_count; pair++) {
            int first = candidates[2 * pair], second = candidates[2 * pair + 1];
            int order = compare_slope(pair_slope(first, second, points), median);
            bool keep_first, keep_second;
            if (support_is_left) {
                keep_first = order < 0; keep_second = order < 0;
                if (order >= 0) {
                    keep_first = points[first].x > points[second].x;
                    keep_second = points[second].x > points[first].x;
                }
            } else {
                keep_first = order > 0; keep_second = order > 0;
                if (order <= 0) {
                    keep_first = points[first].x < points[second].x;
                    keep_second = points[second].x < points[first].x;
                }
            }
            if (keep_first) next[next_count++] = first;
            if (keep_second) next[next_count++] = second;
        }
        if (count % 2 != 0) next[next_count++] = candidates[count - 1];
        for (usz i = 0; i < next_count; i++) candidates[i] = next[i];
        count = next_count;
    }
    if (points[candidates[0]].x < points[candidates[1]].x) {
        *left_out = candidates[0]; *right_out = candidates[1];
    } else {
        *left_out = candidates[1]; *right_out = candidates[0];
    }
    *candidate_count = count;
}

fn void append_unique(int* chain, usz* count, int point) {
    if (*count == 0 || chain[*count - 1] != point) chain[(*count)++] = point;
}

fn void connect_upper(Point* points, int* candidates, usz count,
        int left_endpoint, int right_endpoint, int* chain, usz* chain_count) {
    if (left_endpoint == right_endpoint) {
        append_unique(chain, chain_count, left_endpoint);
        return;
    }
    int[MAX_POINTS] median_ids = zeroed;
    int[MAX_POINTS] mutable_candidates = zeroed;
    for (usz i = 0; i < count; i++) {
        median_ids[i] = candidates[i];
        mutable_candidates[i] = candidates[i];
    }
    int median_point = select_id_by_x(&median_ids[0], count, (count - 1) / 2, points);
    long separator = points[median_point].x;
    usz mutable_count = count;
    int bridge_left, bridge_right;
    upper_bridge(points, &mutable_candidates[0], &mutable_count, separator,
                 &bridge_left, &bridge_right);
    int[MAX_POINTS] left_set = zeroed, right_set = zeroed;
    usz left_count = 0, right_count = 0;
    for (usz i = 0; i < count; i++) {
        int id = candidates[i];
        if (points[id].x <= points[bridge_left].x) left_set[left_count++] = id;
        if (points[id].x >= points[bridge_right].x) right_set[right_count++] = id;
    }
    connect_upper(points, &left_set[0], left_count, left_endpoint, bridge_left,
                  chain, chain_count);
    append_unique(chain, chain_count, bridge_right);
    connect_upper(points, &right_set[0], right_count, bridge_right, right_endpoint,
                  chain, chain_count);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long kirkpatrick_seidel_convex_hull(long* values, usz length,
        char* output, usz capacity) @export("kirkpatrick_seidel_convex_hull") {
    if (values == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long raw_count = values[0];
    if (raw_count < 3 || raw_count > (long)MAX_POINTS) return -1;
    usz count = (usz)raw_count;
    if (length != 1 + 2 * count) return -1;
    Point[MAX_POINTS] original = zeroed;
    Point[MAX_POINTS] upper_points = zeroed;
    Point[MAX_POINTS] lower_points = zeroed;
    bool[2001] seen_x = zeroed;
    for (usz i = 0; i < count; i++) {
        long x = values[1 + 2 * i], y = values[2 + 2 * i];
        if (x < -MAX_COORDINATE || x > MAX_COORDINATE || y < -MAX_COORDINATE || y > MAX_COORDINATE) return -1;
        usz slot = (usz)(x + MAX_COORDINATE);
        if (seen_x[slot]) return -1;
        seen_x[slot] = true;
        original[i] = {x, y}; upper_points[i] = {x, y}; lower_points[i] = {x, -y};
    }
    bool non_collinear = false;
    for (usz i = 2; i < count; i++) {
        long cross = (original[1].x - original[0].x) * (original[i].y - original[0].y)
                   - (original[1].y - original[0].y) * (original[i].x - original[0].x);
        if (cross != 0) { non_collinear = true; break; }
    }
    if (!non_collinear) return -1;
    int[MAX_POINTS] ids = zeroed;
    int[MAX_POINTS] upper = zeroed;
    int[MAX_POINTS] lower = zeroed;
    int[MAX_POINTS] hull = zeroed;
    usz left_index = 0, right_index = 0;
    for (usz i = 0; i < count; i++) {
        ids[i] = (int)i;
        if (original[i].x < original[left_index].x) left_index = i;
        if (original[i].x > original[right_index].x) right_index = i;
    }
    usz upper_count = 0, lower_count = 0;
    connect_upper(&upper_points[0], &ids[0], count, (int)left_index, (int)right_index,
                  &upper[0], &upper_count);
    connect_upper(&lower_points[0], &ids[0], count, (int)left_index, (int)right_index,
                  &lower[0], &lower_count);
    usz hull_count = 0;
    for (usz i = 0; i < lower_count; i++) append_unique(&hull[0], &hull_count, lower[i]);
    for (usz i = upper_count - 1; i > 1; i--) append_unique(&hull[0], &hull_count, upper[i - 1]);
    usz byte_count = 16 * hull_count;
    if (output == null || capacity < byte_count) return -2;
    for (usz i = 0; i < hull_count; i++) {
        Point p = original[hull[i]];
        store_i64_le(output, 16 * i, p.x);
        store_i64_le(output, 16 * i + 8, p.y);
    }
    return (long)byte_count;
}
