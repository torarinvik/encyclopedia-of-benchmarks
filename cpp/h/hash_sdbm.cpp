/* Hash ASCII byte arrays with the pinned 64-bit SDBM recurrence. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxBytes = 64;
std::int64_t signed_bits(std::uint64_t value) noexcept {
    if (value <= static_cast<std::uint64_t>(INT64_MAX)) return static_cast<std::int64_t>(value);
    return INT64_MIN + static_cast<std::int64_t>(value - (UINT64_C(1) << 63));
}
}

extern "C" std::int64_t hash_sdbm(const std::int64_t *input,
                                   std::size_t length) noexcept {
    if (length == 0 || length > kMaxBytes || input == nullptr) return -1;
    std::uint64_t hash = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto byte = input[index];
        if (byte < 1 || byte > 127) return -1;
        const auto value = static_cast<std::uint64_t>(byte);
        hash = value + (hash << 6) + (hash << 16) - hash;
    }
    return signed_bits(hash);
}
