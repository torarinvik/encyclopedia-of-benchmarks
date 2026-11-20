module zielonka_parity_game_solver;

const int ZPG_MAX_VERTICES = 8;
const int ZPG_MAX_EDGES = 20;
const usz ZPG_MAX_PARSEABLE_INPUT = 59;

fn long zpg_attractor(long active, int player, long target, int* owners,
                      long* adjacency, int n) {
    long attracted = target;
    while (true) {
        long additions = 0;
        for (int vertex = 0; vertex < n; vertex++) {
            long bit = 1L << vertex;
            if ((active & bit) == 0 || (attracted & bit) != 0) continue;
            long successors = adjacency[vertex] & active;
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

fn long zpg_solve(long active, int* owners, int* priorities, long* adjacency, int n) {
    if (active == 0) return 0;
    int lowest = 6;
    for (int vertex = 0; vertex < n; vertex++)
        if ((active & (1L << vertex)) != 0 && priorities[vertex] < lowest)
            lowest = priorities[vertex];
    int player = lowest & 1;
    long target = 0;
    for (int vertex = 0; vertex < n; vertex++)
        if ((active & (1L << vertex)) != 0 && priorities[vertex] == lowest)
            target |= 1L << vertex;

    long first = zpg_attractor(active, player, target, owners, adjacency, n);
    long remainder = active & ~first;
    long even_first = zpg_solve(remainder, owners, priorities, adjacency, n);
    long odd_first = remainder & ~even_first;
    long opponent_region = player == 1 ? even_first : odd_first;
    if (opponent_region == 0) return even_first | (player == 0 ? first : 0);

    long second = zpg_attractor(active, 1 - player, opponent_region, owners, adjacency, n);
    long even_second = zpg_solve(active & ~second, owners, priorities, adjacency, n);
    return even_second | (player == 1 ? second : 0);
}

fn long zielonka_parity_game_solver(long* input, usz length) @export("zielonka_parity_game_solver") {
    if (input == null || length < 6 || length > ZPG_MAX_PARSEABLE_INPUT) return -1;
    long vertex_raw = input[0], edge_raw = input[1];
    if (vertex_raw < 1 || vertex_raw > ZPG_MAX_VERTICES ||
        edge_raw < vertex_raw || edge_raw > ZPG_MAX_EDGES) return -1;
    int n = (int)vertex_raw, edge_count = (int)edge_raw;
    if (length != (usz)(2 + 2 * n + 2 * edge_count)) return -1;

    int[8] owners = {0};
    int[8] priorities = {0};
    long[8] adjacency = {0};
    int[8] outdegree = {0};
    usz cursor = 2;
    for (int vertex = 0; vertex < n; vertex++) {
        long owner = input[cursor++], priority = input[cursor++];
        if (owner < 0 || owner > 1 || priority < 0 || priority > 5) return -1;
        owners[vertex] = (int)owner;
        priorities[vertex] = (int)priority;
    }
    for (int edge = 0; edge < edge_count; edge++) {
        long source_raw = input[cursor++], destination_raw = input[cursor++];
        if (source_raw < 0 || source_raw >= n || destination_raw < 0 || destination_raw >= n)
            return -1;
        int source = (int)source_raw, destination = (int)destination_raw;
        long bit = 1L << destination;
        if ((adjacency[source] & bit) != 0) return -1;
        adjacency[source] |= bit;
        outdegree[source]++;
    }
    for (int vertex = 0; vertex < n; vertex++) if (outdegree[vertex] == 0) return -1;
    return zpg_solve((1L << n) - 1, owners, priorities, adjacency, n);
}
