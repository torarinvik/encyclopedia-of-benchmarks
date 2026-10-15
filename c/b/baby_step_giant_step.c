/* Bounded baby-step giant-step discrete logarithm. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define TABLE_SIZE ((size_t)65536)
#define TABLE_MASK (TABLE_SIZE - 1)
#define MAX_MODULUS UINT64_C(1000000007)

static uint64_t gcd_u64(uint64_t left, uint64_t right)
{
    while (right != 0) {
        const uint64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static uint64_t ceil_sqrt_u64(uint64_t value)
{
    uint64_t low = 1, high = 31624;
    while (low < high) {
        const uint64_t middle = low + (high - low) / 2;
        if (middle * middle >= value) high = middle;
        else low = middle + 1;
    }
    return low;
}

static void insert_baby(uint64_t *keys, uint32_t *encoded_steps,
                        uint64_t key, uint32_t step)
{
    size_t slot = (size_t)(key & TABLE_MASK);
    while (encoded_steps[slot] != 0 && keys[slot] != key) slot = (slot + 1) & TABLE_MASK;
    keys[slot] = key;
    encoded_steps[slot] = step + 1;
}

static int64_t find_baby(const uint64_t *keys, const uint32_t *encoded_steps, uint64_t key)
{
    size_t slot = (size_t)(key & TABLE_MASK);
    while (encoded_steps[slot] != 0) {
        if (keys[slot] == key) return (int64_t)encoded_steps[slot] - 1;
        slot = (slot + 1) & TABLE_MASK;
    }
    return -1;
}

int64_t baby_step_giant_step(const int64_t *values, size_t length)
{
    if (length != 3 || values == NULL) return -1;
    if (values[0] < 0 || values[1] < 0 || values[2] < 1 ||
        (uint64_t)values[2] > MAX_MODULUS || values[0] >= values[2] || values[1] >= values[2]) return -1;
    const uint64_t a = (uint64_t)values[0];
    const uint64_t b = (uint64_t)values[1];
    const uint64_t modulus = (uint64_t)values[2];
    if (gcd_u64(a, modulus) != 1) return -1;

    const uint64_t m = ceil_sqrt_u64(modulus);
    uint64_t *keys = calloc(TABLE_SIZE, sizeof(*keys));
    uint32_t *encoded_steps = calloc(TABLE_SIZE, sizeof(*encoded_steps));
    if (keys == NULL || encoded_steps == NULL) {
        free(keys);
        free(encoded_steps);
        return -1;
    }
    uint64_t step = 1;
    for (uint64_t index = 0; index < m; ++index) {
        insert_baby(keys, encoded_steps, (step * b) % modulus, (uint32_t)index);
        step = (step * a) % modulus;
    }
    const uint64_t giant_step = step;
    for (uint64_t index = m; index <= modulus; index += m) {
        const int64_t baby_index = find_baby(keys, encoded_steps, step);
        if (baby_index >= 0) {
            const int64_t result = (int64_t)index - baby_index;
            free(keys);
            free(encoded_steps);
            return result;
        }
        step = (step * giant_step) % modulus;
    }
    free(keys);
    free(encoded_steps);
    return -1;
}
