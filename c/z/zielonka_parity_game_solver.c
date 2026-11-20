#include <stddef.h>
#include <stdint.h>

#define ZPG_MAX_VERTICES 8
#define ZPG_MAX_EDGES 20
#define ZPG_MAX_PARSEABLE_INPUT 59

static uint32_t zpg_attractor(uint32_t active, int player, uint32_t target,
                              const int owners[ZPG_MAX_VERTICES],
                              const uint32_t adjacency[ZPG_MAX_VERTICES], int n) {
    uint32_t attracted = target;
    for (;;) {
        uint32_t additions = 0;
        for (int vertex = 0; vertex < n; ++vertex) {
            const uint32_t bit = UINT32_C(1) << vertex;
            if ((active & bit) == 0 || (attracted & bit) != 0) continue;
            const uint32_t successors = adjacency[vertex] & active;
            if (owners[vertex] == player) {
                if ((successors & attracted) != 0) additions |= bit;
            } else if (successors != 0 && (successors & ~attracted) == 0) {
                additions |= bit;
            }
        }
        if (additions == 0) return attracted;
        attracted |= additions;
    }
}

static uint32_t zpg_solve(uint32_t active, const int owners[ZPG_MAX_VERTICES],
                          const int priorities[ZPG_MAX_VERTICES],
                          const uint32_t adjacency[ZPG_MAX_VERTICES], int n) {
    if (active == 0) return 0;
    int lowest = 6;
    for (int vertex = 0; vertex < n; ++vertex)
        if ((active & (UINT32_C(1) << vertex)) != 0 && priorities[vertex] < lowest)
            lowest = priorities[vertex];
    const int player = lowest & 1;
    uint32_t target = 0;
    for (int vertex = 0; vertex < n; ++vertex)
        if ((active & (UINT32_C(1) << vertex)) != 0 && priorities[vertex] == lowest)
            target |= UINT32_C(1) << vertex;

    const uint32_t first = zpg_attractor(active, player, target, owners, adjacency, n);
    const uint32_t remainder = active & ~first;
    const uint32_t even_first = zpg_solve(remainder, owners, priorities, adjacency, n);
    const uint32_t odd_first = remainder & ~even_first;
    const uint32_t opponent_region = player == 1 ? even_first : odd_first;
    if (opponent_region == 0) return even_first | (player == 0 ? first : 0);

    const uint32_t second = zpg_attractor(active, 1 - player, opponent_region,
                                          owners, adjacency, n);
    const uint32_t even_second = zpg_solve(active & ~second, owners, priorities, adjacency, n);
    return even_second | (player == 1 ? second : 0);
}

int64_t zielonka_parity_game_solver(const int64_t *input, size_t length) {
    if (input == NULL || length < 6 || length > ZPG_MAX_PARSEABLE_INPUT) return -1;
    const int64_t vertex_raw = input[0], edge_raw = input[1];
    if (vertex_raw < 1 || vertex_raw > ZPG_MAX_VERTICES ||
        edge_raw < vertex_raw || edge_raw > ZPG_MAX_EDGES) return -1;
    const int n = (int)vertex_raw, edge_count = (int)edge_raw;
    if (length != (size_t)(2 + 2 * n + 2 * edge_count)) return -1;

    int owners[ZPG_MAX_VERTICES] = {0};
    int priorities[ZPG_MAX_VERTICES] = {0};
    uint32_t adjacency[ZPG_MAX_VERTICES] = {0};
    int outdegree[ZPG_MAX_VERTICES] = {0};
    size_t cursor = 2;
    for (int vertex = 0; vertex < n; ++vertex) {
        const int64_t owner = input[cursor++], priority = input[cursor++];
        if (owner < 0 || owner > 1 || priority < 0 || priority > 5) return -1;
        owners[vertex] = (int)owner;
        priorities[vertex] = (int)priority;
    }
    for (int edge = 0; edge < edge_count; ++edge) {
        const int64_t source_raw = input[cursor++], destination_raw = input[cursor++];
        if (source_raw < 0 || source_raw >= n || destination_raw < 0 || destination_raw >= n)
            return -1;
        const int source = (int)source_raw, destination = (int)destination_raw;
        const uint32_t bit = UINT32_C(1) << destination;
        if ((adjacency[source] & bit) != 0) return -1;
        adjacency[source] |= bit;
        ++outdegree[source];
    }
    for (int vertex = 0; vertex < n; ++vertex)
        if (outdegree[vertex] == 0) return -1;
    return (int64_t)zpg_solve((UINT32_C(1) << n) - 1, owners, priorities, adjacency, n);
}
