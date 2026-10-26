/* Clean-room bounded GBBS approximate set-cover profile; see package MIT notice. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxSets = 8, MaxElements = 8, MaxInput = 10;
void storeI64LE(std::uint8_t* out, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { out[offset + i] = static_cast<std::uint8_t>(bits); bits >>= 8; }
}
}

extern "C" std::int64_t gbbs_approximate_set_cover(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto ns64 = input[0];
    if (ns64 < 1 || ns64 > 8) return -1;
    const auto ns = static_cast<std::size_t>(ns64), ne = ns;
    if (length != 1 + ns) return -1;
    const auto valid = static_cast<std::uint16_t>((1u << ne) - 1u);
    std::array<std::uint16_t, MaxSets> sets{};
    for (std::size_t s = 0; s < ns; ++s) {
        if (input[1 + s] < 0 || (static_cast<std::uint64_t>(input[1 + s]) & ~static_cast<std::uint64_t>(valid))) return -1;
        sets[s] = static_cast<std::uint16_t>(input[1 + s]);
        if (sets[s] & (1u << s)) return -1;
    }
    for (std::size_t u = 0; u < ns; ++u)
        for (std::size_t v = 0; v < ns; ++v)
            if (((sets[u] >> v) & 1u) != ((sets[v] >> u) & 1u)) return -1;
    if (!output || capacity < 16) return -2;
    auto uncovered = valid;
    std::uint16_t selected = 0;
    std::array<std::size_t, MaxSets> bucket{};
    for (std::size_t s = 0; s < ns; ++s) {
        auto bits = sets[s];
        while (bits) { bits = static_cast<std::uint16_t>(bits & (bits - 1)); ++bucket[s]; }
    }
    std::size_t round = 0;
    while (uncovered) {
        std::array<std::size_t, MaxSets> degree{};
        std::size_t top = 0;
        for (std::size_t s = 0; s < ns; ++s) if (bucket[s] > top) top = bucket[s];
        if (!top) break;
        std::array<bool, MaxSets> eligible{};
        std::size_t eligibleCount = 0;
        for (std::size_t s = 0; s < ns; ++s) if (bucket[s] == top) {
            auto bits = static_cast<std::uint16_t>(sets[s] & uncovered);
            while (bits) { bits = static_cast<std::uint16_t>(bits & (bits - 1)); ++degree[s]; }
            bucket[s] = degree[s];
            eligible[s] = degree[s] >= top;
            eligibleCount += eligible[s] ? 1U : 0U;
        }
        std::array<std::size_t, MaxSets> priority{};
        std::size_t priorityCount = 0;
        for (std::size_t r = 0; r < ns; ++r) {
            const auto s = (round + r) % ns;
            if (eligible[s]) priority[priorityCount++] = s;
        }
        std::array<std::size_t, MaxSets> wins{};
        for (std::size_t e = 0; e < ne; ++e) {
            const auto bit = static_cast<std::uint16_t>(1u << e);
            if (!(uncovered & bit)) continue;
            for (std::size_t r = 0; r < priorityCount; ++r) {
                const auto s = priority[r];
                if (sets[s] & bit) { ++wins[s]; break; }
            }
        }
        std::uint16_t roundCover = 0;
        for (std::size_t s = 0; s < ns; ++s) if (eligible[s] && wins[s] >= top) roundCover |= static_cast<std::uint16_t>(1u << s);
        if (!roundCover && eligibleCount) return -1;
        selected |= roundCover;
        std::uint16_t covered = 0;
        for (std::size_t s = 0; s < ns; ++s) if (roundCover & (1u << s)) covered |= sets[s];
        uncovered = static_cast<std::uint16_t>(uncovered & static_cast<std::uint16_t>(~covered));
        for (std::size_t s = 0; s < ns; ++s) if (roundCover & (1u << s)) bucket[s] = 0;
        ++round;
    }
    storeI64LE(output, 0, selected);
    storeI64LE(output, 8, uncovered);
    return 16;
}
