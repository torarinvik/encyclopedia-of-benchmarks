#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t state_size = 55;
constexpr std::size_t short_lag = 24;
constexpr std::size_t warmup_values = 165;
constexpr std::int32_t modulus = 1'000'000'000;

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t subtractive_prng_bentley_seeded_sequence(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length != 2) return -1;
    const auto seed = input[0];
    const auto count = input[1];
    if (seed < 0 || seed >= modulus || count < 0 || count > 64) return -1;
    const auto n = static_cast<std::size_t>(count);
    const auto required = n * 8;
    if (capacity < required || (required != 0 && output == nullptr)) return -2;
    if (n == 0) return 0;

    std::int32_t seed_state[state_size];
    std::int32_t ring[state_size];
    seed_state[0] = static_cast<std::int32_t>(seed);
    seed_state[1] = 1;
    for (std::size_t i = 2; i < state_size; ++i) {
        auto value = seed_state[i - 2] - seed_state[i - 1];
        if (value < 0) value += modulus;
        seed_state[i] = value;
    }
    for (std::size_t i = 0; i < state_size; ++i)
        ring[i] = seed_state[(34 * (i + 1)) % state_size];

    std::size_t write_index = 0;
    std::size_t lag_index = state_size - short_lag;
    for (std::size_t step = 0; step < warmup_values + n; ++step) {
        auto value = ring[write_index] - ring[lag_index];
        if (value < 0) value += modulus;
        ring[write_index] = value;
        if (step >= warmup_values)
            put_i64_le(output, (step - warmup_values) * 8, value);
        write_index = (write_index + 1) % state_size;
        lag_index = (lag_index + 1) % state_size;
    }
    return static_cast<std::int64_t>(required);
}
