#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 16;
constexpr std::size_t MAX_EVENTS = 32;
constexpr std::size_t MAX_INPUT_VALUES = 2 + 4 * MAX_EVENTS + 1;
constexpr std::size_t TREE_NODES = 4 * MAX_EVENTS + 8;

std::size_t find_root(const std::size_t parent[MAX_VERTICES], std::size_t vertex) {
    while (parent[vertex] != vertex) vertex = parent[vertex];
    return vertex;
}

void add_interval(std::size_t node, std::size_t left, std::size_t right,
                  std::size_t query_left, std::size_t query_right,
                  std::size_t edge_id,
                  std::size_t bucket_count[TREE_NODES],
                  std::size_t buckets[TREE_NODES][MAX_EVENTS]) {
    if (query_left <= left && right <= query_right) {
        buckets[node][bucket_count[node]++] = edge_id;
        return;
    }
    const std::size_t middle = left + (right - left) / 2;
    if (query_left < middle)
        add_interval(2 * node, left, middle, query_left, query_right,
                     edge_id, bucket_count, buckets);
    if (query_right > middle)
        add_interval(2 * node + 1, middle, right, query_left, query_right,
                     edge_id, bucket_count, buckets);
}

void unite(std::size_t left, std::size_t right,
           std::size_t parent[MAX_VERTICES], std::size_t set_size[MAX_VERTICES],
           std::size_t history_child[MAX_VERTICES],
           std::size_t history_root[MAX_VERTICES],
           std::size_t history_size[MAX_VERTICES], std::size_t& history_count) {
    std::size_t root_left = find_root(parent, left);
    std::size_t root_right = find_root(parent, right);
    if (root_left == root_right) return;
    if (set_size[root_left] > set_size[root_right]) {
        const std::size_t temporary = root_left;
        root_left = root_right;
        root_right = temporary;
    }
    history_child[history_count] = root_left;
    history_root[history_count] = root_right;
    history_size[history_count] = set_size[root_right];
    ++history_count;
    parent[root_left] = root_right;
    set_size[root_right] += set_size[root_left];
}

void rollback_to(std::size_t checkpoint, std::size_t parent[MAX_VERTICES],
                 std::size_t set_size[MAX_VERTICES],
                 const std::size_t history_child[MAX_VERTICES],
                 const std::size_t history_root[MAX_VERTICES],
                 const std::size_t history_size[MAX_VERTICES],
                 std::size_t& history_count) {
    while (history_count > checkpoint) {
        --history_count;
        const std::size_t child = history_child[history_count];
        const std::size_t root = history_root[history_count];
        parent[child] = child;
        set_size[root] = history_size[history_count];
    }
}

