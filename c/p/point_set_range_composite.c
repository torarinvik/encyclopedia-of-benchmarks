#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_N INT64_C(16)
#define MAX_OPERATIONS INT64_C(32)
#define MAX_INPUT_LENGTH ((size_t)162)
#define TREE_CAPACITY ((size_t)64)

typedef struct {
    int64_t a;
    int64_t b;
} AffineMap;

static AffineMap identity_map(void)
{
    return (AffineMap){.a = 1, .b = 0};
}

/* Apply left first, then right: the result is right composed with left. */
static AffineMap compose(AffineMap left, AffineMap right)
{
    return (AffineMap){
        .a = (right.a * left.a) % MODULUS,
        .b = (right.a * left.b + right.b) % MODULUS,
    };
}

int64_t point_set_range_composite(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = values[0];
    const int64_t q_value = values[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_OPERATIONS) return -1;
    const size_t n = (size_t)n_value;
    const size_t q = (size_t)q_value;
    if (length != 2 + 2 * n + 4 * q) return -1;

    for (size_t i = 0; i < n; ++i) {
        const int64_t a = values[2 + 2 * i];
        const int64_t b = values[3 + 2 * i];
        if (a < 0 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
    }

    size_t base = 1;
    while (base < n) base *= 2;
    AffineMap tree[TREE_CAPACITY];
    for (size_t i = 0; i < TREE_CAPACITY; ++i) tree[i] = identity_map();
    for (size_t i = 0; i < n; ++i) {
        tree[base + i] = (AffineMap){values[2 + 2 * i], values[3 + 2 * i]};
    }
    for (size_t node = base; node > 1; --node) {
        const size_t parent = node - 1;
        tree[parent] = compose(tree[2 * parent], tree[2 * parent + 1]);
    }

    int64_t checksum = 0;
    int64_t query_number = 0;
    size_t cursor = 2 + 2 * n;
    for (size_t operation = 0; operation < q; ++operation) {
        const int64_t opcode = values[cursor];
        const int64_t first = values[cursor + 1];
        const int64_t second = values[cursor + 2];
        const int64_t third = values[cursor + 3];
        cursor += 4;
        if (opcode == 0) {
            if (first < 0 || first >= n_value || second < 0 || second >= MODULUS ||
                third < 0 || third >= MODULUS) return -1;
            size_t node = base + (size_t)first;
            tree[node] = (AffineMap){second, third};
            while (node > 1) {
                node /= 2;
                tree[node] = compose(tree[2 * node], tree[2 * node + 1]);
            }
        } else if (opcode == 1) {
            if (first < 0 || first > second || second > n_value ||
                third < 0 || third >= MODULUS) return -1;
            size_t left_index = base + (size_t)first;
            size_t right_index = base + (size_t)second;
            AffineMap left = identity_map();
            AffineMap right = identity_map();
            while (left_index < right_index) {
                if (left_index & 1U) left = compose(left, tree[left_index++]);
                if (right_index & 1U) right = compose(tree[--right_index], right);
                left_index /= 2;
                right_index /= 2;
            }
            const AffineMap range = compose(left, right);
            const int64_t answer = (range.a * third + range.b) % MODULUS;
            ++query_number;
            checksum = (checksum + query_number * answer) % MODULUS;
        } else {
            return -1;
        }
    }
    return cursor == length ? checksum : -1;
}
