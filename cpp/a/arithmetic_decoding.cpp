/* Decode an exact arithmetic-coded lower-bound numerator. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t arithmetic_decoding(const std::int64_t *input,
                                              std::size_t length,
                                              std::uint8_t *output,
                                              std::size_t capacity) noexcept
{
    if (input == nullptr || length < 5) return -1;
    const auto count = input[0];
    const auto alphabet_size = input[1];
    if (count < 1 || count > 12 || alphabet_size < 1 || alphabet_size > count
        || length != static_cast<std::size_t>(3 + 2 * alphabet_size)) return -1;

    std::int64_t denominator = 1;
    for (std::int64_t index = 0; index < count; ++index) denominator *= count;
    const auto code = input[2];
    if (code < 0 || code >= denominator) return -1;

    std::array<std::int64_t, 12> symbols{};
    std::array<std::int64_t, 13> cumulative{};
    std::int64_t total = 0;
    for (std::int64_t index = 0; index < alphabet_size; ++index) {
        const auto symbol = input[3 + 2 * index];
        const auto frequency = input[4 + 2 * index];
        if (symbol < 0 || symbol > 255 || frequency < 1 || frequency > count
            || (index > 0 && symbol <= symbols[static_cast<std::size_t>(index - 1)])) return -1;
        symbols[static_cast<std::size_t>(index)] = symbol;
        total += frequency;
        cumulative[static_cast<std::size_t>(index + 1)] = total;
    }
    if (total != count) return -1;
    if (capacity < static_cast<std::size_t>(count) || output == nullptr) return -2;

    std::int64_t low = 0;
    std::int64_t high = 1;
    std::int64_t scale = denominator / count;
    for (std::int64_t step = 0; step < count; ++step) {
        const auto range = high - low;
        const auto base = low * count;
        bool found = false;
        for (std::int64_t index = 0; index < alphabet_size; ++index) {
            const auto offset = static_cast<std::size_t>(index);
            const auto symbol_low = base + range * cumulative[offset];
            const auto symbol_high = base + range * cumulative[offset + 1];
            if (code >= symbol_low * scale && code < symbol_high * scale) {
                output[static_cast<std::size_t>(step)] = static_cast<std::uint8_t>(symbols[offset]);
                low = symbol_low;
                high = symbol_high;
                found = true;
                break;
            }
        }
        if (!found) return -1;
        if (step + 1 < count) scale /= count;
    }
    return count;
}
