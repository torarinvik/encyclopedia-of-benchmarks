// Clean-room bounded GraphAIBench complete-linkage HAC; see package LICENSE.txt.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 8, MaxM = 24, MaxInput = 2 + 3 * MaxM, MaxNodes = 2 * MaxN - 1;
constexpr std::int64_t RootParent = INT64_C(4294967295);
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t graphai_hac_complete_linkage(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) || length != 2 + 3 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::array<int, MaxN>, MaxN> adjacent{};
    std::array<bool, 33> usedWeight{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 3 * edge], v64 = input[3 + 3 * edge], w64 = input[4 + 3 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || w64 < 1 || w64 > 32) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64), w = static_cast<int>(w64);
        if (adjacent[u][v] != 0 || usedWeight[w]) return -1;
        adjacent[u][v] = adjacent[v][u] = w; usedWeight[w] = true;
    }
    std::array<bool, MaxN> reached{}; std::array<std::size_t, MaxN> queue{};
    std::size_t head = 0, tail = 0; reached[0] = true; queue[tail++] = 0;
    while (head < tail) { auto u = queue[head++]; for (std::size_t v = 0; v < n; ++v)
        if (adjacent[u][v] != 0 && !reached[v]) { reached[v] = true; queue[tail++] = v; } }
    for (std::size_t v = 0; v < n; ++v) if (!reached[v]) return -1;
    const auto nodeCount = 2 * n - 1, outputBytes = 16 * nodeCount;
    if (!output || capacity < outputBytes) return -2;

    std::array<bool, MaxN> active{}; std::array<int, MaxN> currentId{};
    std::array<std::int64_t, MaxNodes> parent{}, mergeWeight{};
    parent.fill(RootParent);
    for (std::size_t u = 0; u < n; ++u) { active[u] = true; currentId[u] = static_cast<int>(u); }
    for (std::size_t merge = 0; merge < n - 1; ++merge) {
        int bestU = -1, bestV = -1, bestWeight = 0;
        for (std::size_t u = 0; u < n; ++u) if (active[u])
            for (std::size_t v = u + 1; v < n; ++v)
                if (active[v] && adjacent[u][v] > bestWeight) { bestWeight = adjacent[u][v]; bestU = static_cast<int>(u); bestV = static_cast<int>(v); }
        if (bestU < 0) return -1;
        int degreeU = 0, degreeV = 0;
        for (std::size_t z = 0; z < n; ++z) { degreeU += active[z] && adjacent[bestU][z] != 0; degreeV += active[z] && adjacent[bestV][z] != 0; }
        const int larger = degreeU < degreeV ? bestV : bestU, smaller = larger == bestU ? bestV : bestU;
        const int newId = static_cast<int>(n + merge);
        parent[currentId[bestU]] = parent[currentId[bestV]] = newId;
        mergeWeight[currentId[bestU]] = mergeWeight[currentId[bestV]] = bestWeight;
        std::array<int, MaxN> mergedWeight{};
        for (std::size_t z = 0; z < n; ++z) if (active[z] && static_cast<int>(z) != bestU && static_cast<int>(z) != bestV) {
            const int a = adjacent[bestU][z], b = adjacent[bestV][z];
            if (a || b) mergedWeight[z] = a && b ? std::min(a, b) : (a ? a : b);
        }
        for (std::size_t z = 0; z < n; ++z) { adjacent[bestU][z] = adjacent[z][bestU] = 0; adjacent[bestV][z] = adjacent[z][bestV] = 0; }
        active[smaller] = false;
        for (std::size_t z = 0; z < n; ++z) if (active[z] && static_cast<int>(z) != larger && mergedWeight[z]) adjacent[larger][z] = adjacent[z][larger] = mergedWeight[z];
        currentId[larger] = newId;
    }
    for (std::size_t node = 0; node < nodeCount; ++node) { storeI64LE(output, 16 * node, parent[node]); storeI64LE(output, 16 * node + 8, mergeWeight[node]); }
    return static_cast<std::int64_t>(outputBytes);
}
