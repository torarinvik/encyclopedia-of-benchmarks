#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 128;
constexpr std::int64_t max_requested_count = 64;
constexpr std::int64_t checksum_base = 300000;
}

extern "C" std::int64_t substring(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_text_length + 2) return -1;
    const auto text_length = length - 2;
    const auto start = values[0];
    const auto requested = values[1];
    if (start < 0 || static_cast<std::uint64_t>(start) > text_length || requested < 0 || requested > max_requested_count) return -1;
    for (std::size_t i = 0; i < text_length; ++i) if (values[i + 2] < 1 || values[i + 2] > 127) return -1;
    const auto remaining = text_length - static_cast<std::size_t>(start);
    auto count = static_cast<std::size_t>(requested);
    if (count == 0 && remaining > 0) count = 1;
    if (count > remaining) count = remaining;
    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < count; ++i) checksum += static_cast<std::int64_t>(i + 1) * values[static_cast<std::size_t>(start) + i + 2];
    return static_cast<std::int64_t>(count) * checksum_base + checksum;
}
