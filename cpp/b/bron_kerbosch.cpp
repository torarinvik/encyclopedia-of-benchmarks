#include <cstddef>
#include <cstdint>

namespace {
unsigned population_count(std::uint64_t value) noexcept {
    unsigned count = 0;
    while (value != 0) {
        count += static_cast<unsigned>(value & 1u);
        value >>= 1;
    }
    return count;
}

std::uint64_t bron_kerbosch_search(std::size_t vertex_count, const std::uint64_t *adjacency,
                                   std::uint64_t clique, std::uint64_t possible,
                                   std::uint64_t excluded) noexcept {
    if (possible == 0 && excluded == 0) return std::uint64_t{1} << clique;

    int pivot = -1;
    unsigned greatest_degree = 0;
    const auto pivot_choices = possible | excluded;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        if ((pivot_choices & (std::uint64_t{1} << vertex)) == 0) continue;
        const auto degree = population_count(adjacency[vertex]);
        if (pivot < 0 || degree > greatest_degree) {
            pivot = static_cast<int>(vertex);
            greatest_degree = degree;
        }
    }

    auto candidates = possible;
    if (pivot >= 0) candidates &= ~adjacency[static_cast<std::size_t>(pivot)];
    std::uint64_t result = 0;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        const auto bit = std::uint64_t{1} << vertex;
        if ((candidates & bit) == 0) continue;
        result |= bron_kerbosch_search(vertex_count, adjacency, clique | bit,
                                       possible & adjacency[vertex], excluded & adjacency[vertex]);
        possible &= ~bit;
        excluded |= bit;
    }
    return result;
}
}

extern "C" std::int64_t bron_kerbosch(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 7) return -1;
    if (input[0] < 0 || input[0] > 5) return -1;
    const auto vertex_count = static_cast<std::size_t>(input[0]);
    if (length != vertex_count + 1) return -1;

    const auto vertex_mask = (std::uint64_t{1} << vertex_count) - 1;
    std::uint64_t adjacency[5] = {};
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        if (input[vertex + 1] < 0 || (static_cast<std::uint64_t>(input[vertex + 1]) & ~vertex_mask) != 0) return -1;
        adjacency[vertex] = static_cast<std::uint64_t>(input[vertex + 1]) & ~(std::uint64_t{1} << vertex);
    }
    for (std::size_t left = 0; left < vertex_count; ++left) {
        for (std::size_t right = left + 1; right < vertex_count; ++right) {
            if (((adjacency[left] >> right) & 1u) != ((adjacency[right] >> left) & 1u)) return -1;
        }
    }
    return static_cast<std::int64_t>(bron_kerbosch_search(vertex_count, adjacency, 0, vertex_mask, 0));
}
