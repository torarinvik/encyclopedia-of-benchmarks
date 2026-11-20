// Uncompiled minimum tree path-partition draft.
#include <array>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t tree_minimum_path_partition(const std::int64_t* input, std::size_t length) {
    if (!input || length < 1 || length > 65) return -1;
    const auto nv = input[0];
    if (nv < 1 || nv > 64 || length != static_cast<std::size_t>(nv)) return -1;
    const auto n = static_cast<std::size_t>(nv);
    for (std::size_t v = 1; v < n; ++v)
        if (input[v] < 0 || input[v] >= static_cast<std::int64_t>(v)) return -1;
    std::array<std::int64_t,64> base{}, first{}, second{};
    for (std::size_t v = n; v-- > 1;) {
        const auto p = static_cast<std::size_t>(input[v]);
        const auto best = base[v] + first[v] + second[v];
        const auto gain = 1 + base[v] + first[v] - best;
        base[p] += best;
        if (gain > first[p]) { second[p] = first[p]; first[p] = gain; }
        else if (gain > second[p]) second[p] = gain;
    }
    return nv - base[0] - first[0] - second[0];
}
