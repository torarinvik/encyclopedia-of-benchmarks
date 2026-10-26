// Clean-room bounded GBBS label-propagation profile; see package LICENSE.txt.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16;
constexpr std::size_t MaxM = 64;
constexpr std::size_t MaxInput = 2 + 2 * MaxM;
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t gbbs_label_propagation_clustering(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
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
    const auto outputBytes = 8 * n;
    if (!output || capacity < outputBytes) return -2;

    std::array<std::int64_t, MaxN> labels{};
    for (std::size_t v = 0; v < n; ++v) labels[v] = static_cast<std::int64_t>(v);
    for (std::size_t u = 0; u < n; ++u) {
        std::array<std::size_t, MaxN> frequency{};
        std::size_t degree = 0;
        for (std::size_t v = 0; v < n; ++v) if (adjacent[u][v]) {
            ++frequency[static_cast<std::size_t>(labels[v])];
            ++degree;
        }
        if (degree == 0) continue;
        std::size_t bestLabel = 0, bestFrequency = 0;
        for (std::size_t label = 0; label < n; ++label) {
            if (frequency[label] > bestFrequency ||
                (frequency[label] == bestFrequency && frequency[label] != 0 && label > bestLabel)) {
                bestLabel = label;
                bestFrequency = frequency[label];
            }
        }
        labels[u] = static_cast<std::int64_t>(bestLabel);
    }
    for (std::size_t v = 0; v < n; ++v) storeI64LE(output, 8 * v, labels[v]);
    return static_cast<std::int64_t>(outputBytes);
}
