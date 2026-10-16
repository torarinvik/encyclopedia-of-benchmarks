#include <cstddef>
#include <cstdint>
extern "C" std::int64_t pairwise_iteration(const std::int64_t* v, std::size_t n, std::uint8_t* out, std::size_t cap) noexcept {
    if (!v || n < 1 || n > 129 || v[0] < 0 || v[0] > 128 || n != static_cast<std::size_t>(v[0]) + 1) return -1;
    const auto count = static_cast<std::size_t>(v[0]); const auto bytes = count ? (count - 1) * 16 : 0;
    for (std::size_t i = 0; i < count; ++i) if (v[i + 1] < -1000000 || v[i + 1] > 1000000) return -1;
    if (bytes > cap || (bytes && !out)) return -2;
    std::size_t k = 0;
    for (std::size_t i = 0; i + 1 < count; ++i) for (std::size_t j = i; j <= i + 1; ++j) {
        const auto x = static_cast<std::uint64_t>(v[j + 1]);
        for (std::size_t b = 0; b < 8; ++b) out[k++] = static_cast<std::uint8_t>(x >> (8 * b));
    }
    return static_cast<std::int64_t>(bytes);
}
