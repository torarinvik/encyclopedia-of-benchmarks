// Clean-room bounded GBBS five-cycle profile; see package LICENSE.txt.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16;
constexpr std::size_t MaxM = 64;
constexpr std::size_t MaxInput = 2 + 2 * MaxM;
void storeI64LE(std::uint8_t* output, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t gbbs_five_cycle_count(const std::int64_t* input,
                                               std::size_t length,
                                               std::uint8_t* output,
                                               std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MaxN) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(MaxM)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;
    std::array<std::array<bool, MaxN>, MaxN> adjacent{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= static_cast<std::int64_t>(n)) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
    }
    if (!output || capacity < 8) return -2;

    std::int64_t count = 0;
    for (std::size_t start = 0; start < n; ++start) {
        for (std::size_t first = start + 1; first < n; ++first) {
            for (std::size_t second = start + 1; second < n; ++second) {
                if (second == first) continue;
                for (std::size_t third = start + 1; third < n; ++third) {
                    if (third == first || third == second) continue;
                    for (std::size_t last = first + 1; last < n; ++last) {
                        if (last == second || last == third) continue;
                        if (adjacent[start][first] && adjacent[first][second] &&
                            adjacent[second][third] && adjacent[third][last] &&
                            adjacent[last][start]) ++count;
                    }
                }
            }
        }
    }
    storeI64LE(output, count);
    return 8;
}
