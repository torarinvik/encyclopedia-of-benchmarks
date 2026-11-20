/* Two-stack aggregate deque with midpoint rebuilding. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_OPERATIONS = 32, MAX_INPUT_LENGTH = 162, MODULUS = 97 };

typedef struct { int64_t v[4]; } Matrix;

static Matrix identity(void) { return (Matrix){{1, 0, 0, 1}}; }

static Matrix multiply(Matrix x, Matrix y)
{
    Matrix z;
    z.v[0] = (x.v[0] * y.v[0] + x.v[1] * y.v[2]) % MODULUS;
    z.v[1] = (x.v[0] * y.v[1] + x.v[1] * y.v[3]) % MODULUS;
    z.v[2] = (x.v[2] * y.v[0] + x.v[3] * y.v[2]) % MODULUS;
    z.v[3] = (x.v[2] * y.v[1] + x.v[3] * y.v[3]) % MODULUS;
    return z;
}

static int64_t pack(Matrix matrix)
{
    return matrix.v[0] + MODULUS * matrix.v[1] +
           MODULUS * MODULUS * matrix.v[2] +
           MODULUS * MODULUS * MODULUS * matrix.v[3];
}

static void push_front(Matrix *items, Matrix *aggregates, size_t *count, Matrix value)
{
    items[*count] = value;
    aggregates[*count] = *count == 0 ? value : multiply(value, aggregates[*count - 1]);
    ++*count;
}

static void push_back(Matrix *items, Matrix *aggregates, size_t *count, Matrix value)
{
    items[*count] = value;
    aggregates[*count] = *count == 0 ? value : multiply(aggregates[*count - 1], value);
    ++*count;
}

static void rebalance(Matrix *front, Matrix *front_aggregate, size_t *front_count,
                      Matrix *back, Matrix *back_aggregate, size_t *back_count,
                      Matrix *temporary)
{
    const int front_was_empty = *front_count == 0;
    const size_t total = *front_count + *back_count;
    for (size_t i = 0; i < *front_count; ++i) temporary[i] = front[*front_count - 1 - i];
    for (size_t i = 0; i < *back_count; ++i) temporary[*front_count + i] = back[i];
    const size_t front_size = total / 2 + (front_was_empty ? total % 2 : 0);
    *front_count = 0;
    *back_count = 0;
    for (size_t i = front_size; i > 0; --i)
        push_front(front, front_aggregate, front_count, temporary[i - 1]);
    for (size_t i = front_size; i < total; ++i)
        push_back(back, back_aggregate, back_count, temporary[i]);
}

int64_t slide_window_aggregation_deque(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;

    Matrix front[ MAX_OPERATIONS ], front_aggregate[ MAX_OPERATIONS ];
    Matrix back[ MAX_OPERATIONS ], back_aggregate[ MAX_OPERATIONS ];
    Matrix temporary[ MAX_OPERATIONS ];
    size_t front_count = 0, back_count = 0, cursor = 1, query_ordinal = 0;
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const int64_t opcode = input[cursor++];
        if (opcode == 0 || opcode == 1) {
            if (cursor + 4 > length) return -1;
            Matrix value;
            for (size_t i = 0; i < 4; ++i) {
                if (input[cursor + i] < 0 || input[cursor + i] >= MODULUS) return -1;
                value.v[i] = input[cursor + i];
            }
            cursor += 4;
            if (opcode == 0) push_front(front, front_aggregate, &front_count, value);
            else push_back(back, back_aggregate, &back_count, value);
        } else if (opcode == 2 || opcode == 3) {
            if (front_count + back_count == 0) return -1;
            if (opcode == 2) {
                if (front_count == 0)
                    rebalance(front, front_aggregate, &front_count, back, back_aggregate, &back_count, temporary);
                --front_count;
            } else {
                if (back_count == 0)
                    rebalance(front, front_aggregate, &front_count, back, back_aggregate, &back_count, temporary);
                --back_count;
            }
        } else if (opcode == 4) {
            const Matrix left = front_count == 0 ? identity() : front_aggregate[front_count - 1];
            const Matrix right = back_count == 0 ? identity() : back_aggregate[back_count - 1];
            ++query_ordinal;
            checksum += (int64_t)query_ordinal * (pack(multiply(left, right)) + 1);
        } else return -1;
    }
    return cursor == length ? checksum : -1;
}
