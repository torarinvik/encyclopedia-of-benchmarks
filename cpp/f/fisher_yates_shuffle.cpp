#include <cstddef>
#include <cstdint>

extern "C" std::int64_t fisher_yates_shuffle(const std::int64_t* input, std::size_t length,
                                                std::uint8_t* output, std::size_t output_capacity) noexcept {
    constexpr std::size_t max_values = 1024;
    constexpr std::uint64_t modulus = UINT64_C(2147483647);
    if (input == nullptr || length < 1 || length > max_values + 1) return -1;
    const std::int64_t seed = input[0];
    if (seed < 1 || seed >= static_cast<std::int64_t>(modulus)) return -1;
    const std::size_t count = length - 1;
    std::int32_t values[max_values];
    for (std::size_t i = 0; i < count; ++i) {
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
        values[i] = static_cast<std::int32_t>(input[i + 1]);
    }
    const std::size_t byte_count = count * 4;
    if (output_capacity < byte_count || (byte_count != 0 && output == nullptr)) return -2;
    std::uint64_t state = static_cast<std::uint64_t>(seed);
    for (std::size_t remaining = count; remaining >= 2; --remaining) {
        state = (state * UINT64_C(48271)) % modulus;
        const std::size_t other = static_cast<std::size_t>(state % remaining);
        const std::int32_t temporary = values[remaining - 1];
        values[remaining - 1] = values[other];
        values[other] = temporary;
    }
    for (std::size_t i = 0; i < count; ++i) {
        const std::uint32_t bits = static_cast<std::uint32_t>(values[i]);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[i * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(count);
}
