module rectangle_add_point_get;

const int MAX_N = 32;
const int MAX_Q = 32;
const int MAX_RECTANGLES = MAX_N + MAX_Q;
const int MAX_COORDS = 2 * MAX_RECTANGLES;
const int MAX_CORNERS = 4 * MAX_RECTANGLES;
const usz MAX_PARSEABLE_INPUT = 2 + 5 * (usz)MAX_N + 6 * (usz)MAX_Q + 1;
const long MAX_COORD = 1000000;
const long MAX_WEIGHT = 1000000;

struct Rectangle { long left, down, right, up, weight; }
struct Operation { long kind, a, b, c, d, e; }

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

fn usz upper_bound_long(long* values, usz count, long target) {
    usz left = 0, right = count;
    while (left < right) {
        usz middle = left + (right - left) / 2;
        if (values[middle] <= target) left = middle + 1;
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

fn usz sort_unique(long* values, usz count) {
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

fn void register_event(long* xs, usz x_count, long* ys, usz y_count,
                       bool* present, long x, long y) {
    usz outer = lower_bound_long(xs, x_count, x) + 1;
    usz rank = lower_bound_long(ys, y_count, y);
    while (outer <= x_count) {
        present[outer * MAX_COORDS + rank] = true;
        outer += lowbit(outer);
    }
}

fn void register_rectangle(long* xs, usz x_count, long* ys, usz y_count,
                           bool* present, Rectangle rectangle) {
    register_event(xs, x_count, ys, y_count, present, rectangle.left, rectangle.down);
    register_event(xs, x_count, ys, y_count, present, rectangle.right, rectangle.down);
    register_event(xs, x_count, ys, y_count, present, rectangle.left, rectangle.up);
    register_event(xs, x_count, ys, y_count, present, rectangle.right, rectangle.up);
}

fn void fenwick_add(long* tree, usz* y_values, usz* y_counts,
                    long* xs, usz x_count, long* ys, usz y_count,
                    long x, long y, long weight) {
    usz outer = lower_bound_long(xs, x_count, x) + 1;
    usz y_rank = lower_bound_long(ys, y_count, y);
    while (outer <= x_count) {
        usz row = outer * MAX_COORDS;
        usz inner = lower_bound_usz(&y_values[row], y_counts[outer], y_rank) + 1;
        while (inner <= y_counts[outer]) {
            tree[outer * (MAX_COORDS + 1) + inner] += weight;
            inner += lowbit(inner);
        }
        outer += lowbit(outer);
    }
}

fn void apply_rectangle(long* tree, usz* y_values, usz* y_counts,
    long* xs, usz x_count, long* ys, usz y_count, Rectangle rectangle) {
    long weight = rectangle.weight;
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.left, rectangle.down, weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.right, rectangle.down, -weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.left, rectangle.up, -weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
        rectangle.right, rectangle.up, weight);
}

fn long prefix_sum(long* tree, usz* y_values, usz* y_counts,
    long* xs, usz x_count, long* ys, usz y_count, long x_limit, long y_limit) {
    usz outer = upper_bound_long(xs, x_count, x_limit);
    usz y_limit_rank = upper_bound_long(ys, y_count, y_limit);
    long total = 0;
    while (outer > 0) {
        usz row = outer * MAX_COORDS;
        usz inner = lower_bound_usz(&y_values[row], y_counts[outer], y_limit_rank);
        while (inner > 0) {
            total += tree[outer * (MAX_COORDS + 1) + inner];
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

fn long rectangle_add_point_get(long* input, usz length, char* output, usz capacity)
    @export("rectangle_add_point_get") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    long nv = input[0], qv = input[1];
    if (nv < 1 || nv > MAX_N || qv < 1 || qv > MAX_Q) return -1;
    int n = (int)nv, q = (int)qv;
    Rectangle[MAX_N] initial;
    Operation[MAX_Q] operations;
    long[MAX_CORNERS] all_x, all_y;
    usz rectangle_count = 0, cursor = 2;
    for (int index = 0; index < n; index++) {
        if (cursor + 5 > length) return -1;
        Rectangle rectangle = {input[cursor], input[cursor + 1], input[cursor + 2],
                               input[cursor + 3], input[cursor + 4]};
        cursor += 5;
        if (rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > MAX_COORD ||
            rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > MAX_COORD ||
            rectangle.weight < 0 || rectangle.weight > MAX_WEIGHT) return -1;
        initial[index] = rectangle;
        long[4] corner_x = {rectangle.left, rectangle.right, rectangle.left, rectangle.right};
        long[4] corner_y = {rectangle.down, rectangle.down, rectangle.up, rectangle.up};
        for (usz corner = 0; corner < 4; corner++) {
            all_x[rectangle_count * 4 + corner] = corner_x[corner];
            all_y[rectangle_count * 4 + corner] = corner_y[corner];
        }
        rectangle_count++;
    }
    for (int index = 0; index < q; index++) {
        if (cursor >= length) return -1;
        long kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 5 > length) return -1;
            Rectangle rectangle = {input[cursor], input[cursor + 1], input[cursor + 2],
                                   input[cursor + 3], input[cursor + 4]};
            cursor += 5;
            if (rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > MAX_COORD ||
                rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > MAX_COORD ||
                rectangle.weight < 0 || rectangle.weight > MAX_WEIGHT) return -1;
            operations[index] = {0, rectangle.left, rectangle.down,
                                 rectangle.right, rectangle.up, rectangle.weight};
            long[4] corner_x = {rectangle.left, rectangle.right, rectangle.left, rectangle.right};
            long[4] corner_y = {rectangle.down, rectangle.down, rectangle.up, rectangle.up};
            for (usz corner = 0; corner < 4; corner++) {
                all_x[rectangle_count * 4 + corner] = corner_x[corner];
                all_y[rectangle_count * 4 + corner] = corner_y[corner];
            }
            rectangle_count++;
        } else if (kind == 1) {
            if (cursor + 2 > length) return -1;
            long x = input[cursor++], y = input[cursor++];
            if (x < 0 || x > MAX_COORD || y < 0 || y > MAX_COORD) return -1;
            operations[index] = {1, x, y, 0, 0, 0};
        } else return -1;
    }
    if (cursor != length) return -1;

    usz corner_count = rectangle_count * 4;
    usz x_count = sort_unique(&all_x[0], corner_count);
    usz y_count = sort_unique(&all_y[0], corner_count);
    bool[(MAX_COORDS + 1) * MAX_COORDS] present;
    for (usz i = 0; i < (usz)((MAX_COORDS + 1) * MAX_COORDS); i++) present[i] = false;
    for (int i = 0; i < n; i++) register_rectangle(&all_x[0], x_count, &all_y[0], y_count, &present[0], initial[i]);
    for (int i = 0; i < q; i++) if (operations[i].kind == 0) {
        Rectangle rectangle = {operations[i].a, operations[i].b, operations[i].c,
                               operations[i].d, operations[i].e};
        register_rectangle(&all_x[0], x_count, &all_y[0], y_count, &present[0], rectangle);
    }
    usz[(MAX_COORDS + 1) * MAX_COORDS] y_values;
    usz[MAX_COORDS + 1] y_counts;
    for (int i = 0; i <= MAX_COORDS; i++) y_counts[i] = 0;
    for (usz outer = 1; outer <= x_count; outer++)
        for (usz rank = 0; rank < y_count; rank++)
            if (present[outer * MAX_COORDS + rank])
                y_values[outer * MAX_COORDS + y_counts[outer]++] = rank;
    long[(MAX_COORDS + 1) * (MAX_COORDS + 1)] tree;
    for (usz i = 0; i < (usz)((MAX_COORDS + 1) * (MAX_COORDS + 1)); i++) tree[i] = 0;
    for (int i = 0; i < n; i++) apply_rectangle(&tree[0], &y_values[0], &y_counts[0],
        &all_x[0], x_count, &all_y[0], y_count, initial[i]);
    long[MAX_Q] answers;
    usz answer_count = 0;
    for (int i = 0; i < q; i++) {
        Operation operation = operations[i];
        if (operation.kind == 0) {
            Rectangle rectangle = {operation.a, operation.b, operation.c, operation.d, operation.e};
            apply_rectangle(&tree[0], &y_values[0], &y_counts[0], &all_x[0], x_count,
                &all_y[0], y_count, rectangle);
        } else answers[answer_count++] = prefix_sum(&tree[0], &y_values[0], &y_counts[0],
            &all_x[0], x_count, &all_y[0], y_count, operation.a, operation.b);
    }
    usz output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;
    for (usz i = 0; i < answer_count; i++) put_i64_le(output, 8 * i, answers[i]);
    return (long)output_bytes;
}
