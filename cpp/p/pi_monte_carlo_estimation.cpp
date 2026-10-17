#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t mt_n = 624;
constexpr std::size_t mt_m = 397;
constexpr std::size_t max_parseable_input_length = 3;
constexpr std::int64_t max_simulations = 100000;
constexpr std::uint64_t max_seed = UINT64_C(4294967295);
constexpr std::uint32_t mt_matrix_a = UINT32_C(0x9908B0DF);
constexpr std::uint32_t mt_upper_mask = UINT32_C(0x80000000);
constexpr std::uint32_t mt_lower_mask = UINT32_C(0x7FFFFFFF);

double rounded_multiply(double left, double right)
{
    volatile double value = left * right;
    return value;
}

double rounded_add(double left, double right)
{
    volatile double value = left + right;
    return value;
}

void mt_seed(std::uint32_t state[mt_n], std::uint32_t seed)
{
    state[0] = UINT32_C(19650218);
    for (std::size_t index = 1; index < mt_n; ++index) {
        const std::uint32_t previous = state[index - 1];
        state[index] = UINT32_C(1812433253) * (previous ^ (previous >> 30)) +
                       static_cast<std::uint32_t>(index);
    }

    std::size_t index = 1;
    std::size_t key_index = 0;
    for (std::size_t remaining = mt_n; remaining > 0; --remaining) {
        const std::uint32_t previous = state[index - 1];
        state[index] = (state[index] ^
                        ((previous ^ (previous >> 30)) * UINT32_C(1664525))) +
                       seed + static_cast<std::uint32_t>(key_index);
        ++index;
        ++key_index;
        if (index >= mt_n) {
            state[0] = state[mt_n - 1];
            index = 1;
        }
        if (key_index >= 1) key_index = 0;
    }

    for (std::size_t remaining = mt_n - 1; remaining > 0; --remaining) {
        const std::uint32_t previous = state[index - 1];
        state[index] = (state[index] ^
                        ((previous ^ (previous >> 30)) * UINT32_C(1566083941))) -
                       static_cast<std::uint32_t>(index);
        ++index;
        if (index >= mt_n) {
            state[0] = state[mt_n - 1];
            index = 1;
        }
    }
    state[0] = mt_upper_mask;
}

void mt_twist(std::uint32_t state[mt_n])
{
    for (std::size_t index = 0; index < mt_n - mt_m; ++index) {
        const std::uint32_t joined = (state[index] & mt_upper_mask) |
                                     (state[index + 1] & mt_lower_mask);
        state[index] = state[index + mt_m] ^ (joined >> 1);
        if ((joined & 1u) != 0u) state[index] ^= mt_matrix_a;
    }
    for (std::size_t index = mt_n - mt_m; index < mt_n - 1; ++index) {
        const std::uint32_t joined = (state[index] & mt_upper_mask) |
                                     (state[index + 1] & mt_lower_mask);
        state[index] = state[index - (mt_n - mt_m)] ^ (joined >> 1);
        if ((joined & 1u) != 0u) state[index] ^= mt_matrix_a;
    }
    const std::uint32_t joined = (state[mt_n - 1] & mt_upper_mask) |
                                 (state[0] & mt_lower_mask);
    state[mt_n - 1] = state[mt_m - 1] ^ (joined >> 1);
    if ((joined & 1u) != 0u) state[mt_n - 1] ^= mt_matrix_a;
}

std::uint32_t mt_next_uint32(std::uint32_t state[mt_n], std::size_t& index)
{
    if (index >= mt_n) {
        mt_twist(state);
        index = 0;
    }

    std::uint32_t value = state[index++];
    value ^= value >> 11;
    value ^= (value << 7) & UINT32_C(0x9D2C5680);
    value ^= (value << 15) & UINT32_C(0xEFC60000);
    value ^= value >> 18;
    return value;
}

double mt_random(std::uint32_t state[mt_n], std::size_t& index)
{
    const std::uint32_t high = mt_next_uint32(state, index) >> 5;
    const std::uint32_t low = mt_next_uint32(state, index) >> 6;
    const double significand = static_cast<double>(high) * 67108864.0 +
                               static_cast<double>(low);
    return significand * (1.0 / 9007199254740992.0);
}

bool exact_integer_in_range(double value, double minimum, double maximum)
{
    if (!std::isfinite(value) || value < minimum || value > maximum) return false;
    return value == static_cast<double>(static_cast<std::int64_t>(value));
}
} // namespace

extern "C" std::int64_t pi_monte_carlo_estimation(const double* input,
                                                    std::size_t input_length,
                                                    double* output,
                                                    std::size_t output_capacity)
{
    if (input == nullptr || input_length == 0 || input_length > max_parseable_input_length ||
        input_length != 2) return -1;
    if (!exact_integer_in_range(input[0], 1.0, static_cast<double>(max_simulations)) ||
        !exact_integer_in_range(input[1], 0.0, static_cast<double>(max_seed))) return -1;

    const std::size_t simulations = static_cast<std::size_t>(input[0]);
    const std::uint32_t seed = static_cast<std::uint32_t>(input[1]);
    if (output == nullptr || output_capacity < 1) return -2;

    std::uint32_t state[mt_n];
    mt_seed(state, seed);
    std::size_t random_index = mt_n;
    std::size_t hits = 0;
    for (std::size_t trial = 0; trial < simulations; ++trial) {
        const double x = mt_random(state, random_index);
        const double y = mt_random(state, random_index);
        const double x_squared = rounded_multiply(x, x);
        const double y_squared = rounded_multiply(y, y);
        if (rounded_add(x_squared, y_squared) <= 1.0) ++hits;
    }

    output[0] = static_cast<double>(4 * hits) / static_cast<double>(simulations);
    return 1;
}
