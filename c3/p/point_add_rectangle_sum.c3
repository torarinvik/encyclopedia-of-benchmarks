module point_add_rectangle_sum;

const int MAX_N = 32;
const int MAX_Q = 32;
const int MAX_POINTS = MAX_N + MAX_Q;
const usz MAX_PARSEABLE_INPUT_VALUES = 2 + 3 * (usz)MAX_N + 5 * (usz)MAX_Q + 1;
const long MAX_COORD = 1000000;
const long MAX_WEIGHT = 1000000;

fn usz lowbit(usz value) { return value & (~value + 1); }

fn usz lower_bound_long(long* values, usz count, long target) {
    usz left = 0, right = count;
    while (left < right) {
        usz middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

fn usz lower_bound_usz(usz* values, usz count, usz target) {
    usz left = 0, right = count;
    while (left < right) {
        usz middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

fn usz sort_unique_long(long* values, usz count) {
    for (usz index = 1; index < count; index++) {
        long value = values[index];
        usz position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            position--;
        }
        values[position] = value;
    }
    usz unique_count = 0;
    for (usz index = 0; index < count; index++) {
        if (unique_count == 0 || values[index] != values[unique_count - 1])
            values[unique_count++] = values[index];
    }
    return unique_count;
}

fn void register_coordinate(long* xs, usz x_count, long* ys, usz y_count,
                            int* present, long x, long y) {
    usz outer = lower_bound_long(xs, x_count, x) + 1;
    usz rank = lower_bound_long(ys, y_count, y);
    while (outer <= x_count) {
        present[outer * MAX_POINTS + rank] = 1;
        outer += lowbit(outer);
    }
}

fn void fenwick_add(long* tree, usz* y_values, usz* y_counts, usz x_count,
                    long* xs, long* ys, usz y_count,
                    long x, long y, long weight) {
    usz outer = lower_bound_long(xs, x_count, x) + 1;
    usz y_rank = lower_bound_long(ys, y_count, y);
    while (outer <= x_count) {
        usz row = outer * MAX_POINTS;
        usz inner = lower_bound_usz(&y_values[row], y_counts[outer], y_rank) + 1;
        while (inner <= y_counts[outer]) {
            tree[outer * (MAX_POINTS + 1) + inner] += weight;
            inner += lowbit(inner);
        }
        outer += lowbit(outer);
    }
}

fn long prefix_sum(long* tree, usz* y_values, usz* y_counts, usz x_count,
                   long* xs, long* ys, usz y_count, long x_limit, long y_limit) {
    usz outer = lower_bound_long(xs, x_count, x_limit);
    usz y_limit_rank = lower_bound_long(ys, y_count, y_limit);
    long total = 0;
    while (outer > 0) {
        usz row = outer * MAX_POINTS;
        usz inner = lower_bound_usz(&y_values[row], y_counts[outer], y_limit_rank);
        while (inner > 0) {
            total += tree[outer * (MAX_POINTS + 1) + inner];
            inner -= lowbit(inner);
        }
        outer -= lowbit(outer);
    }
    return total;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long point_add_rectangle_sum(long* input, usz length, char* output, usz capacity)
    @export("point_add_rectangle_sum") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    long nv = input[0], qv = input[1];
    if (nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q) return -1;
    int n = (int)nv, q = (int)qv;

    long[MAX_N] initial_x, initial_y, initial_weight;
    long[MAX_Q] kinds, op_a, op_b, op_c, op_d;
    long[MAX_POINTS] all_x, all_y;
    usz point_count = 0, cursor = 2;
    for (int index = 0; index < n; index++) {
        if (cursor + 3 > length) return -1;
        long x = input[cursor++], y = input[cursor++], weight = input[cursor++];
        if (x < 0 || x > MAX_COORD || y < 0 || y > MAX_COORD ||
            weight < 0 || weight > MAX_WEIGHT) return -1;
        initial_x[index] = x; initial_y[index] = y; initial_weight[index] = weight;
        all_x[point_count] = x; all_y[point_count++] = y;
    }
    usz query_count = 0;
    for (int index = 0; index < q; index++) {
        if (cursor >= length) return -1;
        long kind = input[cursor++];
        kinds[index] = kind;
        if (kind == 0) {
            if (cursor + 3 > length) return -1;
            long x = input[cursor++], y = input[cursor++], weight = input[cursor++];
            if (x < 0 || x > MAX_COORD || y < 0 || y > MAX_COORD ||
                weight < 0 || weight > MAX_WEIGHT) return -1;
            op_a[index] = x; op_b[index] = y; op_c[index] = weight; op_d[index] = 0;
            all_x[point_count] = x; all_y[point_count++] = y;
        } else if (kind == 1) {
            if (cursor + 4 > length) return -1;
            long left = input[cursor++], down = input[cursor++];
            long right = input[cursor++], up = input[cursor++];
            if (left < 0 || left >= right || right > MAX_COORD ||
                down < 0 || down >= up || up > MAX_COORD) return -1;
            op_a[index] = left; op_b[index] = down; op_c[index] = right; op_d[index] = up;
            query_count++;
        } else return -1;
    }
    if (cursor != length) return -1;

    usz x_count = sort_unique_long(&all_x[0], point_count);
    usz y_count = sort_unique_long(&all_y[0], point_count);
    int[(MAX_POINTS + 1) * MAX_POINTS] present;
    for (usz i = 0; i < (usz)((MAX_POINTS + 1) * MAX_POINTS); i++) present[i] = 0;
    for (int i = 0; i < n; i++)
        register_coordinate(&all_x[0], x_count, &all_y[0], y_count, &present[0], initial_x[i], initial_y[i]);
    for (int i = 0; i < q; i++) if (kinds[i] == 0)
        register_coordinate(&all_x[0], x_count, &all_y[0], y_count, &present[0], op_a[i], op_b[i]);

    usz[(MAX_POINTS + 1) * MAX_POINTS] y_values;
    usz[MAX_POINTS + 1] y_counts;
    for (int i = 0; i <= MAX_POINTS; i++) y_counts[i] = 0;
    for (int outer = 1; outer <= (int)x_count; outer++)
        for (int rank = 0; rank < (int)y_count; rank++)
            if (present[outer * MAX_POINTS + rank] != 0)
                y_values[outer * MAX_POINTS + y_counts[outer]++] = (usz)rank;

    long[(MAX_POINTS + 1) * (MAX_POINTS + 1)] tree;
    for (usz i = 0; i < (usz)((MAX_POINTS + 1) * (MAX_POINTS + 1)); i++) tree[i] = 0;
    for (int i = 0; i < n; i++)
        fenwick_add(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count,
            initial_x[i], initial_y[i], initial_weight[i]);
    long[MAX_Q] answers;
    usz answer_count = 0;
    for (int i = 0; i < q; i++) {
        if (kinds[i] == 0) {
            fenwick_add(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count,
                op_a[i], op_b[i], op_c[i]);
        } else {
            answers[answer_count++] =
                prefix_sum(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count, op_c[i], op_d[i]) -
                prefix_sum(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count, op_a[i], op_d[i]) -
                prefix_sum(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count, op_c[i], op_b[i]) +
                prefix_sum(&tree[0], &y_values[0], &y_counts[0], x_count, &all_x[0], &all_y[0], y_count, op_a[i], op_b[i]);
        }
    }
    usz output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;
    for (usz i = 0; i < answer_count; i++) put_i64_le(output, 8 * i, answers[i]);
    return (long)output_bytes;
}
