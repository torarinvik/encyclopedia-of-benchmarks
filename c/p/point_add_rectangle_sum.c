#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_Q 32
#define MAX_POINTS (MAX_N + MAX_Q)
#define MAX_PARSEABLE_INPUT_VALUES (2 + 3 * MAX_N + 5 * MAX_Q + 1)
#define MAX_COORD INT64_C(1000000)
#define MAX_WEIGHT INT64_C(1000000)

typedef struct { int64_t x, y, weight; } point;
typedef struct { int64_t kind, a, b, c, d; } operation;

static size_t lowbit(size_t value) { return value & (~value + 1); }

static size_t lower_bound_i64(const int64_t *values, size_t count, int64_t target) {
    size_t left = 0, right = count;
    while (left < right) {
        const size_t middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

static size_t lower_bound_size(const size_t *values, size_t count, size_t target) {
    size_t left = 0, right = count;
    while (left < right) {
        const size_t middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

static size_t sort_unique_i64(int64_t *values, size_t count) {
    for (size_t index = 1; index < count; ++index) {
        const int64_t value = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
    size_t unique_count = 0;
    for (size_t index = 0; index < count; ++index)
        if (unique_count == 0 || values[index] != values[unique_count - 1])
            values[unique_count++] = values[index];
    return unique_count;
}

static void register_coordinate(const int64_t *xs, size_t x_count,
        const int64_t *ys, size_t y_count, int *present,
        int64_t x, int64_t y) {
    size_t outer = lower_bound_i64(xs, x_count, x) + 1;
    const size_t y_rank = lower_bound_i64(ys, y_count, y);
    while (outer <= x_count) {
        present[outer * MAX_POINTS + y_rank] = 1;
        outer += lowbit(outer);
    }
}

static void fenwick_add(int64_t *tree,
        const size_t *y_values,
        const size_t y_counts[MAX_POINTS + 1], size_t x_count,
        int64_t x, int64_t y, int64_t weight,
        const int64_t *xs, const int64_t *ys, size_t y_count) {
    size_t outer = lower_bound_i64(xs, x_count, x) + 1;
    const size_t y_rank = lower_bound_i64(ys, y_count, y);
    while (outer <= x_count) {
        const size_t row = outer * MAX_POINTS;
        size_t inner = lower_bound_size(&y_values[row], y_counts[outer], y_rank) + 1;
        while (inner <= y_counts[outer]) {
            tree[outer * (MAX_POINTS + 1) + inner] += weight;
            inner += lowbit(inner);
        }
        outer += lowbit(outer);
    }
}

static int64_t prefix_sum(const int64_t *tree,
        const size_t *y_values,
        const size_t y_counts[MAX_POINTS + 1], size_t x_count,
        const int64_t *xs, const int64_t *ys, size_t y_count,
        int64_t x_limit, int64_t y_limit) {
    size_t outer = lower_bound_i64(xs, x_count, x_limit);
    const size_t y_limit_rank = lower_bound_i64(ys, y_count, y_limit);
    int64_t total = 0;
    while (outer > 0) {
        const size_t row = outer * MAX_POINTS;
        size_t inner = lower_bound_size(&y_values[row], y_counts[outer], y_limit_rank);
        while (inner > 0) {
            total += tree[outer * (MAX_POINTS + 1) + inner];
            inner -= lowbit(inner);
        }
        outer -= lowbit(outer);
    }
    return total;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t point_add_rectangle_sum(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;

    point initial[MAX_N];
    operation operations[MAX_Q];
    int64_t all_x[MAX_POINTS], all_y[MAX_POINTS];
    size_t point_count = 0, cursor = 2;
    for (size_t index = 0; index < n; ++index) {
        if (cursor + 3 > length) return -1;
        const int64_t x = input[cursor++], y = input[cursor++], weight = input[cursor++];
        if (x < 0 || x > MAX_COORD || y < 0 || y > MAX_COORD ||
            weight < 0 || weight > MAX_WEIGHT) return -1;
        initial[index] = (point){x, y, weight};
        all_x[point_count] = x;
        all_y[point_count++] = y;
    }

    size_t query_count = 0;
    for (size_t index = 0; index < q; ++index) {
        if (cursor >= length) return -1;
        const int64_t kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 3 > length) return -1;
            const int64_t x = input[cursor++], y = input[cursor++], weight = input[cursor++];
            if (x < 0 || x > MAX_COORD || y < 0 || y > MAX_COORD ||
                weight < 0 || weight > MAX_WEIGHT) return -1;
            operations[index] = (operation){0, x, y, weight, 0};
            all_x[point_count] = x;
            all_y[point_count++] = y;
        } else if (kind == 1) {
            if (cursor + 4 > length) return -1;
            const int64_t left = input[cursor++], down = input[cursor++];
            const int64_t right = input[cursor++], up = input[cursor++];
            if (left < 0 || left >= right || right > MAX_COORD ||
                down < 0 || down >= up || up > MAX_COORD) return -1;
            operations[index] = (operation){1, left, down, right, up};
            ++query_count;
        } else return -1;
    }
    if (cursor != length) return -1;

    const size_t x_count = sort_unique_i64(all_x, point_count);
    const size_t y_count = sort_unique_i64(all_y, point_count);
    int present[(MAX_POINTS + 1) * MAX_POINTS] = {0};
    for (size_t index = 0; index < n; ++index)
        register_coordinate(all_x, x_count, all_y, y_count, present, initial[index].x, initial[index].y);
    for (size_t index = 0; index < q; ++index)
        if (operations[index].kind == 0)
            register_coordinate(all_x, x_count, all_y, y_count, present,
                operations[index].a, operations[index].b);

    size_t y_values[(MAX_POINTS + 1) * MAX_POINTS] = {0};
    size_t y_counts[MAX_POINTS + 1] = {0};
    for (size_t outer = 1; outer <= x_count; ++outer)
        for (size_t y_rank = 0; y_rank < y_count; ++y_rank)
            if (present[outer * MAX_POINTS + y_rank])
                y_values[outer * MAX_POINTS + y_counts[outer]++] = y_rank;

    int64_t tree[(MAX_POINTS + 1) * (MAX_POINTS + 1)] = {0};
    for (size_t index = 0; index < n; ++index)
        fenwick_add(tree, y_values, y_counts, x_count, initial[index].x, initial[index].y,
            initial[index].weight, all_x, all_y, y_count);

    int64_t answers[MAX_Q];
    size_t answer_count = 0;
    for (size_t index = 0; index < q; ++index) {
        const operation op = operations[index];
        if (op.kind == 0) {
            fenwick_add(tree, y_values, y_counts, x_count, op.a, op.b, op.c,
                all_x, all_y, y_count);
        } else {
            const int64_t result = prefix_sum(tree, y_values, y_counts, x_count,
                all_x, all_y, y_count, op.c, op.d) -
                prefix_sum(tree, y_values, y_counts, x_count, all_x, all_y, y_count, op.a, op.d) -
                prefix_sum(tree, y_values, y_counts, x_count, all_x, all_y, y_count, op.c, op.b) +
                prefix_sum(tree, y_values, y_counts, x_count, all_x, all_y, y_count, op.a, op.b);
            answers[answer_count++] = result;
        }
    }

    const size_t output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (output == NULL || capacity < output_bytes)) return -2;
    for (size_t index = 0; index < answer_count; ++index)
        put_i64_le(output, 8 * index, answers[index]);
    return (int64_t)output_bytes;
}
