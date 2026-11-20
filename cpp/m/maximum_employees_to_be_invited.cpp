#include <cstddef>
#include <cstdint>

extern "C" std::int64_t maximum_employees_to_be_invited(const std::int64_t *input, std::size_t length) {
    constexpr std::size_t max_n = 8;
    if (input == nullptr || length < 3 || length > 10) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_n) || length != static_cast<std::size_t>(n_value + 1)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    std::int64_t favorite[max_n], indegree[max_n]{}, chain[max_n], queue[max_n];
    bool visited[max_n]{};
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t target = input[i + 1];
        if (target < 0 || target >= n_value || target == static_cast<std::int64_t>(i)) return -1;
        favorite[i] = target;
        chain[i] = 1;
        ++indegree[target];
    }
    std::size_t head = 0, tail = 0;
    for (std::size_t i = 0; i < n; ++i) if (indegree[i] == 0) queue[tail++] = static_cast<std::int64_t>(i);
    while (head < tail) {
        const std::size_t node = static_cast<std::size_t>(queue[head++]);
        const std::size_t target = static_cast<std::size_t>(favorite[node]);
        if (chain[node] + 1 > chain[target]) chain[target] = chain[node] + 1;
        if (--indegree[target] == 0) queue[tail++] = static_cast<std::int64_t>(target);
    }
    std::int64_t pair_total = 0, longest_cycle = 0;
    for (std::size_t start = 0; start < n; ++start) {
        if (indegree[start] == 0 || visited[start]) continue;
        std::size_t node = start, first = 0, second = 0;
        std::int64_t cycle_length = 0;
        while (!visited[node]) {
            visited[node] = true;
            if (cycle_length == 0) first = node;
            else if (cycle_length == 1) second = node;
            ++cycle_length;
            node = static_cast<std::size_t>(favorite[node]);
        }
        if (cycle_length == 2) pair_total += chain[first] + chain[second];
        else if (cycle_length > longest_cycle) longest_cycle = cycle_length;
    }
    return pair_total > longest_cycle ? pair_total : longest_cycle;
}
