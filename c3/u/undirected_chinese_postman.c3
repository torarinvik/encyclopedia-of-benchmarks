module undirected_chinese_postman;

const int MAX_N = 8;
const int MAX_M = 12;
const long INF = 1000000000;

fn long undirected_chinese_postman(long* input, usz length) @export("undirected_chinese_postman") {
    if (input == null || length < 2) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M) return -1;
    int n = (int)input[0], m = (int)input[1];
    if (length != (usz)(2 + 3 * m)) return -1;
    if (n == 1) return m == 0 ? 0 : -1;
    if (m < n - 1) return -1;
    long[MAX_N * MAX_N] distance = {};
    int[MAX_N] degree = {};
    bool[MAX_N * MAX_N] seen = {};
    for (int u = 0; u < n; u++) for (int v = 0; v < n; v++)
        distance[u * MAX_N + v] = u == v ? 0 : INF;
    long total_weight = 0;
    for (int edge = 0; edge < m; edge++) {
        long u_value = input[2 + 3 * edge], v_value = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value || weight < 1 || weight > 1000) return -1;
        int u = (int)u_value, v = (int)v_value;
        if (seen[u * MAX_N + v]) return -1;
        seen[u * MAX_N + v] = true;
        seen[v * MAX_N + u] = true;
        distance[u * MAX_N + v] = weight;
        distance[v * MAX_N + u] = weight;
        degree[u]++;
        degree[v]++;
        total_weight += weight;
    }
    for (int middle = 0; middle < n; middle++) for (int source = 0; source < n; source++) for (int target = 0; target < n; target++) {
        long candidate = distance[source * MAX_N + middle] + distance[middle * MAX_N + target];
        if (candidate < distance[source * MAX_N + target]) distance[source * MAX_N + target] = candidate;
    }
    for (int vertex = 0; vertex < n; vertex++) if (distance[vertex] >= INF) return -1;
    int[MAX_N] odd = {};
    int odd_count = 0;
    for (int vertex = 0; vertex < n; vertex++) if ((degree[vertex] & 1) != 0) { odd[odd_count] = vertex; odd_count++; }
    long[1 << MAX_N] pairing = {};
    int state_count = 1 << odd_count;
    for (int mask = 0; mask < state_count; mask++) pairing[mask] = INF;
    pairing[0] = 0;
    for (int mask = 1; mask < state_count; mask++) {
        int first = 0;
        while ((mask & (1 << first)) == 0) first++;
        int first_bit = 1 << first;
        for (int partner = first + 1; partner < odd_count; partner++) {
            int partner_bit = 1 << partner;
            if ((mask & partner_bit) == 0) continue;
            int remaining = mask ^ first_bit ^ partner_bit;
            long candidate = distance[odd[first] * MAX_N + odd[partner]] + pairing[remaining];
            if (candidate < pairing[mask]) pairing[mask] = candidate;
        }
    }
    return total_weight + pairing[state_count - 1];
}
