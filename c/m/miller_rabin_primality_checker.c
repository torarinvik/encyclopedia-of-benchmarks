#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_VALUES 4
#define MAX_N INT64_C(2147483647)

static uint64_t next_word(uint64_t *state) {
    *state += UINT64_C(0x9E3779B97F4A7C15);
    uint64_t z = *state;
    z = (z ^ (z >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)) * UINT64_C(0x94D049BB133111EB);
    return z ^ (z >> 31);
}

static int64_t mod_power(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

static int passes_witness(int64_t n, int64_t a, int64_t d, int64_t powers_of_two) {
    int64_t x = mod_power(a, d, n);
    if (x == 1 || x == n - 1) return 1;
    for (int64_t round = 1; round < powers_of_two; ++round) {
        x = (x * x) % n;
        if (x == n - 1) return 1;
    }
    return 0;
}

int64_t miller_rabin_primality_checker(const int64_t *values, size_t length) {
    if (values == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    const int64_t n = values[0], rounds = values[1], seed = values[2];
    if (length != 3 || n < 5 || n > MAX_N || (n & 1) == 0 ||
        rounds < 1 || rounds > 64 || seed < 0 || seed > MAX_N) return -1;

    uint64_t state = (uint64_t)seed;
    const uint64_t span = (uint64_t)(n - 4);
    const uint64_t threshold = (UINT64_C(0) - span) % span;
    uint64_t word;
    do { word = next_word(&state); } while (word < threshold);
    const int64_t a = 2 + (int64_t)(word % span);

    int64_t d = n - 1, powers_of_two = 0;
    while ((d & 1) == 0) { d >>= 1; ++powers_of_two; }
    for (int64_t i = 0; i < rounds; ++i)
        if (!passes_witness(n, a, d, powers_of_two)) return 0;
    return 1;
}
