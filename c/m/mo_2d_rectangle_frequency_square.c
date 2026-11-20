#include <stddef.h>
#include <stdint.h>

#define MAX_N 8u
#define MAX_Q 32u
#define MAX_INPUT_LENGTH 195u

typedef struct {
    size_t top;
    size_t left;
    size_t bottom;
    size_t right;
    size_t index;
} RectangleQuery;

static int query_before(const RectangleQuery *a, const RectangleQuery *b, size_t block_size) {
    const size_t a_blocks[] = {a->top / block_size, a->left / block_size,
                               a->bottom / block_size, a->right / block_size};
    const size_t b_blocks[] = {b->top / block_size, b->left / block_size,
                               b->bottom / block_size, b->right / block_size};
    for (size_t coordinate = 0; coordinate < 4; ++coordinate) {
        if (a_blocks[coordinate] != b_blocks[coordinate])
            return a_blocks[coordinate] < b_blocks[coordinate];
    }
    const size_t a_coordinates[] = {a->top, a->left, a->bottom, a->right, a->index};
    const size_t b_coordinates[] = {b->top, b->left, b->bottom, b->right, b->index};
    for (size_t coordinate = 0; coordinate < 5; ++coordinate) {
        if (a_coordinates[coordinate] != b_coordinates[coordinate])
            return a_coordinates[coordinate] < b_coordinates[coordinate];
    }
    return 0;
}

static void add_value(int64_t value, int64_t frequency[8], int64_t *sum_squares) {
    *sum_squares += 2 * frequency[value] + 1;
    ++frequency[value];
}

static void remove_value(int64_t value, int64_t frequency[8], int64_t *sum_squares) {
    *sum_squares += 1 - 2 * frequency[value];
    --frequency[value];
}

int64_t mo_2d_rectangle_frequency_square(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t q_value = input[1];
    if (n_value < 1 || n_value > (int64_t)MAX_N || q_value < 0 || q_value > (int64_t)MAX_Q)
        return -1;

    const size_t n = (size_t)n_value;
    const size_t q = (size_t)q_value;
    const size_t matrix_length = n * n;
    if (length != 2 + matrix_length + 4 * q) return -1;

    int64_t matrix[MAX_N * MAX_N];
    for (size_t cell = 0; cell < matrix_length; ++cell) {
        const int64_t value = input[2 + cell];
        if (value < 0 || value > 7) return -1;
        matrix[cell] = value;
    }

    RectangleQuery queries[MAX_Q];
    const size_t query_offset = 2 + matrix_length;
    for (size_t query = 0; query < q; ++query) {
        const int64_t top = input[query_offset + 4 * query];
        const int64_t left = input[query_offset + 4 * query + 1];
        const int64_t bottom = input[query_offset + 4 * query + 2];
        const int64_t right = input[query_offset + 4 * query + 3];
        if (top < 0 || left < 0 || bottom < top || right < left ||
            bottom >= n_value || right >= n_value) return -1;
        queries[query] = (RectangleQuery){(size_t)top, (size_t)left,
                                         (size_t)bottom, (size_t)right, query};
    }

    size_t block_size = 0;
    size_t n_fourth = n * n * n * n;
    for (size_t candidate = 1; candidate <= n; ++candidate) {
        const size_t candidate_fourth = candidate * candidate * candidate * candidate;
        if (q * candidate_fourth <= n_fourth) block_size = candidate;
    }
    if (block_size == 0) block_size = 1;

    for (size_t query = 1; query < q; ++query) {
        const RectangleQuery current = queries[query];
        size_t position = query;
        while (position > 0 && query_before(&current, &queries[position - 1], block_size)) {
            queries[position] = queries[position - 1];
            --position;
        }
        queries[position] = current;
    }

    if (q == 0) return 0;

    int64_t frequency[8] = {0};
    int64_t sum_squares = 0;
    RectangleQuery current = queries[0];
    for (size_t row = current.top; row <= current.bottom; ++row)
        for (size_t column = current.left; column <= current.right; ++column)
            add_value(matrix[row * n + column], frequency, &sum_squares);

    int64_t answers[MAX_Q];
    answers[current.index] = sum_squares;
    for (size_t query = 1; query < q; ++query) {
        const RectangleQuery target = queries[query];
        while (current.top > target.top) {
            --current.top;
            for (size_t column = current.left; column <= current.right; ++column)
                add_value(matrix[current.top * n + column], frequency, &sum_squares);
        }
        while (current.bottom < target.bottom) {
            ++current.bottom;
            for (size_t column = current.left; column <= current.right; ++column)
                add_value(matrix[current.bottom * n + column], frequency, &sum_squares);
        }
        while (current.left > target.left) {
            --current.left;
            for (size_t row = current.top; row <= current.bottom; ++row)
                add_value(matrix[row * n + current.left], frequency, &sum_squares);
        }
        while (current.right < target.right) {
            ++current.right;
            for (size_t row = current.top; row <= current.bottom; ++row)
                add_value(matrix[row * n + current.right], frequency, &sum_squares);
        }
        while (current.top < target.top) {
            for (size_t column = current.left; column <= current.right; ++column)
                remove_value(matrix[current.top * n + column], frequency, &sum_squares);
            ++current.top;
        }
        while (current.bottom > target.bottom) {
            for (size_t column = current.left; column <= current.right; ++column)
                remove_value(matrix[current.bottom * n + column], frequency, &sum_squares);
            --current.bottom;
        }
        while (current.left < target.left) {
            for (size_t row = current.top; row <= current.bottom; ++row)
                remove_value(matrix[row * n + current.left], frequency, &sum_squares);
            ++current.left;
        }
        while (current.right > target.right) {
            for (size_t row = current.top; row <= current.bottom; ++row)
                remove_value(matrix[row * n + current.right], frequency, &sum_squares);
            --current.right;
        }
        answers[target.index] = sum_squares;
    }

    int64_t result = 0;
    for (size_t query = 0; query < q; ++query)
        result += (int64_t)(query + 1) * answers[query];
    return result;
}
