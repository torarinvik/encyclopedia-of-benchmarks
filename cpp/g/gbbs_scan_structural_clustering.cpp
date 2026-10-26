// Clean-room bounded GBBS SCAN profile; see package LICENSE.txt.
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t MaxN = 16;
constexpr std::size_t MaxM = 64;
constexpr std::size_t MaxInput = 2 + 2 * MaxM;
using Graph = std::array<std::array<bool, MaxN>, MaxN>;
using Degrees = std::array<std::size_t, MaxN>;

std::pair<std::uint64_t, std::uint64_t> similarityParts(
        std::size_t u, std::size_t v, const Graph& adjacent, const Degrees& degree) {
    std::size_t shared = 0;
    for (std::size_t w = 0; w < MaxN; ++w)
        if (adjacent[u][w] && adjacent[v][w]) ++shared;
    return {shared + 2, (degree[u] + 1) * (degree[v] + 1)};
}
bool epsilonSimilar(std::uint64_t numerator, std::uint64_t denominatorSq) {
    return 4 * numerator * numerator >= denominatorSq;
}
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t gbbs_scan_structural_clustering(
        const std::int64_t* input, std::size_t length, std::uint8_t* output,
        std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MaxN) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(MaxM)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;
    Graph adjacent{};
    Degrees degree{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= static_cast<std::int64_t>(n)) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
        ++degree[u];
        ++degree[v];
    }
    if (!output || capacity < 8 * n) return -2;

    std::array<bool, MaxN> core{};
    std::array<std::int64_t, MaxN> labels{};
    for (std::size_t u = 0; u < n; ++u) {
        std::size_t similarCount = 0;
        for (std::size_t v = 0; v < n; ++v) if (adjacent[u][v]) {
            const auto [num, den] = similarityParts(u, v, adjacent, degree);
            similarCount += epsilonSimilar(num, den);
        }
        core[u] = similarCount >= 2;
        labels[u] = -1;
    }
    for (std::size_t root = 0; root < n; ++root) {
        if (!core[root] || labels[root] != -1) continue;
        std::array<std::size_t, MaxN> queue{};
        std::size_t head = 0, tail = 0;
        labels[root] = static_cast<std::int64_t>(root);
        queue[tail++] = root;
        while (head < tail) {
            const auto u = queue[head++];
            for (std::size_t v = 0; v < n; ++v) {
                if (!core[v] || labels[v] != -1 || !adjacent[u][v]) continue;
                const auto [num, den] = similarityParts(u, v, adjacent, degree);
                if (epsilonSimilar(num, den)) {
                    labels[v] = static_cast<std::int64_t>(root);
                    queue[tail++] = v;
                }
            }
        }
    }
    for (std::size_t u = 0; u < n; ++u) {
        if (core[u]) continue;
        std::size_t bestCore = MaxN;
        std::uint64_t bestNum = 0, bestDen = 1;
        for (std::size_t v = 0; v < n; ++v) {
            if (!core[v] || !adjacent[u][v]) continue;
            const auto [num, den] = similarityParts(u, v, adjacent, degree);
            if (!epsilonSimilar(num, den)) continue;
            const auto left = num * num * bestDen;
            const auto right = bestNum * bestNum * den;
            if (bestCore == MaxN || left > right || (left == right && v < bestCore)) {
                bestCore = v;
                bestNum = num;
                bestDen = den;
            }
        }
        if (bestCore != MaxN) labels[u] = labels[bestCore];
    }
    for (std::size_t v = 0; v < n; ++v) storeI64LE(output, 8 * v, labels[v]);
    return static_cast<std::int64_t>(8 * n);
}
