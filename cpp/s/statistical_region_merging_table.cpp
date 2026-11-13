#include <array>
#include <cstddef>
#include <cstdint>

namespace {
std::size_t root(std::array<std::size_t, 36>& parent, std::size_t x) noexcept {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}
}

extern "C" std::int64_t statistical_region_merging_table(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 4 || length > 74 || input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6) return -1;
    const auto width = static_cast<std::size_t>(input[1]);
    const auto n = static_cast<std::size_t>(input[0]) * width;
    if (length != 2 + 2*n) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[2+i] < 0 || input[2+i] > 65535 || input[2+n+i] < 0 || input[2+n+i] > 255) return -1;
    std::array<std::size_t, 36> parent{}, sizes{}, minimum{};
    std::array<std::int64_t, 36> sums{};
    for (std::size_t i = 0; i < n; ++i) { parent[i] = minimum[i] = i; sizes[i] = 1; sums[i] = input[2+n+i]; }
    for (int diff = 0; diff < 256; ++diff) for (std::size_t p = 0; p < n; ++p) {
        std::array<std::size_t, 2> neighbors{};
        std::size_t count = 0;
        if (p % width + 1 < width) neighbors[count++] = p + 1;
        if (p + width < n) neighbors[count++] = p + width;
        for (std::size_t k = 0; k < count; ++k) {
            const auto q = neighbors[k];
            auto d = input[2+n+p] - input[2+n+q];
            if (d < 0) d = -d;
            if (d != diff) continue;
            auto a = root(parent, p), b = root(parent, q);
            if (a == b) continue;
            const auto na = static_cast<std::int64_t>(sizes[a]), nb = static_cast<std::int64_t>(sizes[b]);
            const auto delta = sums[a]*nb - sums[b]*na;
            const auto bound = input[1+sizes[a]] + input[1+sizes[b]];
            if (delta*delta > bound*na*na*nb*nb) continue;
            if (sizes[a] < sizes[b]) { const auto t = a; a = b; b = t; }
            parent[b] = a; sizes[a] += sizes[b]; sums[a] += sums[b];
            if (minimum[b] < minimum[a]) minimum[a] = minimum[b];
        }
    }
    if (!output || capacity < n) return -2;
    for (std::size_t i = 0; i < n; ++i) output[i] = static_cast<std::uint8_t>(minimum[root(parent, i)]);
    return static_cast<std::int64_t>(n);
}
