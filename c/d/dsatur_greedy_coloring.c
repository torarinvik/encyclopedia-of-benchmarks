/* Brélaz saturation-degree greedy coloring on a bounded simple graph. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 12
#define MAX_EDGES 66
#define MAX_VALID_LENGTH 134
#define MAX_PARSEABLE_LENGTH 135

static int bit_count(uint16_t value)
{
    int count = 0;
    while (value != 0) {
        count += value & 1u;
        value >>= 1;
    }
    return count;
}

int64_t dsatur_greedy_coloring(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;

    const int64_t raw_vertices = input[0];
    const int64_t raw_edges = input[1];
    if (raw_vertices < 1 || raw_vertices > MAX_VERTICES ||
        raw_edges < 0 || raw_edges > MAX_EDGES) return -1;

    const size_t vertex_count = (size_t)raw_vertices;
    const size_t edge_count = (size_t)raw_edges;
    if (length != 2 + 2 * edge_count || length > MAX_VALID_LENGTH) return -1;

    uint16_t adjacency[MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t raw_first = input[2 + 2 * edge];
        const int64_t raw_second = input[3 + 2 * edge];
        if (raw_first < 0 || raw_second < 0 || raw_first >= raw_second ||
            raw_second >= raw_vertices) return -1;
        const size_t first = (size_t)raw_first;
        const size_t second = (size_t)raw_second;
        const uint16_t first_bit = (uint16_t)(1u << second);
        if ((adjacency[first] & first_bit) != 0) return -1;
        adjacency[first] |= first_bit;
        adjacency[second] |= (uint16_t)(1u << first);
    }

    int colors[MAX_VERTICES];
    uint16_t saturation_colors[MAX_VERTICES] = {0};
    int residual_degree[MAX_VERTICES] = {0};
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        colors[vertex] = -1;
        residual_degree[vertex] = bit_count(adjacency[vertex]);
    }

    int color_count = 0;
    for (size_t round = 0; round < vertex_count; ++round) {
        int selected = -1;
        for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
            if (colors[vertex] >= 0) continue;
            if (selected < 0) {
                selected = (int)vertex;
                continue;
            }
            const int saturation = bit_count(saturation_colors[vertex]);
            const int selected_saturation = bit_count(saturation_colors[selected]);
            if (saturation > selected_saturation ||
                (saturation == selected_saturation &&
                 (residual_degree[vertex] > residual_degree[selected] ||
                  (residual_degree[vertex] == residual_degree[selected] &&
                   vertex < (size_t)selected)))) {
                selected = (int)vertex;
            }
        }

        uint16_t used = saturation_colors[selected];
        int color = 0;
        while ((used & (uint16_t)(1u << color)) != 0) ++color;
        colors[selected] = color;
        if (color + 1 > color_count) color_count = color + 1;

        for (size_t neighbor = 0; neighbor < vertex_count; ++neighbor) {
            if ((adjacency[selected] & (uint16_t)(1u << neighbor)) == 0 ||
                colors[neighbor] >= 0) continue;
            --residual_degree[neighbor];
            saturation_colors[neighbor] |= (uint16_t)(1u << color);
        }
    }

    uint64_t packed = (uint64_t)color_count << 48;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex)
        packed |= (uint64_t)colors[vertex] << (4 * vertex);
    return (int64_t)packed;
}
