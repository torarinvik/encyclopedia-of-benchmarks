#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t is_contains_unique_chars(const std::int64_t* values, std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < 0 || values[i] > 127) return -1;

    std::uint64_t seen[2] = {0, 0};
    for (std::size_t i = 0; i < length; ++i) {
        const auto value = static_cast<std::uint64_t>(values[i]);
        const std::size_t word = static_cast<std::size_t>(value / 64);
        const std::uint64_t mask = std::uint64_t{1} << (value % 64);
        if ((seen[word] & mask) != 0) return 0;
        seen[word] |= mask;
    }
    return 1;
}
