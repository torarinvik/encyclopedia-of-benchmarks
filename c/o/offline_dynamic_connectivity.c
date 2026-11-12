#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_EVENTS 32
#define MAX_INPUT_VALUES (2 + 4 * MAX_EVENTS + 1)
#define TREE_NODES (4 * MAX_EVENTS + 8)

static size_t find_root(const size_t parent[MAX_VERTICES], size_t vertex) {
    while (parent[vertex] != vertex) vertex = parent[vertex];
    return vertex;
}

static void add_interval(size_t node, size_t left, size_t right,
                         size_t query_left, size_t query_right,
                         size_t edge_id,
                         size_t bucket_count[TREE_NODES],
                         size_t buckets[TREE_NODES][MAX_EVENTS]) {
    if (query_left <= left && right <= query_right) {
        buckets[node][bucket_count[node]++] = edge_id;
        return;
    }
    const size_t middle = left + (right - left) / 2;
    if (query_left < middle)
        add_interval(2 * node, left, middle, query_left, query_right,
                     edge_id, bucket_count, buckets);
    if (query_right > middle)
        add_interval(2 * node + 1, middle, right, query_left, query_right,
                     edge_id, bucket_count, buckets);
}

static void unite(size_t left, size_t right,
                  size_t parent[MAX_VERTICES], size_t set_size[MAX_VERTICES],
                  size_t history_child[MAX_VERTICES],
                  size_t history_root[MAX_VERTICES],
                  size_t history_size[MAX_VERTICES], size_t *history_count) {
    size_t root_left = find_root(parent, left);
    size_t root_right = find_root(parent, right);
    if (root_left == root_right) return;
    if (set_size[root_left] > set_size[root_right]) {
        const size_t temporary = root_left;
        root_left = root_right;
        root_right = temporary;
    }
    history_child[*history_count] = root_left;
    history_root[*history_count] = root_right;
    history_size[*history_count] = set_size[root_right];
    ++*history_count;
    parent[root_left] = root_right;
    set_size[root_right] += set_size[root_left];
}

static void rollback_to(size_t checkpoint, size_t parent[MAX_VERTICES],
                        size_t set_size[MAX_VERTICES],
                        const size_t history_child[MAX_VERTICES],
                        const size_t history_root[MAX_VERTICES],
                        const size_t history_size[MAX_VERTICES],
                        size_t *history_count) {
    while (*history_count > checkpoint) {
        --*history_count;
        const size_t child = history_child[*history_count];
        const size_t root = history_root[*history_count];
        parent[child] = child;
        set_size[root] = history_size[*history_count];
    }
}

static void solve_time_tree(
    size_t node, size_t left, size_t right,
    const int64_t operation[MAX_EVENTS],
    const int64_t first[MAX_EVENTS], const int64_t second[MAX_EVENTS],
    const int64_t edge_left[MAX_EVENTS], const int64_t edge_right[MAX_EVENTS],
    const size_t bucket_count[TREE_NODES],
    const size_t buckets[TREE_NODES][MAX_EVENTS],
    size_t parent[MAX_VERTICES], size_t set_size[MAX_VERTICES],
    size_t history_child[MAX_VERTICES], size_t history_root[MAX_VERTICES],
    size_t history_size[MAX_VERTICES], size_t *history_count,
    int64_t answer[MAX_EVENTS]) {
    const size_t checkpoint = *history_count;
    for (size_t entry = 0; entry < bucket_count[node]; ++entry) {
        const size_t edge_id = buckets[node][entry];
        unite((size_t)edge_left[edge_id], (size_t)edge_right[edge_id],
              parent, set_size, history_child, history_root, history_size,
              history_count);
    }
    if (right - left == 1) {
        if (operation[left] == 2)
            answer[left] = find_root(parent, (size_t)first[left]) ==
                           find_root(parent, (size_t)second[left]);
    } else {
        const size_t middle = left + (right - left) / 2;
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

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t offline_dynamic_connectivity(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES ||
        input[1] < 0 || input[1] > MAX_EVENTS) return -1;
    const size_t vertex_count = (size_t)input[0];
    const size_t event_count = (size_t)input[1];
    if (length != 2 + 4 * event_count) return -1;

    int64_t operation[MAX_EVENTS], first[MAX_EVENTS], second[MAX_EVENTS];
    int64_t edge_left[MAX_EVENTS], edge_right[MAX_EVENTS];
    size_t start_time[MAX_EVENTS];
    bool used_id[MAX_EVENTS] = {false};
    bool active[MAX_EVENTS] = {false};
    size_t query_count = 0;
    for (size_t time = 0; time < event_count; ++time) {
        const size_t offset = 2 + 4 * time;
        operation[time] = input[offset];
        first[time] = input[offset + 1];
        second[time] = input[offset + 2];
        const int64_t third = input[offset + 3];
        if (operation[time] == 0) {
            const int64_t edge_id = first[time];
            if (edge_id < 0 || edge_id >= MAX_EVENTS ||
                second[time] < 0 || second[time] >= (int64_t)vertex_count ||
                third < 0 || third >= (int64_t)vertex_count ||
                used_id[(size_t)edge_id]) return -1;
            used_id[(size_t)edge_id] = true;
            active[(size_t)edge_id] = true;
            start_time[(size_t)edge_id] = time;
            edge_left[(size_t)edge_id] = second[time];
            edge_right[(size_t)edge_id] = third;
        } else if (operation[time] == 1) {
            const int64_t edge_id = first[time];
            if (edge_id < 0 || edge_id >= MAX_EVENTS || !active[(size_t)edge_id] ||
                second[time] != 0 || third != 0) return -1;
            active[(size_t)edge_id] = false;
        } else if (operation[time] == 2) {
            if (first[time] < 0 || first[time] >= (int64_t)vertex_count ||
                second[time] < 0 || second[time] >= (int64_t)vertex_count ||
                third != 0) return -1;
            ++query_count;
        } else {
            return -1;
        }
    }

    const size_t required = 8 * query_count;
    if (output == NULL || capacity < required) return -2;

    size_t bucket_count[TREE_NODES] = {0};
    size_t buckets[TREE_NODES][MAX_EVENTS];
    for (size_t edge_id = 0; edge_id < MAX_EVENTS; ++edge_id) {
        if (!used_id[edge_id]) continue;
        size_t end_time = event_count;
        if (!active[edge_id]) {
            end_time = event_count;
            for (size_t time = start_time[edge_id] + 1; time < event_count; ++time) {
                if (operation[time] == 1 && first[time] == (int64_t)edge_id) {
                    end_time = time;
                    break;
                }
            }
        }
        if (start_time[edge_id] < end_time && event_count != 0)
            add_interval(1, 0, event_count, start_time[edge_id], end_time,
                         edge_id, bucket_count, buckets);
    }

    size_t parent[MAX_VERTICES], set_size[MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        parent[vertex] = vertex;
        set_size[vertex] = 1;
    }
    size_t history_child[MAX_VERTICES], history_root[MAX_VERTICES];
    size_t history_size[MAX_VERTICES], history_count = 0;
    int64_t answer[MAX_EVENTS] = {0};
    if (event_count != 0)
        solve_time_tree(1, 0, event_count, operation, first, second,
                        edge_left, edge_right, bucket_count, buckets, parent,
                        set_size, history_child, history_root, history_size,
                        &history_count, answer);

    size_t written = 0;
    for (size_t time = 0; time < event_count; ++time) {
        if (operation[time] == 2) {
            store_i64_le(output, written, answer[time]);
            written += 8;
        }
    }
    return (int64_t)written;
}
