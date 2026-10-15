/* Portable byte counting sort for printable non-space ASCII characters. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_text_length = 4095;
}

extern "C" std::int64_t counting_sort_string(const std::int64_t* values,
                                               std::size_t length,
                                               std::uint8_t* output,
                                               std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 1 || length > static_cast<std::size_t>(max_text_length + 1)) return -1;
    const std::int64_t count = values[0];
    if (count < 0 || count > max_text_length || length != static_cast<std::size_t>(count) + 1) return -1;

    std::array<std::size_t, 256> frequencies{};
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index) {
        const std::int64_t value = values[index + 1];
        if (value < 33 || value > 126) return -1;
        ++frequencies[static_cast<std::uint8_t>(value)];
    }
    if (output == nullptr || output_capacity < static_cast<std::size_t>(count)) return -2;

    for (std::size_t value = 1; value < frequencies.size(); ++value)
        frequencies[value] += frequencies[value - 1];
    for (std::size_t index = static_cast<std::size_t>(count); index > 0; --index) {
        const auto value = static_cast<std::uint8_t>(values[index]);
        output[--frequencies[value]] = value;
    }
    return count;
}
