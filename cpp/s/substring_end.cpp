#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_text_length = 128; constexpr std::int64_t checksum_base = 1100000; }

extern "C" std::int64_t substring_end(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 1 || length > max_text_length + 1) return -1;
    const auto text_length = length - 1;
    const auto start = values[0];
    if (start < 0 || static_cast<std::uint64_t>(start) > text_length) return -1;
    for (std::size_t i = 0; i < text_length; ++i) if (values[i + 1] < 1 || values[i + 1] > 127) return -1;
    const auto count = text_length - static_cast<std::size_t>(start);
    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < count; ++i) checksum += static_cast<std::int64_t>(i + 1) * values[static_cast<std::size_t>(start) + i + 1];
    return static_cast<std::int64_t>(count) * checksum_base + checksum;
}