void solve_time_tree(
    std::size_t node, std::size_t left, std::size_t right,
    const std::int64_t operation[MAX_EVENTS],
    const std::int64_t first[MAX_EVENTS], const std::int64_t second[MAX_EVENTS],
    const std::int64_t edge_left[MAX_EVENTS], const std::int64_t edge_right[MAX_EVENTS],
    const std::size_t bucket_count[TREE_NODES],
    const std::size_t buckets[TREE_NODES][MAX_EVENTS],
    std::size_t parent[MAX_VERTICES], std::size_t set_size[MAX_VERTICES],
    std::size_t history_child[MAX_VERTICES], std::size_t history_root[MAX_VERTICES],
    std::size_t history_size[MAX_VERTICES], std::size_t& history_count,
    std::int64_t answer[MAX_EVENTS]) {
    const std::size_t checkpoint = history_count;
    for (std::size_t entry = 0; entry < bucket_count[node]; ++entry) {
        const std::size_t edge_id = buckets[node][entry];
        unite(static_cast<std::size_t>(edge_left[edge_id]),
              static_cast<std::size_t>(edge_right[edge_id]), parent, set_size,
              history_child, history_root, history_size, history_count);
    }
    if (right - left == 1) {
        if (operation[left] == 2)
            answer[left] = find_root(parent, static_cast<std::size_t>(first[left])) ==
                           find_root(parent, static_cast<std::size_t>(second[left]));
    } else {
        const std::size_t middle = left + (right - left) / 2;
        solve_time_tree(2 * node, left, middle, operation, first, second,
                        edge_left, edge_right, bucket_count, buckets, parent,
                        set_size, history_child, history_root, history_size,
                        history_count, answer);
        solve_time_tree(2 * node + 1, middle, right, operation, first, second,
                        edge_left, edge_right, bucket_count, buckets, parent,
                        set_size, history_child, history_root, history_size,
                        history_count, answer);
    }
    rollback_to(checkpoint, parent, set_size, history_child, history_root,
                history_size, history_count);
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t offline_dynamic_connectivity(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_VERTICES) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(MAX_EVENTS)) return -1;
    const std::size_t vertex_count = static_cast<std::size_t>(input[0]);
    const std::size_t event_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 4 * event_count) return -1;

    std::int64_t operation[MAX_EVENTS], first[MAX_EVENTS], second[MAX_EVENTS];
    std::int64_t edge_left[MAX_EVENTS], edge_right[MAX_EVENTS];
    std::size_t start_time[MAX_EVENTS];
    bool used_id[MAX_EVENTS] = {};
    bool active[MAX_EVENTS] = {};
    std::size_t query_count = 0;
    for (std::size_t time = 0; time < event_count; ++time) {
        const std::size_t offset = 2 + 4 * time;
        operation[time] = input[offset];
        first[time] = input[offset + 1];
        second[time] = input[offset + 2];
        const std::int64_t third = input[offset + 3];
        if (operation[time] == 0) {
            const std::int64_t edge_id = first[time];
            if (edge_id < 0 || edge_id >= static_cast<std::int64_t>(MAX_EVENTS) ||
                second[time] < 0 || second[time] >= static_cast<std::int64_t>(vertex_count) ||
                third < 0 || third >= static_cast<std::int64_t>(vertex_count) ||
                used_id[static_cast<std::size_t>(edge_id)]) return -1;
            used_id[static_cast<std::size_t>(edge_id)] = true;
            active[static_cast<std::size_t>(edge_id)] = true;
            start_time[static_cast<std::size_t>(edge_id)] = time;
            edge_left[static_cast<std::size_t>(edge_id)] = second[time];
            edge_right[static_cast<std::size_t>(edge_id)] = third;
        } else if (operation[time] == 1) {
            const std::int64_t edge_id = first[time];
            if (edge_id < 0 || edge_id >= static_cast<std::int64_t>(MAX_EVENTS) ||
                !active[static_cast<std::size_t>(edge_id)] || second[time] != 0 || third != 0)
                return -1;
            active[static_cast<std::size_t>(edge_id)] = false;
        } else if (operation[time] == 2) {
            if (first[time] < 0 || first[time] >= static_cast<std::int64_t>(vertex_count) ||
                second[time] < 0 || second[time] >= static_cast<std::int64_t>(vertex_count) ||
                third != 0) return -1;
            ++query_count;
        } else {
            return -1;
        }
    }

    const std::size_t required = 8 * query_count;
    if (output == nullptr || capacity < required) return -2;

    std::size_t bucket_count[TREE_NODES] = {};
    std::size_t buckets[TREE_NODES][MAX_EVENTS];
    for (std::size_t edge_id = 0; edge_id < MAX_EVENTS; ++edge_id) {
        if (!used_id[edge_id]) continue;
        std::size_t end_time = event_count;
        if (!active[edge_id]) {
            for (std::size_t time = start_time[edge_id] + 1; time < event_count; ++time) {
                if (operation[time] == 1 && first[time] == static_cast<std::int64_t>(edge_id)) {
                    end_time = time;
                    break;
                }
            }
        }
        if (start_time[edge_id] < end_time && event_count != 0)
            add_interval(1, 0, event_count, start_time[edge_id], end_time,
                         edge_id, bucket_count, buckets);
    }

    std::size_t parent[MAX_VERTICES], set_size[MAX_VERTICES];
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        parent[vertex] = vertex;
        set_size[vertex] = 1;
    }
    std::size_t history_child[MAX_VERTICES], history_root[MAX_VERTICES];
    std::size_t history_size[MAX_VERTICES], history_count = 0;
    std::int64_t answer[MAX_EVENTS] = {};
    if (event_count != 0)
        solve_time_tree(1, 0, event_count, operation, first, second,
                        edge_left, edge_right, bucket_count, buckets, parent,
                        set_size, history_child, history_root, history_size,
                        history_count, answer);

    std::size_t written = 0;
    for (std::size_t time = 0; time < event_count; ++time) {
        if (operation[time] == 2) {
            store_i64_le(output, written, answer[time]);
            written += 8;
        }
    }
    return static_cast<std::int64_t>(written);
}
