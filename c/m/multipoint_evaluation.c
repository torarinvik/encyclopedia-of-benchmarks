#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 8, LEAF_BASE = 8, NODE_CAPACITY = 16, COEFFICIENT_CAPACITY = 9, MAX_INPUT = 18 };
static const int64_t MODULUS = INT64_C(998244353);

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static size_t trim(int64_t *polynomial, size_t length)
{
    while (length > 1 && polynomial[length - 1] == 0) --length;
    return length;
}

static size_t multiply(const int64_t *left, size_t left_length,
                       const int64_t *right, size_t right_length,
                       int64_t *product)
{
    const size_t length = left_length + right_length - 1;
    for (size_t i = 0; i < length; ++i) product[i] = 0;
    for (size_t i = 0; i < left_length; ++i)
        for (size_t j = 0; j < right_length; ++j)
            product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
    return length;
}

static size_t remainder(const int64_t *dividend, size_t dividend_length,
                        const int64_t *divisor, size_t divisor_length,
                        int64_t *result)
{
    if (divisor_length == 1 && divisor[0] == 1) {
        result[0] = 0;
        return 1;
    }
    for (size_t i = 0; i < dividend_length; ++i) result[i] = dividend[i];
    size_t length = trim(result, dividend_length);
    while (length >= divisor_length) {
        const size_t shift = length - divisor_length;
        const int64_t factor = result[length - 1];
        for (size_t degree = 0; degree < divisor_length; ++degree) {
            const size_t slot = shift + degree;
            result[slot] = (result[slot] - factor * divisor[degree]) % MODULUS;
            if (result[slot] < 0) result[slot] += MODULUS;
        }
        length = trim(result, length);
    }
    return length;
}

int64_t multipoint_evaluation(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M) return -1;
    const size_t n = (size_t)input[0];
    const size_t m = (size_t)input[1];
    if (length != 2 + n + m) return -1;
    for (size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= MODULUS) return -1;
    if (input[1 + n] == 0) return -1;

    const size_t bytes = 8 * m;
    if (output == NULL || capacity < bytes) return -2;
    int64_t products[NODE_CAPACITY][COEFFICIENT_CAPACITY] = {{0}};
    int64_t remainders[NODE_CAPACITY][COEFFICIENT_CAPACITY] = {{0}};
    size_t product_lengths[NODE_CAPACITY] = {0};
    size_t remainder_lengths[NODE_CAPACITY] = {0};
    size_t starts[NODE_CAPACITY] = {0};
    size_t spans[NODE_CAPACITY] = {0};
    for (size_t node = 1; node < NODE_CAPACITY; ++node) {
        products[node][0] = 1;
        product_lengths[node] = 1;
    }
    for (size_t i = 0; i < m; ++i) {
        const size_t leaf = LEAF_BASE + i;
        products[leaf][0] = input[2 + n + i] == 0 ? 0 : MODULUS - input[2 + n + i];
        products[leaf][1] = 1;
        product_lengths[leaf] = 2;
    }
    for (size_t node = LEAF_BASE - 1; node > 0; --node)
        product_lengths[node] = multiply(products[2 * node], product_lengths[2 * node],
                                         products[2 * node + 1], product_lengths[2 * node + 1],
                                         products[node]);

    starts[1] = 0;
    spans[1] = LEAF_BASE;
    for (size_t node = 1; node < LEAF_BASE; ++node) {
        spans[2 * node] = spans[node] / 2;
        spans[2 * node + 1] = spans[node] / 2;
        starts[2 * node] = starts[node];
        starts[2 * node + 1] = starts[node] + spans[node] / 2;
    }
    remainder_lengths[1] = remainder(input + 2, n, products[1], product_lengths[1], remainders[1]);
    for (size_t node = 1; node < LEAF_BASE; ++node) {
        for (size_t side = 0; side < 2; ++side) {
            const size_t child = 2 * node + side;
            if (starts[child] < m)
                remainder_lengths[child] = remainder(remainders[node], remainder_lengths[node],
                    products[child], product_lengths[child], remainders[child]);
        }
    }
    for (size_t i = 0; i < m; ++i) store_le(output, 8 * i, remainders[LEAF_BASE + i][0]);
    return (int64_t)bytes;
}
