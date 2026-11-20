#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 32
#define MAX_INPUT_VALUES 66
#define MAX_COORDINATE 1000

typedef struct { int64_t x, y; } Point;
typedef struct { int64_t dy, dx; } Slope;

static int compare_slope(Slope a, Slope b) {
    const int64_t left = a.dy * b.dx;
    const int64_t right = b.dy * a.dx;
    return (left > right) - (left < right);
}

static void sort_ids_by_x(int *ids, size_t count, const Point *points) {
    for (size_t i = 1; i < count; ++i) {
        const int value = ids[i];
        size_t j = i;
        while (j > 0 && points[ids[j - 1]].x > points[value].x) {
            ids[j] = ids[j - 1];
            --j;
        }
        ids[j] = value;
    }
}

static int select_id_by_x(int *ids, size_t count, size_t rank, const Point *points) {
    if (count <= 5) {
        sort_ids_by_x(ids, count, points);
        return ids[rank];
    }
    int medians[MAX_POINTS];
    size_t median_count = 0;
    for (size_t start = 0; start < count; start += 5) {
        const size_t group = count - start < 5 ? count - start : 5;
        sort_ids_by_x(ids + start, group, points);
        medians[median_count++] = ids[start + (group - 1) / 2];
    }
    const int pivot = select_id_by_x(medians, median_count, (median_count - 1) / 2, points);
    size_t lower = 0, cursor = 0, upper = count;
    while (cursor < upper) {
        if (points[ids[cursor]].x < points[pivot].x) {
            const int tmp = ids[lower]; ids[lower] = ids[cursor]; ids[cursor] = tmp;
            ++lower; ++cursor;
        } else if (points[ids[cursor]].x > points[pivot].x) {
            --upper;
            const int tmp = ids[upper]; ids[upper] = ids[cursor]; ids[cursor] = tmp;
        } else {
            ++cursor;
        }
    }
    if (rank < lower) return select_id_by_x(ids, lower, rank, points);
    if (rank < upper) return pivot;
    return select_id_by_x(ids + upper, count - upper, rank - upper, points);
}

static void sort_slopes(Slope *values, size_t count) {
    for (size_t i = 1; i < count; ++i) {
        const Slope value = values[i];
        size_t j = i;
        while (j > 0 && compare_slope(values[j - 1], value) > 0) {
            values[j] = values[j - 1];
            --j;
        }
        values[j] = value;
    }
}

static Slope select_slope(Slope *values, size_t count, size_t rank) {
    if (count <= 5) {
        sort_slopes(values, count);
        return values[rank];
    }
    Slope medians[MAX_POINTS];
    size_t median_count = 0;
    for (size_t start = 0; start < count; start += 5) {
        const size_t group = count - start < 5 ? count - start : 5;
        sort_slopes(values + start, group);
        medians[median_count++] = values[start + (group - 1) / 2];
    }
    const Slope pivot = select_slope(medians, median_count, (median_count - 1) / 2);
    size_t lower = 0, cursor = 0, upper = count;
    while (cursor < upper) {
        const int order = compare_slope(values[cursor], pivot);
        if (order < 0) {
            const Slope tmp = values[lower]; values[lower] = values[cursor]; values[cursor] = tmp;
            ++lower; ++cursor;
        } else if (order > 0) {
            --upper;
            const Slope tmp = values[upper]; values[upper] = values[cursor]; values[cursor] = tmp;
        } else {
            ++cursor;
        }
    }
    if (rank < lower) return select_slope(values, lower, rank);
    if (rank < upper) return pivot;
    return select_slope(values + upper, count - upper, rank - upper);
}

static Slope pair_slope(int first, int second, const Point *points) {
    if (points[first].x > points[second].x) {
        const int tmp = first; first = second; second = tmp;
    }
    return (Slope){points[second].y - points[first].y,
                    points[second].x - points[first].x};
}

static void upper_bridge(const Point *points, int *candidates, size_t *candidate_count,
                         int64_t separator, int *left_out, int *right_out) {
    size_t count = *candidate_count;
    while (count > 2) {
        const size_t pair_count = count / 2;
        Slope slopes[MAX_POINTS];
        for (size_t pair = 0; pair < pair_count; ++pair) {
            int p = candidates[2 * pair], q = candidates[2 * pair + 1];
            if (points[p].x > points[q].x) { const int tmp = p; p = q; q = tmp; }
            slopes[pair] = (Slope){points[q].y - points[p].y, points[q].x - points[p].x};
        }
        const Slope median = select_slope(slopes, pair_count, (pair_count - 1) / 2);
        int64_t maximum = INT64_MIN;
        for (size_t i = 0; i < count; ++i) {
            const Point point = points[candidates[i]];
            const int64_t score = point.y * median.dx - median.dy * point.x;
            if (score > maximum) maximum = score;
        }
        int left = -1, right = -1;
        for (size_t i = 0; i < count; ++i) {
            const int id = candidates[i];
            const Point point = points[id];
            if (point.y * median.dx - median.dy * point.x == maximum) {
                if (left < 0 || point.x < points[left].x) left = id;
                if (right < 0 || point.x > points[right].x) right = id;
            }
        }
        if (points[left].x <= separator && separator < points[right].x) {
            *left_out = left; *right_out = right; *candidate_count = count;
            return;
        }

        const bool support_is_left = points[right].x <= separator;
        int next[MAX_POINTS];
        size_t next_count = 0;
        for (size_t pair = 0; pair < pair_count; ++pair) {
            const int first = candidates[2 * pair], second = candidates[2 * pair + 1];
            const int order = compare_slope(pair_slope(first, second, points), median);
            bool keep_first, keep_second;
            if (support_is_left) {
                keep_first = keep_second = order < 0;
                if (order >= 0) {
                    keep_first = points[first].x > points[second].x;
                    keep_second = points[second].x > points[first].x;
                }
            } else {
                keep_first = keep_second = order > 0;
                if (order <= 0) {
                    keep_first = points[first].x < points[second].x;
                    keep_second = points[second].x < points[first].x;
                }
            }
            if (keep_first) next[next_count++] = first;
            if (keep_second) next[next_count++] = second;
        }
        if (count % 2 != 0) next[next_count++] = candidates[count - 1];
        for (size_t i = 0; i < next_count; ++i) candidates[i] = next[i];
        count = next_count;
    }
    if (points[candidates[0]].x < points[candidates[1]].x) {
        *left_out = candidates[0]; *right_out = candidates[1];
    } else {
        *left_out = candidates[1]; *right_out = candidates[0];
    }
    *candidate_count = count;
}

