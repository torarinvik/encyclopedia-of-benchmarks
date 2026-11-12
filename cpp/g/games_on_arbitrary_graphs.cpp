// Reverse-edge retrograde classification for a bounded directed game graph.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_v = 16;
constexpr std::size_t max_e = 32;
constexpr std::size_t max_input = 66;
constexpr std::size_t max_output = 17;
}

extern "C" std::int64_t games_on_arbitrary_graphs(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity)
{
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const std::int64_t nv = input[0], me = input[1];
    if (nv < 0 || nv > static_cast<std::int64_t>(max_v) ||
        me < 0 || me > static_cast<std::int64_t>(max_e)) return -1;
    const auto n = static_cast<std::size_t>(nv);
    const auto m = static_cast<std::size_t>(me);
    if (length != 2 + 2 * m) return -1;

    std::array<std::uint16_t, max_v> outmask{};
    std::array<int, max_v> head{};
    std::array<int, max_e> edge_source{}, edge_next{};
    std::array<int, max_v> remaining{}, status{};
    std::array<int, max_v> queue{};
    std::array<std::uint8_t, max_output> staged{};
    for (std::size_t v = 0; v < n; ++v) head[v] = -1;

    std::size_t unique_edges = 0;
    for (std::size_t i = 0; i < m; ++i) {
        const std::int64_t sv = input[2 + 2 * i], tv = input[3 + 2 * i];
        if (sv < 0 || sv >= nv || tv < 0 || tv >= nv) return -1;
        const auto s = static_cast<std::size_t>(sv), t = static_cast<std::size_t>(tv);
        const auto bit = static_cast<std::uint16_t>(1u << t);
        if ((outmask[s] & bit) == 0) {
            outmask[s] = static_cast<std::uint16_t>(outmask[s] | bit);
            edge_source[unique_edges] = static_cast<int>(s);
            edge_next[unique_edges] = head[t];
            head[t] = static_cast<int>(unique_edges++);
            ++remaining[s];
        }
    }

    std::size_t first = 0, count = 0;
    for (std::size_t v = 0; v < n; ++v) {
        if (remaining[v] == 0) { status[v] = 2; queue[count++] = static_cast<int>(v); }
    }
    while (first < count) {
        const int resolved = queue[first++];
        for (int edge = head[static_cast<std::size_t>(resolved)]; edge != -1; edge = edge_next[static_cast<std::size_t>(edge)]) {
            const int predecessor = edge_source[static_cast<std::size_t>(edge)];
            if (status[static_cast<std::size_t>(predecessor)] != 0) continue;
            if (status[static_cast<std::size_t>(resolved)] == 2) {
                status[static_cast<std::size_t>(predecessor)] = 1;
                queue[count++] = predecessor;
            } else if (--remaining[static_cast<std::size_t>(predecessor)] == 0) {
                status[static_cast<std::size_t>(predecessor)] = 2;
                queue[count++] = predecessor;
            }
        }
    }

    staged[0] = static_cast<std::uint8_t>(n);
    for (std::size_t v = 0; v < n; ++v) staged[v + 1] = static_cast<std::uint8_t>(status[v]);
    const std::size_t needed = n + 1;
    if (output == nullptr || capacity < needed) return -2;
    for (std::size_t i = 0; i < needed; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(needed);
}
