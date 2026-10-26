// Clean-room bounded GAPBS Afforest profile; see package LICENSE.txt.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 64, MaxSamples = 64;
constexpr std::size_t MaxInput = 3 + MaxSamples + 2 * MaxM;

void linkComponents(int u, int v, std::array<int, MaxN>& component) noexcept {
    int p1 = component[static_cast<std::size_t>(u)], p2 = component[static_cast<std::size_t>(v)];
    while (p1 != p2) {
        const int high = p1 > p2 ? p1 : p2;
        const int low = p1 + (p2 - high);
        const int parentHigh = component[static_cast<std::size_t>(high)];
        if (parentHigh == low) break;
        if (parentHigh == high) { component[static_cast<std::size_t>(high)] = low; break; }
        p1 = component[static_cast<std::size_t>(component[static_cast<std::size_t>(high)])];
        p2 = component[static_cast<std::size_t>(low)];
    }
}

void compressComponents(std::size_t n, std::array<int, MaxN>& component) noexcept {
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        while (component[vertex] != component[static_cast<std::size_t>(component[vertex])])
            component[vertex] = component[static_cast<std::size_t>(component[vertex])];
}

void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
} // namespace

extern "C" std::int64_t gapbs_afforest_components(const std::int64_t* input, std::size_t length,
                                                    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 4 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1], sampleCount64 = input[2];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 || m64 > static_cast<std::int64_t>(MaxM)
        || sampleCount64 < 1 || sampleCount64 > static_cast<std::int64_t>(MaxSamples)
        || length != 3 + static_cast<std::size_t>(sampleCount64) + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    const auto sampleCount = static_cast<std::size_t>(sampleCount64);
    std::array<std::size_t, MaxSamples> samples{};
    for (std::size_t i = 0; i < sampleCount; ++i) {
        const auto sample = input[3 + i];
        if (sample < 0 || sample >= n64) return -1;
        samples[i] = static_cast<std::size_t>(sample);
    }
    std::array<std::array<bool, MaxN>, MaxN> adjacency{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto pos = 3 + sampleCount + 2 * edge;
        const auto u = input[pos], v = input[pos + 1];
        if (u < 0 || v <= u || v >= n64 || adjacency[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)]) return -1;
        adjacency[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] = true;
        adjacency[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] = true;
    }
    const auto outputBytes = 8 * n;
    if (!output || capacity < outputBytes) return -2;

    std::array<std::array<int, MaxN>, MaxN> neighbors{};
    std::array<int, MaxN> degree{};
    for (std::size_t u = 0; u < n; ++u)
        for (std::size_t v = 0; v < n; ++v)
            if (adjacency[u][v]) neighbors[u][static_cast<std::size_t>(degree[u]++)] = static_cast<int>(v);
    std::array<int, MaxN> component{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) component[vertex] = static_cast<int>(vertex);
    for (int round = 0; round < 2; ++round) {
        for (std::size_t u = 0; u < n; ++u)
            if (degree[u] > round) linkComponents(static_cast<int>(u), neighbors[u][static_cast<std::size_t>(round)], component);
        compressComponents(n, component);
    }
    std::array<int, MaxN> sampleCounts{};
    for (std::size_t i = 0; i < sampleCount; ++i) ++sampleCounts[static_cast<std::size_t>(component[samples[i]])];
    int skipLabel = 0;
    for (std::size_t label = 1; label < n; ++label)
        if (sampleCounts[label] > sampleCounts[static_cast<std::size_t>(skipLabel)]) skipLabel = static_cast<int>(label);
    bool skipIsSafe = true;
    for (std::size_t u = 0; u < n && skipIsSafe; ++u) {
        if (component[u] != skipLabel) continue;
        for (int offset = 2; offset < degree[u]; ++offset)
            if (component[static_cast<std::size_t>(neighbors[u][static_cast<std::size_t>(offset)])] != skipLabel) { skipIsSafe = false; break; }
    }
    for (std::size_t u = 0; u < n; ++u) {
        if (skipIsSafe && component[u] == skipLabel) continue;
        for (int offset = 2; offset < degree[u]; ++offset)
            linkComponents(static_cast<int>(u), neighbors[u][static_cast<std::size_t>(offset)], component);
    }
    compressComponents(n, component);
    for (std::size_t vertex = 0; vertex < n; ++vertex) storeI64LE(output, 8 * vertex, component[vertex]);
    return static_cast<std::int64_t>(outputBytes);
}