static void append_unique(int *chain, size_t *length, int point) {
    if (*length == 0 || chain[*length - 1] != point) chain[(*length)++] = point;
}

static void connect_upper(const Point *points, const int *candidates, size_t count,
                          int left_endpoint, int right_endpoint,
                          int *chain, size_t *chain_length) {
    if (left_endpoint == right_endpoint) {
        append_unique(chain, chain_length, left_endpoint);
        return;
    }
    int median_ids[MAX_POINTS];
    for (size_t i = 0; i < count; ++i) median_ids[i] = candidates[i];
    const int median_point = select_id_by_x(median_ids, count, (count - 1) / 2, points);
    const int64_t separator = points[median_point].x;
    int mutable_candidates[MAX_POINTS];
    for (size_t i = 0; i < count; ++i) mutable_candidates[i] = candidates[i];
    size_t mutable_count = count;
    int bridge_left, bridge_right;
    upper_bridge(points, mutable_candidates, &mutable_count, separator,
                 &bridge_left, &bridge_right);

    int left_set[MAX_POINTS], right_set[MAX_POINTS];
    size_t left_count = 0, right_count = 0;
    for (size_t i = 0; i < count; ++i) {
        const int id = candidates[i];
        if (points[id].x <= points[bridge_left].x) left_set[left_count++] = id;
        if (points[id].x >= points[bridge_right].x) right_set[right_count++] = id;
    }
    connect_upper(points, left_set, left_count, left_endpoint, bridge_left,
                  chain, chain_length);
    append_unique(chain, chain_length, bridge_right);
    connect_upper(points, right_set, right_count, bridge_right, right_endpoint,
                  chain, chain_length);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t kirkpatrick_seidel_convex_hull(const int64_t *values, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (values == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 3 || raw_count > MAX_POINTS || length != 1 + 2 * (size_t)raw_count) return -1;
    const size_t count = (size_t)raw_count;
    Point original[MAX_POINTS], upper_points[MAX_POINTS], lower_points[MAX_POINTS];
    bool seen_x[2 * MAX_COORDINATE + 1] = {false};
    for (size_t i = 0; i < count; ++i) {
        const int64_t x = values[1 + 2 * i], y = values[2 + 2 * i];
        if (x < -MAX_COORDINATE || x > MAX_COORDINATE ||
            y < -MAX_COORDINATE || y > MAX_COORDINATE || seen_x[x + MAX_COORDINATE]) return -1;
        seen_x[x + MAX_COORDINATE] = true;
        original[i] = (Point){x, y};
        upper_points[i] = (Point){x, y};
        lower_points[i] = (Point){x, -y};
    }
    bool non_collinear = false;
    for (size_t i = 2; i < count; ++i) {
        const int64_t cross = (original[1].x - original[0].x) *
                              (original[i].y - original[0].y) -
                              (original[1].y - original[0].y) *
                              (original[i].x - original[0].x);
        if (cross != 0) { non_collinear = true; break; }
    }
    if (!non_collinear) return -1;

    int ids[MAX_POINTS];
    size_t left_index = 0, right_index = 0;
    for (size_t i = 0; i < count; ++i) {
        ids[i] = (int)i;
        if (original[i].x < original[left_index].x) left_index = i;
        if (original[i].x > original[right_index].x) right_index = i;
    }
    int upper[MAX_POINTS], lower[MAX_POINTS];
    size_t upper_count = 0, lower_count = 0;
    connect_upper(upper_points, ids, count, (int)left_index, (int)right_index,
                  upper, &upper_count);
    connect_upper(lower_points, ids, count, (int)left_index, (int)right_index,
                  lower, &lower_count);

    int hull[MAX_POINTS];
    size_t hull_count = 0;
    for (size_t i = 0; i < lower_count; ++i) append_unique(hull, &hull_count, lower[i]);
    for (size_t i = upper_count - 1; i > 1; --i)
        append_unique(hull, &hull_count, upper[i - 1]);

    const size_t byte_count = 16 * hull_count;
    if (output == NULL || capacity < byte_count) return -2;
    for (size_t i = 0; i < hull_count; ++i) {
        const Point point = original[hull[i]];
        store_i64_le(output, 16 * i, point.x);
        store_i64_le(output, 16 * i + 8, point.y);
    }
    return (int64_t)byte_count;
}
