#include <stddef.h>
#include <stdint.h>

static unsigned population_count(uint64_t value) {
    unsigned count = 0;
    while (value != 0) {
        count += (unsigned)(value & 1u);
        value >>= 1;
    }
    return count;
}

static uint64_t bron_kerbosch_search(size_t vertex_count, const uint64_t *adjacency,
                                     uint64_t clique, uint64_t possible, uint64_t excluded) {
    if (possible == 0 && excluded == 0) return UINT64_C(1) << clique;

    int pivot = -1;
    unsigned greatest_degree = 0;
    const uint64_t pivot_choices = possible | excluded;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        if ((pivot_choices & (UINT64_C(1) << vertex)) == 0) continue;
        const unsigned degree = population_count(adjacency[vertex]);
        if (pivot < 0 || degree > greatest_degree) {
            pivot = (int)vertex;
            greatest_degree = degree;
        }
    }

    uint64_t candidates = possible;
    if (pivot >= 0) candidates &= ~adjacency[(size_t)pivot];
    uint64_t result = 0;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        const uint64_t bit = UINT64_C(1) << vertex;
        if ((candidates & bit) == 0) continue;
        result |= bron_kerbosch_search(vertex_count, adjacency, clique | bit,
                                       possible & adjacency[vertex], excluded & adjacency[vertex]);
        possible &= ~bit;
        excluded |= bit;
    }
    return result;
}

int64_t bron_kerbosch(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 7) return -1;
    if (input[0] < 0 || input[0] > 5) return -1;
    const size_t vertex_count = (size_t)input[0];
    if (length != vertex_count + 1) return -1;

    const uint64_t vertex_mask = (UINT64_C(1) << vertex_count) - 1;
    uint64_t adjacency[5] = {0};
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        if (input[vertex + 1] < 0 || ((uint64_t)input[vertex + 1] & ~vertex_mask) != 0) return -1;
        adjacency[vertex] = (uint64_t)input[vertex + 1] & ~(UINT64_C(1) << vertex);
    }
    for (size_t left = 0; left < vertex_count; ++left) {
        for (size_t right = left + 1; right < vertex_count; ++right) {
            if (((adjacency[left] >> right) & 1u) != ((adjacency[right] >> left) & 1u)) return -1;
        }
    }
    return (int64_t)bron_kerbosch_search(vertex_count, adjacency, 0, vertex_mask, 0);
}
