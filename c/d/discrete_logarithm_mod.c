/* Extended baby-step giant-step for a bounded modular discrete logarithm. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define TABLE_SIZE ((size_t)65536)
#define TABLE_MASK (TABLE_SIZE - 1)
#define MAX_MODULUS UINT64_C(1000000000)

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
    uint64_t low = 1, high = 31623;
    while (low < high) {
        const uint64_t middle = low + (high - low) / 2;
        if (middle * middle >= value) high = middle;
        else low = middle + 1;
    }
    return low;
}

static uint64_t pow_mod(uint64_t base, uint64_t exponent, uint64_t modulus)
{
    uint64_t result = 1 % modulus;
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

static int64_t inverse_mod(uint64_t value, uint64_t modulus)
{
    int64_t old_r = (int64_t)value, r = (int64_t)modulus;
    int64_t old_t = 1, t = 0;
    while (r != 0) {
        const int64_t quotient = old_r / r;
        const int64_t next_r = old_r - quotient * r;
        const int64_t next_t = old_t - quotient * t;
        old_r = r;
        r = next_r;
        old_t = t;
        t = next_t;
    }
    if (old_r != 1) return -1;
    old_t %= (int64_t)modulus;
    if (old_t < 0) old_t += (int64_t)modulus;
    return old_t;
}

static void insert_baby(uint64_t *keys, uint32_t *encoded_steps, uint64_t key, uint32_t step)
{
    size_t slot = (size_t)(key & TABLE_MASK);
    while (encoded_steps[slot] != 0) {
        if (keys[slot] == key) return; /* Keep the least exponent for this residue. */
        slot = (slot + 1) & TABLE_MASK;
    }
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

static int64_t coprime_log(uint64_t x, uint64_t y, uint64_t modulus)
{
    if (y == 1 % modulus) return 0;
    const uint64_t width = ceil_sqrt_u64(modulus);
    uint64_t *keys = calloc(TABLE_SIZE, sizeof(*keys));
    uint32_t *encoded_steps = calloc(TABLE_SIZE, sizeof(*encoded_steps));
    if (keys == NULL || encoded_steps == NULL) {
        free(keys);
        free(encoded_steps);
        return -1;
    }

    uint64_t residue = 1 % modulus;
    for (uint64_t step = 0; step < width; ++step) {
        insert_baby(keys, encoded_steps, residue, (uint32_t)step);
        residue = (residue * x) % modulus;
    }
    const int64_t inverse = inverse_mod(x, modulus);
    const uint64_t giant_factor = pow_mod((uint64_t)inverse, width, modulus);
    uint64_t giant = y;
    for (uint64_t block = 0; block * width <= modulus; ++block) {
        const int64_t baby = find_baby(keys, encoded_steps, giant);
        if (baby >= 0) {
            const uint64_t answer = block * width + (uint64_t)baby;
            free(keys);
            free(encoded_steps);
            return answer <= modulus ? (int64_t)answer : -1;
        }
        giant = (giant * giant_factor) % modulus;
    }
    free(keys);
    free(encoded_steps);
    return -1;
}

static int64_t extended_log(uint64_t x, uint64_t y, uint64_t modulus)
{
    if (modulus == 1) return 0;
    uint64_t accumulator = 1;
    uint64_t added = 0;
    while (gcd_u64(x, modulus) > 1) {
        if (y == accumulator) return (int64_t)added;
        const uint64_t divisor = gcd_u64(x, modulus);
        if (y % divisor != 0) return -1;
        y /= divisor;
        modulus /= divisor;
        accumulator = (accumulator * (x / divisor)) % modulus;
        ++added;
        if (modulus == 1) return (int64_t)added;
    }
    const int64_t inverse = inverse_mod(accumulator, modulus);
    if (inverse < 0) return -1;
    const uint64_t reduced_target = (y * (uint64_t)inverse) % modulus;
    const int64_t remaining = coprime_log(x % modulus, reduced_target, modulus);
    return remaining < 0 ? -1 : (int64_t)added + remaining;
}

int64_t discrete_logarithm_mod(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return -1;
    if (values[0] < 0 || values[1] < 0 || values[2] < 1 ||
        (uint64_t)values[2] > MAX_MODULUS || values[0] >= values[2] || values[1] >= values[2]) return -1;
    return extended_log((uint64_t)values[0], (uint64_t)values[1], (uint64_t)values[2]);
}
