#include <cstddef>
#include <cstdint>

extern "C" std::int64_t lowest_common_ancestor(const std::int64_t *input, std::size_t length)
{
    constexpr std::size_t max_nodes = 1023;
    constexpr std::int64_t invalid_result = -1;
    if (input == nullptr || length < 4 || input[0] < 2 || input[0] > static_cast<std::int64_t>(max_nodes))
        return invalid_result;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (length != 4 + 3 * count) return invalid_result;
    for (std::size_t field = 1; field <= 3; ++field)
        if (input[field] < 0 || static_cast<std::uint64_t>(input[field]) >= count) return invalid_result;
    if (input[2] == input[3]) return invalid_result;
    const std::size_t root = static_cast<std::size_t>(input[1]);
    const std::size_t p = static_cast<std::size_t>(input[2]);
    const std::size_t q = static_cast<std::size_t>(input[3]);

    std::int64_t parent[max_nodes];
    std::size_t stack[max_nodes], path_p[max_nodes], path_q[max_nodes];
    bool seen[max_nodes] = {};
    for (std::size_t node = 0; node < count; ++node) parent[node] = -1;
    for (std::size_t node = 0; node < count; ++node) {
        const std::size_t offset = 4 + 3 * node;
        if (input[offset] < -1'000'000'000 || input[offset] > 1'000'000'000) return invalid_result;
        for (std::size_t edge = 1; edge <= 2; ++edge) {
            const std::int64_t child = input[offset + edge];
            if (child < -1 || (child >= 0 && static_cast<std::uint64_t>(child) >= count))
                return invalid_result;
            if (child >= 0) {
                const std::size_t child_index = static_cast<std::size_t>(child);
                if (parent[child_index] != -1) return invalid_result;
                parent[child_index] = static_cast<std::int64_t>(node);
            }
        }
    }
    if (parent[root] != -1) return invalid_result;
    for (std::size_t node = 0; node < count; ++node)
        if (node != root && parent[node] == -1) return invalid_result;

    std::size_t top = 0, reached = 0;
    stack[top++] = root;
    while (top != 0) {
        const std::size_t node = stack[--top];
        if (seen[node]) return invalid_result;
        seen[node] = true;
        ++reached;
        const std::size_t offset = 4 + 3 * node;
        for (std::size_t edge = 1; edge <= 2; ++edge) {
            const std::int64_t child = input[offset + edge];
            if (child >= 0) stack[top++] = static_cast<std::size_t>(child);
        }
    }
    if (reached != count) return invalid_result;

    std::size_t depth_p = 0, depth_q = 0, current = p;
    while (true) {
        path_p[depth_p++] = current;
        if (current == root) break;
        current = static_cast<std::size_t>(parent[current]);
    }
    current = q;
    while (true) {
        path_q[depth_q++] = current;
        if (current == root) break;
        current = static_cast<std::size_t>(parent[current]);
    }
    std::int64_t ancestor = invalid_result;
    while (depth_p != 0 && depth_q != 0 && path_p[depth_p - 1] == path_q[depth_q - 1]) {
        ancestor = static_cast<std::int64_t>(path_p[depth_p - 1]);
        --depth_p;
        --depth_q;
    }
    return ancestor;
}
