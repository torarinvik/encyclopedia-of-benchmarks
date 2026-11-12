#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_Q 32
#define MAX_RECTANGLES (MAX_N + MAX_Q)
#define MAX_COORDS (2 * MAX_RECTANGLES)
#define MAX_CORNERS (4 * MAX_RECTANGLES)
#define MAX_PARSEABLE_INPUT (2 + 5 * MAX_N + 6 * MAX_Q + 1)
#define MAX_COORD INT64_C(1000000)
#define MAX_WEIGHT INT64_C(1000000)

typedef struct { int64_t left, down, right, up, weight; } Rectangle;
typedef struct { int64_t kind, a, b, c, d, e; } Operation;

static size_t lowbit(size_t value) { return value & (~value + 1); }

static size_t lower_bound_i64(const int64_t *values, size_t count, int64_t target) {
    size_t left = 0, right = count;
    while (left < right) {
        size_t middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

static size_t upper_bound_i64(const int64_t *values, size_t count, int64_t target) {
    size_t left = 0, right = count;
    while (left < right) {
        size_t middle = left + (right - left) / 2;
        if (values[middle] <= target) left = middle + 1;
        else right = middle;
    }
    return left;
}

static size_t lower_bound_size(const size_t *values, size_t count, size_t target) {
    size_t left = 0, right = count;
    while (left < right) {
        size_t middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

static size_t sort_unique(int64_t *values, size_t count) {
    for (size_t index = 1; index < count; ++index) {
        int64_t value = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
    size_t unique_count = 0;
    for (size_t index = 0; index < count; ++index) {
        if (unique_count == 0 || values[index] != values[unique_count - 1])
            values[unique_count++] = values[index];
    }
    return unique_count;
}

static void register_event(const int64_t *xs, size_t x_count,
    const int64_t *ys, size_t y_count,
    uint8_t *present, int64_t x, int64_t y) {
    size_t outer = lower_bound_i64(xs, x_count, x) + 1;
    size_t rank = lower_bound_i64(ys, y_count, y);
    while (outer <= x_count) {
        present[outer * MAX_COORDS + rank] = 1;
        outer += lowbit(outer);
    }
}

static void register_rectangle(const int64_t *xs, size_t x_count,
    const int64_t *ys, size_t y_count, uint8_t *present, const Rectangle *rectangle) {
    register_event(xs, x_count, ys, y_count, present, rectangle->left, rectangle->down);
    register_event(xs, x_count, ys, y_count, present, rectangle->right, rectangle->down);
    register_event(xs, x_count, ys, y_count, present, rectangle->left, rectangle->up);
    register_event(xs, x_count, ys, y_count, present, rectangle->right, rectangle->up);
}

static void fenwick_add(int64_t *tree, const size_t *y_values, const size_t *y_counts,
    const int64_t *xs, size_t x_count, const int64_t *ys, size_t y_count,
    int64_t x, int64_t y, int64_t weight) {
    size_t outer = lower_bound_i64(xs, x_count, x) + 1;
    size_t y_rank = lower_bound_i64(ys, y_count, y);
    while (outer <= x_count) {
        size_t row = outer * MAX_COORDS;
        size_t inner = lower_bound_size(&y_values[row], y_counts[outer], y_rank) + 1;
        while (inner <= y_counts[outer]) {
            tree[outer * (MAX_COORDS + 1) + inner] += weight;
            inner += lowbit(inner);
        }
        outer += lowbit(outer);
    }
}

static void apply_rectangle(int64_t *tree, const size_t *y_values,
    const size_t *y_counts, const int64_t *xs, size_t x_count,
    const int64_t *ys, size_t y_count, const Rectangle *rectangle) {
    int64_t weight = rectangle->weight;
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
                rectangle->left, rectangle->down, weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
                rectangle->right, rectangle->down, -weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
                rectangle->left, rectangle->up, -weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
                rectangle->right, rectangle->up, weight);
}

static int64_t prefix_sum(const int64_t *tree, const size_t *y_values,
    const size_t *y_counts, const int64_t *xs, size_t x_count,
    const int64_t *ys, size_t y_count, int64_t x_limit, int64_t y_limit) {
    size_t outer = upper_bound_i64(xs, x_count, x_limit);
    size_t y_limit_rank = upper_bound_i64(ys, y_count, y_limit);
    int64_t total = 0;
    while (outer > 0) {
        size_t row = outer * MAX_COORDS;
        size_t inner = lower_bound_size(&y_values[row], y_counts[outer], y_limit_rank);
        while (inner > 0) {
            total += tree[outer * (MAX_COORDS + 1) + inner];
            inner -= lowbit(inner);
        }
        outer -= lowbit(outer);
    }
    return total;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t rectangle_add_point_get(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    int64_t nv = input[0], qv = input[1];
    if (nv < 1 || nv > MAX_N || qv < 1 || qv > MAX_Q) return -1;
    size_t n = (size_t)nv, q = (size_t)qv;
    Rectangle initial[MAX_N] = {{0}};
    Operation operations[MAX_Q] = {{0}};
    int64_t all_x[MAX_CORNERS] = {0}, all_y[MAX_CORNERS] = {0};
    size_t rectangle_count = 0, cursor = 2;
    for (size_t index = 0; index < n; ++index) {
        if (cursor + 5 > length) return -1;
        Rectangle rectangle = {input[cursor], input[cursor + 1], input[cursor + 2],
                               input[cursor + 3], input[cursor + 4]};
        cursor += 5;
        if (rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > MAX_COORD ||
            rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > MAX_COORD ||
            rectangle.weight < 0 || rectangle.weight > MAX_WEIGHT) return -1;
        initial[index] = rectangle;
        const int64_t corner_x[4] = {rectangle.left, rectangle.right, rectangle.left, rectangle.right};
        const int64_t corner_y[4] = {rectangle.down, rectangle.down, rectangle.up, rectangle.up};
        for (size_t corner = 0; corner < 4; ++corner) {
            all_x[rectangle_count * 4 + corner] = corner_x[corner];
            all_y[rectangle_count * 4 + corner] = corner_y[corner];
        }
        ++rectangle_count;
    }
    for (size_t index = 0; index < q; ++index) {
        if (cursor >= length) return -1;
        int64_t kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 5 > length) return -1;
            Rectangle rectangle = {input[cursor], input[cursor + 1], input[cursor + 2],
                                   input[cursor + 3], input[cursor + 4]};
            cursor += 5;
            if (rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > MAX_COORD ||
                rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > MAX_COORD ||
                rectangle.weight < 0 || rectangle.weight > MAX_WEIGHT) return -1;
            operations[index] = (Operation){0, rectangle.left, rectangle.down,
                                             rectangle.right, rectangle.up, rectangle.weight};
            const int64_t corner_x[4] = {rectangle.left, rectangle.right, rectangle.left, rectangle.right};
            const int64_t corner_y[4] = {rectangle.down, rectangle.down, rectangle.up, rectangle.up};
            for (size_t corner = 0; corner < 4; ++corner) {
                all_x[rectangle_count * 4 + corner] = corner_x[corner];
                all_y[rectangle_count * 4 + corner] = corner_y[corner];
            }
            ++rectangle_count;
        } else if (kind == 1) {
            if (cursor + 2 > length) return -1;
            int64_t x = input[cursor++], y = input[cursor++];
            if (x < 0 || x > MAX_COORD || y < 0 || y > MAX_COORD) return -1;
            operations[index] = (Operation){1, x, y, 0, 0, 0};
        } else return -1;
    }
    if (cursor != length) return -1;

    size_t corner_count = rectangle_count * 4;
    size_t x_count = sort_unique(all_x, corner_count);
    size_t y_count = sort_unique(all_y, corner_count);
    uint8_t present[(MAX_COORDS + 1) * MAX_COORDS] = {0};
    for (size_t index = 0; index < n; ++index)
        register_rectangle(all_x, x_count, all_y, y_count, present, &initial[index]);
    for (size_t index = 0; index < q; ++index) if (operations[index].kind == 0) {
        Rectangle rectangle = {operations[index].a, operations[index].b,
            operations[index].c, operations[index].d, operations[index].e};
        register_rectangle(all_x, x_count, all_y, y_count, present, &rectangle);
    }

    size_t y_values[(MAX_COORDS + 1) * MAX_COORDS] = {0};
    size_t y_counts[MAX_COORDS + 1] = {0};
    for (size_t outer = 1; outer <= x_count; ++outer)
        for (size_t rank = 0; rank < y_count; ++rank)
            if (present[outer * MAX_COORDS + rank])
                y_values[outer * MAX_COORDS + y_counts[outer]++] = rank;
    int64_t tree[(MAX_COORDS + 1) * (MAX_COORDS + 1)] = {0};
    for (size_t index = 0; index < n; ++index)
        apply_rectangle(tree, y_values, y_counts, all_x, x_count, all_y, y_count, &initial[index]);
    int64_t answers[MAX_Q] = {0};
    size_t answer_count = 0;
    for (size_t index = 0; index < q; ++index) {
        Operation operation = operations[index];
        if (operation.kind == 0) {
            Rectangle rectangle = {operation.a, operation.b, operation.c,
                                   operation.d, operation.e};
            apply_rectangle(tree, y_values, y_counts, all_x, x_count, all_y, y_count, &rectangle);
        } else {
            answers[answer_count++] = prefix_sum(tree, y_values, y_counts, all_x,
                x_count, all_y, y_count, operation.a, operation.b);
        }
    }
    size_t output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (output == NULL || capacity < output_bytes)) return -2;
    for (size_t index = 0; index < answer_count; ++index)
        store_i64_le(output, 8 * index, answers[index]);
    return (int64_t)output_bytes;
}
