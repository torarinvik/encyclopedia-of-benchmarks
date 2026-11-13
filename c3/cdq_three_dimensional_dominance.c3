module cdq_three_dimensional_dominance;

const usz MAX_N = 64;
const usz MAX_PARSEABLE_LENGTH = 194;

struct Point {
    long x;
    long y;
    long z;
    long multiplicity;
    usz z_rank;
    usz original_index;
}

struct Workspace {
    Point[MAX_N] points;
    usz[MAX_N] original_group;
    long[MAX_N] dominated;
    long[MAX_N + 1] bit;
    usz[MAX_N] source_order;
    usz[MAX_N] target_order;
    long[MAX_N] z_values;
}

fn bool point_less(Point a, Point b) {
    if (a.x != b.x) return a.x < b.x;
    if (a.y != b.y) return a.y < b.y;
    return a.z < b.z;
}

fn bool same_coordinates(Point a, Point b) {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

fn void bit_add(Workspace* work, usz index_value, long delta, usz limit) {
    usz index = index_value;
    while (index <= limit) {
        work.bit[index] += delta;
        index += index & (0 - index);
    }
}

fn long bit_sum(Workspace* work, usz index_value) {
    usz index = index_value;
    long total = 0;
    while (index > 0) {
        total += work.bit[index];
        index -= index & (0 - index);
    }
    return total;
}

fn void cdq(Workspace* work, usz left, usz right, usz group_count) {
    if (left >= right) return;
    usz middle = left + (right - left) / 2;
    cdq(work, left, middle, group_count);
    cdq(work, middle + 1, right, group_count);

    usz source_cursor = left;
    for (usz target_position = middle + 1; target_position <= right; ++target_position) {
        usz target = work.source_order[target_position];
        while (source_cursor <= middle) {
            usz source = work.source_order[source_cursor];
            if (work.points[source].y > work.points[target].y) break;
            bit_add(work, work.points[source].z_rank, work.points[source].multiplicity, group_count);
            ++source_cursor;
        }
        work.dominated[target] += bit_sum(work, work.points[target].z_rank);
    }
    for (usz i = left; i < source_cursor; ++i) {
        usz source = work.source_order[i];
        bit_add(work, work.points[source].z_rank, -work.points[source].multiplicity, group_count);
    }

    usz left_cursor = left, right_cursor = middle + 1, destination = left;
    while (left_cursor <= middle && right_cursor <= right) {
        usz left_point = work.source_order[left_cursor];
        usz right_point = work.source_order[right_cursor];
        if (work.points[left_point].y <= work.points[right_point].y)
            work.target_order[destination++] = work.source_order[left_cursor++];
        else
            work.target_order[destination++] = work.source_order[right_cursor++];
    }
    while (left_cursor <= middle) work.target_order[destination++] = work.source_order[left_cursor++];
    while (right_cursor <= right) work.target_order[destination++] = work.source_order[right_cursor++];
    for (usz i = left; i <= right; ++i) work.source_order[i] = work.target_order[i];
}

fn long cdq_three_dimensional_dominance(long* input, usz length)
        @export("cdq_three_dimensional_dominance") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 3 * n) return -1;

    Workspace work = {};
    for (usz i = 0; i < n; ++i) {
        long x = input[1 + 3 * i];
        long y = input[2 + 3 * i];
        long z = input[3 + 3 * i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000 || z < -1000 || z > 1000) return -1;
        work.points[i].x = x;
        work.points[i].y = y;
        work.points[i].z = z;
        work.points[i].multiplicity = 1;
        work.points[i].original_index = i;
    }

    for (usz i = 1; i < n; ++i) {
        Point value = work.points[i];
        usz j = i;
        while (j > 0 && point_less(value, work.points[j - 1])) {
            work.points[j] = work.points[j - 1];
            --j;
        }
        work.points[j] = value;
    }

    usz group_count = 0;
    for (usz i = 0; i < n; ++i) {
        Point point = work.points[i];
        if (group_count > 0 && same_coordinates(point, work.points[group_count - 1])) {
            ++work.points[group_count - 1].multiplicity;
            work.original_group[point.original_index] = group_count - 1;
        } else {
            work.points[group_count] = point;
            work.points[group_count].multiplicity = 1;
            work.original_group[point.original_index] = group_count;
            ++group_count;
        }
    }

    for (usz i = 0; i < group_count; ++i) work.z_values[i] = work.points[i].z;
    for (usz i = 1; i < group_count; ++i) {
        long value = work.z_values[i];
        usz j = i;
        while (j > 0 && value < work.z_values[j - 1]) {
            work.z_values[j] = work.z_values[j - 1];
            --j;
        }
        work.z_values[j] = value;
    }
    usz z_count = 0;
    for (usz i = 0; i < group_count; ++i) {
        long value = work.z_values[i];
        if (z_count == 0 || value != work.z_values[z_count - 1])
            work.z_values[z_count++] = value;
    }
    for (usz i = 0; i < group_count; ++i) {
        usz low = 0, high = z_count;
        while (low < high) {
            usz middle = low + (high - low) / 2;
            if (work.z_values[middle] < work.points[i].z) low = middle + 1;
            else high = middle;
        }
        work.points[i].z_rank = low + 1;
        work.source_order[i] = i;
    }

    if (group_count > 1) cdq(&work, 0, group_count - 1, z_count);
    long result = 0;
    for (usz i = 0; i < n; ++i) {
        usz group = work.original_group[i];
        long count = work.dominated[group] + work.points[group].multiplicity - 1;
        result += (long)(i + 1) * count;
    }
    return result;
}
