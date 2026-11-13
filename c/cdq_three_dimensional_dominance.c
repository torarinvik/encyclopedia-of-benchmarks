#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_LENGTH = 194 };

typedef struct {
    int64_t x, y, z, multiplicity, z_rank, original_index;
} Point;

typedef struct {
    Point points[MAX_N];
    int64_t original_group[MAX_N];
    int64_t dominated[MAX_N];
    int64_t bit[MAX_N + 1];
    int64_t source_order[MAX_N];
    int64_t target_order[MAX_N];
    int64_t z_values[MAX_N];
} Workspace;

static int point_less(Point a, Point b) {
    if (a.x != b.x) return a.x < b.x;
    if (a.y != b.y) return a.y < b.y;
    return a.z < b.z;
}

static void sort_points(Point *points, size_t n) {
    for (size_t i = 1; i < n; ++i) {
        Point value = points[i];
        size_t j = i;
        while (j > 0 && point_less(value, points[j - 1])) {
            points[j] = points[j - 1];
            --j;
        }
        points[j] = value;
    }
}

static int same_coordinates(Point a, Point b) {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

static void bit_add(Workspace *work, size_t index, int64_t delta, size_t limit) {
    while (index <= limit) {
        work->bit[index] += delta;
        index += index & (0 - index);
    }
}

static int64_t bit_sum(const Workspace *work, size_t index) {
    int64_t sum = 0;
    while (index > 0) {
        sum += work->bit[index];
        index -= index & (0 - index);
    }
    return sum;
}

static void cdq(Workspace *work, size_t left, size_t right, size_t group_count) {
    if (left >= right) return;
    const size_t middle = left + (right - left) / 2;
    cdq(work, left, middle, group_count);
    cdq(work, middle + 1, right, group_count);

    size_t source_cursor = left;
    for (size_t target_position = middle + 1; target_position <= right; ++target_position) {
        const size_t target = (size_t)work->source_order[target_position];
        while (source_cursor <= middle) {
            const size_t source = (size_t)work->source_order[source_cursor];
            if (work->points[source].y > work->points[target].y) break;
            bit_add(work, (size_t)work->points[source].z_rank,
                    work->points[source].multiplicity, group_count);
            ++source_cursor;
        }
        work->dominated[target] += bit_sum(work, (size_t)work->points[target].z_rank);
    }
    for (size_t i = left; i < source_cursor; ++i) {
        const size_t source = (size_t)work->source_order[i];
        bit_add(work, (size_t)work->points[source].z_rank,
                -work->points[source].multiplicity, group_count);
    }

    size_t left_cursor = left, right_cursor = middle + 1, destination = left;
    while (left_cursor <= middle && right_cursor <= right) {
        const size_t left_point = (size_t)work->source_order[left_cursor];
        const size_t right_point = (size_t)work->source_order[right_cursor];
        if (work->points[left_point].y <= work->points[right_point].y)
            work->target_order[destination++] = (int64_t)work->source_order[left_cursor++];
        else
            work->target_order[destination++] = (int64_t)work->source_order[right_cursor++];
    }
    while (left_cursor <= middle)
        work->target_order[destination++] = (int64_t)work->source_order[left_cursor++];
    while (right_cursor <= right)
        work->target_order[destination++] = (int64_t)work->source_order[right_cursor++];
    for (size_t i = left; i <= right; ++i) work->source_order[i] = work->target_order[i];
}

int64_t cdq_three_dimensional_dominance(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 3 * n) return -1;

    Workspace work = {0};
    for (size_t i = 0; i < n; ++i) {
        const int64_t x = input[1 + 3 * i];
        const int64_t y = input[2 + 3 * i];
        const int64_t z = input[3 + 3 * i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000 || z < -1000 || z > 1000)
            return -1;
        work.points[i] = (Point){x, y, z, 1, 0, (int64_t)i};
    }
    sort_points(work.points, n);

    size_t group_count = 0;
    for (size_t i = 0; i < n; ++i) {
        if (group_count > 0 && same_coordinates(work.points[i], work.points[group_count - 1])) {
            ++work.points[group_count - 1].multiplicity;
            work.original_group[(size_t)work.points[i].original_index] = (int64_t)(group_count - 1);
        } else {
            work.points[group_count] = work.points[i];
            work.points[group_count].multiplicity = 1;
            work.original_group[(size_t)work.points[group_count].original_index] = (int64_t)group_count;
            ++group_count;
        }
    }

    for (size_t i = 0; i < group_count; ++i) work.z_values[i] = work.points[i].z;
    for (size_t i = 1; i < group_count; ++i) {
        const int64_t value = work.z_values[i];
        size_t j = i;
        while (j > 0 && value < work.z_values[j - 1]) {
            work.z_values[j] = work.z_values[j - 1];
            --j;
        }
        work.z_values[j] = value;
    }
    size_t z_count = 0;
    for (size_t i = 0; i < group_count; ++i) {
        if (z_count == 0 || work.z_values[i] != work.z_values[z_count - 1])
            work.z_values[z_count++] = work.z_values[i];
    }
    for (size_t i = 0; i < group_count; ++i) {
        size_t low = 0, high = z_count;
        while (low < high) {
            const size_t middle = low + (high - low) / 2;
            if (work.z_values[middle] < work.points[i].z) low = middle + 1;
            else high = middle;
        }
        work.points[i].z_rank = (int64_t)(low + 1);
        work.source_order[i] = (int64_t)i;
    }

    if (group_count > 1) cdq(&work, 0, group_count - 1, z_count);
    int64_t result = 0;
    for (size_t i = 0; i < n; ++i) {
        const size_t group = (size_t)work.original_group[i];
        const int64_t count = work.dominated[group] + work.points[group].multiplicity - 1;
        result += (int64_t)(i + 1) * count;
    }
    return result;
}
