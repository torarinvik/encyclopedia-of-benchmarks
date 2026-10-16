#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_vertices = 16;

int bit_count(std::uint64_t value)
{
    int count = 0;
    while (value != 0) { value &= value - 1; ++count; }
    return count;
}
}

extern "C" std::int64_t greedy_min_vertex_cover(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > max_vertices + 1) return -1;
    const auto count_value = values[0];
    if (count_value < 1 || count_value > max_vertices || length != static_cast<std::size_t>(count_value) + 1) return -1;
    const int count = static_cast<int>(count_value);
    const std::uint64_t limit = (std::uint64_t{1} << count) - 1;
    std::uint64_t neighbors[max_vertices]{};
    for (int vertex = 0; vertex < count; ++vertex) {
        const auto mask_value = values[vertex + 1];
        if (mask_value < 0 || static_cast<std::uint64_t>(mask_value) > limit) return -1;
        const auto mask = static_cast<std::uint64_t>(mask_value);
        if ((mask & (std::uint64_t{1} << vertex)) != 0) return -1;
        neighbors[vertex] = mask;
    }
    for (int vertex = 0; vertex < count; ++vertex)
        for (int other = vertex + 1; other < count; ++other)
            if (((neighbors[vertex] >> other) & 1) != ((neighbors[other] >> vertex) & 1)) return -1;

    std::uint64_t chosen = 0;
    for (;;) {
        int best_vertex = -1, best_degree = 0;
        for (int vertex = 0; vertex < count; ++vertex) {
            const int degree = bit_count(neighbors[vertex]);
            if (degree > best_degree) { best_vertex = vertex; best_degree = degree; }
        }
        if (best_vertex < 0) return static_cast<std::int64_t>(chosen);
        const auto bit = std::uint64_t{1} << best_vertex;
        chosen |= bit;
        for (int vertex = 0; vertex < count; ++vertex) neighbors[vertex] &= ~bit;
        neighbors[best_vertex] = 0;
    }
}
