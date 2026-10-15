#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t naive_shuffler(const std::int64_t *input, std::size_t length,
                                        std::uint8_t *output, std::size_t output_capacity) {
    constexpr std::size_t max_items = 256;
    constexpr std::int64_t modulus = 2147483647;
    constexpr std::int64_t period = modulus - 1;
    if (input == nullptr || length < 2 || length > max_items + 2) return -1;
    if (input[0] < 0 || input[0] >= period || input[1] < 0 || input[1] > static_cast<std::int64_t>(max_items)) return -1;
    const std::size_t count = static_cast<std::size_t>(input[1]);
    if (length != count + 2) return -1;

    std::array<std::uint8_t, max_items> items{};
    for (std::size_t index = 0; index < count; ++index) {
        if (input[index + 2] < 0 || input[index + 2] > 255) return -1;
        items[index] = static_cast<std::uint8_t>(input[index + 2]);
    }
    if (output_capacity < count || (count > 0 && output == nullptr)) return -2;

    std::int64_t state = input[0] + 1;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t bound = static_cast<std::int64_t>(count);
        const std::int64_t limit = period - period % bound;
        std::int64_t sample;
        do {
            state = (state * 48271) % modulus;
            sample = state - 1;
        } while (sample >= limit);
        const std::size_t other = static_cast<std::size_t>(sample % bound);
        const std::uint8_t temporary = items[index];
        items[index] = items[other];
        items[other] = temporary;
    }
    for (std::size_t index = 0; index < count; ++index) output[index] = items[index];
    return static_cast<std::int64_t>(count);
}
