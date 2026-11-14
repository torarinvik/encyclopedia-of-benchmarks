// Uncompiled exact-length shortest-walk draft.
#include <array>
#include <cstddef>
#include <cstdint>
#include <algorithm>

extern "C" std::int64_t fixed_length_walk_minplus(const std::int64_t* input, std::size_t length) {
    constexpr std::int64_t inf = 1000000000000000LL;
    if (!input || length < 4 || length > 261) return -100000002;
    const auto nv = input[0], source = input[2], target = input[3];
    auto k = input[1];
    if (nv < 1 || nv > 16 || k < 0 || k > 1000000 || source < 0 || source >= nv ||
        target < 0 || target >= nv || length != 4 + static_cast<std::size_t>(nv*nv)) return -100000002;
    const auto n = static_cast<std::size_t>(nv);
    std::array<std::array<std::int64_t,16>,16> matrix{};
    std::array<std::int64_t,16> distance{};
    distance.fill(inf); distance[static_cast<std::size_t>(source)] = 0;
    for (std::size_t i=0; i<n; ++i) for (std::size_t j=0; j<n; ++j) {
        auto weight = input[4+i*n+j];
        if (weight != 1000000 && (weight < -100 || weight > 100)) return -100000002;
        matrix[i][j] = weight == 1000000 ? inf : weight;
    }
    while (k) {
        if (k & 1) {
            std::array<std::int64_t,16> next; next.fill(inf);
            for (std::size_t i=0; i<n; ++i) for (std::size_t j=0; j<n; ++j)
                if (distance[i] != inf && matrix[i][j] != inf)
                    next[j] = std::min(next[j], distance[i] + matrix[i][j]);
            distance = next;
        }
        k >>= 1;
        if (k) {
            std::array<std::array<std::int64_t,16>,16> next{};
            for (auto& row : next) row.fill(inf);
            for (std::size_t i=0; i<n; ++i) for (std::size_t p=0; p<n; ++p)
                for (std::size_t j=0; j<n; ++j)
                    if (matrix[i][p] != inf && matrix[p][j] != inf)
                        next[i][j] = std::min(next[i][j], matrix[i][p] + matrix[p][j]);
            matrix = next;
        }
    }
    auto result = distance[static_cast<std::size_t>(target)];
    return result == inf ? -100000001 : result;
}
