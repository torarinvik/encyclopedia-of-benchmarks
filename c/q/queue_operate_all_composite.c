#include <stddef.h>
#include <stdint.h>

enum { MAX_OPERATIONS = 64, MODULUS = 998244353 };
#define MAX_INPUT_LENGTH (1 + 3 * MAX_OPERATIONS)

typedef struct {
    int64_t a;
    int64_t b;
} Affine;

static Affine compose(Affine first, Affine second)
{
    Affine result;
    result.a = (second.a * first.a) % MODULUS;
    result.b = (second.a * first.b + second.b) % MODULUS;
    return result;
}

static Affine identity(void)
{
    const Affine value = {1, 0};
    return value;
}

static void transfer(Affine *back_functions, Affine *front_aggregates,
                     size_t *back_size, size_t *front_size)
{
    while (*back_size > 0) {
        const Affine function = back_functions[--(*back_size)];
        front_aggregates[*front_size] = *front_size == 0
            ? function : compose(function, front_aggregates[*front_size - 1]);
        ++(*front_size);
    }
}

int64_t queue_operate_all_composite(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation_value = values[0];
    if (operation_value < 0 || operation_value > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_value;

    Affine back_functions[MAX_OPERATIONS];
    Affine back_aggregates[MAX_OPERATIONS];
    Affine front_aggregates[MAX_OPERATIONS];
    size_t back_size = 0;
    size_t front_size = 0;
    size_t position = 1;
    int64_t checksum = 0;
    int64_t query_number = 0;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (position >= length) return -1;
        const int64_t opcode = values[position++];
        if (opcode == 0) {
            if (length - position < 2) return -1;
            const int64_t a = values[position++];
            const int64_t b = values[position++];
            if (a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
            const Affine function = {a, b};
            back_functions[back_size] = function;
            back_aggregates[back_size] = back_size == 0
                ? function : compose(back_aggregates[back_size - 1], function);
            ++back_size;
        } else if (opcode == 1) {
            if (front_size == 0)
                transfer(back_functions, front_aggregates, &back_size, &front_size);
            if (front_size == 0) return -1;
            --front_size;
        } else if (opcode == 2) {
            if (position >= length) return -1;
            const int64_t x = values[position++];
            if (x < 0 || x >= MODULUS) return -1;
            Affine aggregate = identity();
            if (front_size > 0) aggregate = front_aggregates[front_size - 1];
            if (back_size > 0)
                aggregate = front_size > 0
                    ? compose(aggregate, back_aggregates[back_size - 1])
                    : back_aggregates[back_size - 1];
            const int64_t answer = (aggregate.a * x + aggregate.b) % MODULUS;
            ++query_number;
            checksum += query_number * (answer + 1);
        } else {
            return -1;
        }
    }
    return position == length ? checksum : -1;
}
