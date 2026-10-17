#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MT_N 624u
#define MT_M 397u
#define MAX_SIMULATIONS 100000
#define MAX_SEED UINT64_C(4294967295)
#define MT_MATRIX_A UINT32_C(0x9908B0DF)
#define MT_UPPER_MASK UINT32_C(0x80000000)
#define MT_LOWER_MASK UINT32_C(0x7FFFFFFF)

/* Separate binary64 operations to preserve the contract's multiply/add order. */
static double rounded_multiply(double left, double right)
{
    volatile double value = left * right;
    return value;
}

static double rounded_add(double left, double right)
{
    volatile double value = left + right;
    return value;
}

/* CPython 3.12's Random.seed(int) path for a one-word unsigned seed. */
static void mt_seed(uint32_t state[MT_N], uint32_t seed)
{
    state[0] = UINT32_C(19650218);
    for (size_t index = 1u; index < MT_N; ++index) {
        const uint32_t previous = state[index - 1u];
        state[index] = UINT32_C(1812433253) * (previous ^ (previous >> 30u)) +
                       (uint32_t)index;
    }

    size_t index = 1u;
    size_t key_index = 0u;
    for (size_t remaining = MT_N; remaining > 0u; --remaining) {
        const uint32_t previous = state[index - 1u];
        state[index] = (state[index] ^
                        ((previous ^ (previous >> 30u)) * UINT32_C(1664525))) +
                       seed + (uint32_t)key_index;
        ++index;
        ++key_index;
        if (index >= MT_N) {
            state[0] = state[MT_N - 1u];
            index = 1u;
        }
        if (key_index >= 1u) key_index = 0u;
    }

    for (size_t remaining = MT_N - 1u; remaining > 0u; --remaining) {
        const uint32_t previous = state[index - 1u];
        state[index] = (state[index] ^
                        ((previous ^ (previous >> 30u)) * UINT32_C(1566083941))) -
                       (uint32_t)index;
        ++index;
        if (index >= MT_N) {
            state[0] = state[MT_N - 1u];
            index = 1u;
        }
    }
    state[0] = MT_UPPER_MASK;
}

static void mt_twist(uint32_t state[MT_N])
{
    for (size_t index = 0u; index < MT_N - MT_M; ++index) {
        const uint32_t joined = (state[index] & MT_UPPER_MASK) |
                               (state[index + 1u] & MT_LOWER_MASK);
        state[index] = state[index + MT_M] ^ (joined >> 1u);
        if ((joined & 1u) != 0u) state[index] ^= MT_MATRIX_A;
    }
    for (size_t index = MT_N - MT_M; index < MT_N - 1u; ++index) {
        const uint32_t joined = (state[index] & MT_UPPER_MASK) |
                               (state[index + 1u] & MT_LOWER_MASK);
        state[index] = state[index - (MT_N - MT_M)] ^ (joined >> 1u);
        if ((joined & 1u) != 0u) state[index] ^= MT_MATRIX_A;
    }
    const uint32_t joined = (state[MT_N - 1u] & MT_UPPER_MASK) |
                           (state[0] & MT_LOWER_MASK);
    state[MT_N - 1u] = state[MT_M - 1u] ^ (joined >> 1u);
    if ((joined & 1u) != 0u) state[MT_N - 1u] ^= MT_MATRIX_A;
}

static uint32_t mt_next_uint32(uint32_t state[MT_N], size_t *index)
{
    if (*index >= MT_N) {
        mt_twist(state);
        *index = 0u;
    }

    uint32_t value = state[(*index)++];
    value ^= value >> 11u;
    value ^= (value << 7u) & UINT32_C(0x9D2C5680);
    value ^= (value << 15u) & UINT32_C(0xEFC60000);
    value ^= value >> 18u;
    return value;
}

static double mt_random(uint32_t state[MT_N], size_t *index)
{
    const uint32_t high = mt_next_uint32(state, index) >> 5u;
    const uint32_t low = mt_next_uint32(state, index) >> 6u;
    const double significand = (double)high * 67108864.0 + (double)low;
    return significand * (1.0 / 9007199254740992.0);
}

static int exact_integer_in_range(double value, double minimum, double maximum)
{
    if (!isfinite(value) || value < minimum || value > maximum) return 0;
    return value == (double)(int64_t)value;
}

int64_t pi_monte_carlo_estimation(const double *input, size_t input_length,
                                  double *output, size_t output_capacity)
{
    if (input == NULL || input_length == 0u || input_length > 3u || input_length != 2u)
        return -1;
    if (!exact_integer_in_range(input[0], 1.0, (double)MAX_SIMULATIONS) ||
        !exact_integer_in_range(input[1], 0.0, (double)MAX_SEED)) return -1;

    const size_t simulations = (size_t)input[0];
    const uint32_t seed = (uint32_t)input[1];
    if (output == NULL || output_capacity < 1u) return -2;

    uint32_t state[MT_N];
    mt_seed(state, seed);
    size_t random_index = MT_N;
    size_t hits = 0u;
    for (size_t trial = 0u; trial < simulations; ++trial) {
        const double x = mt_random(state, &random_index);
        const double y = mt_random(state, &random_index);
        const double x_squared = rounded_multiply(x, x);
        const double y_squared = rounded_multiply(y, y);
        if (rounded_add(x_squared, y_squared) <= 1.0) ++hits;
    }

    output[0] = (double)(4u * hits) / (double)simulations;
    return 1;
}
