#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 12, MaxM = 16, MaxInput = 18;
void storeI64LE(std::uint8_t* out, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t min_sum_set_cover_greedy(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 3 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 1 ||
        m64 > static_cast<std::int64_t>(MaxM) || length != 2 + static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::uint64_t masks[MaxM]{};
    for (std::size_t set = 0; set < m; ++set) {
        const auto mask = input[2 + set];
        if (mask <= 0 || static_cast<std::uint64_t>(mask) >= (UINT64_C(1) << n)) return -1;
        masks[set] = static_cast<std::uint64_t>(mask);
    }
    const auto outputBytes = 8 * (n + 1);
    if (!output || capacity < outputBytes) return -2;
    bool covered[MaxM]{}, used[MaxN]{};
    std::int64_t order[MaxN]{}, totalTime = 0;
    for (std::size_t slot = 1; slot <= n; ++slot) {
        std::size_t chosen = 0;
        int bestCount = -1;
        for (std::size_t element = 0; element < n; ++element) {
            if (used[element]) continue;
            int count = 0;
            for (std::size_t set = 0; set < m; ++set)
                if (!covered[set] && (masks[set] & (UINT64_C(1) << element))) ++count;
            if (count > bestCount) { bestCount = count; chosen = element; }
        }
        used[chosen] = true;
        order[slot - 1] = static_cast<std::int64_t>(chosen);
        for (std::size_t set = 0; set < m; ++set) {
            if (!covered[set] && (masks[set] & (UINT64_C(1) << chosen))) {
                covered[set] = true;
                totalTime += static_cast<std::int64_t>(slot);
            }
        }
    }
    storeI64LE(output, 0, totalTime);
    for (std::size_t i = 0; i < n; ++i) storeI64LE(output, 8 * (i + 1), order[i]);
    return static_cast<std::int64_t>(outputBytes);
}
