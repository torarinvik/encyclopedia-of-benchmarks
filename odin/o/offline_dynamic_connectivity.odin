package offline_dynamic_connectivity

import "core:c"

MAX_VERTICES :: 16
MAX_EVENTS :: 32
MAX_INPUT_VALUES :: 2 + 4 * MAX_EVENTS + 1
TREE_NODES :: 4 * MAX_EVENTS + 8

find_root :: proc "contextless" (parent: [^]int, vertex_input: int) -> int {
    vertex := vertex_input
    for parent[vertex] != vertex {
        vertex = parent[vertex]
    }
    return vertex
}

add_interval :: proc "contextless" (node, left, right, query_left, query_right,
    edge_id: int, bucket_count, buckets: [^]int) {
    if query_left <= left && right <= query_right {
        buckets[node * MAX_EVENTS + bucket_count[node]] = edge_id
        bucket_count[node] += 1
        return
    }
    middle := left + (right - left) / 2
    if query_left < middle {
        add_interval(node * 2, left, middle, query_left, query_right,
                     edge_id, bucket_count, buckets)
    }
    if query_right > middle {
        add_interval(node * 2 + 1, middle, right, query_left, query_right,
                     edge_id, bucket_count, buckets)
    }
}

unite :: proc "contextless" (left, right: int, parent, set_size: [^]int,
    history_child, history_root, history_size: [^]int, history_count: ^int) {
    root_left := find_root(parent, left)
    root_right := find_root(parent, right)
    if root_left == root_right do return
    if set_size[root_left] > set_size[root_right] {
        root_left, root_right = root_right, root_left
    }
    history_child[history_count^] = root_left
    history_root[history_count^] = root_right
    history_size[history_count^] = set_size[root_right]
    history_count^ += 1
    parent[root_left] = root_right
    set_size[root_right] += set_size[root_left]
}

rollback_to :: proc "contextless" (checkpoint: int, parent, set_size: [^]int,
    history_child, history_root, history_size: [^]int, history_count: ^int) {
    for history_count^ > checkpoint {
        history_count^ -= 1
        child := history_child[history_count^]
        root := history_root[history_count^]
        parent[child] = child
        set_size[root] = history_size[history_count^]
    }
}

solve_time_tree :: proc "contextless" (node, left, right: int,
    operation, first, second, edge_left, edge_right: [^]i64,
    bucket_count, buckets: [^]int, parent, set_size: [^]int,
    history_child, history_root, history_size: [^]int, history_count: ^int,
    answer: [^]i64) {
    checkpoint := history_count^
    for entry := 0; entry < bucket_count[node]; entry += 1 {
        edge_id := buckets[node * MAX_EVENTS + entry]
        unite(int(edge_left[edge_id]), int(edge_right[edge_id]), parent,
              set_size, history_child, history_root, history_size, history_count)
    }
    if right - left == 1 {
        if operation[left] == 2 {
            if find_root(parent, int(first[left])) == find_root(parent, int(second[left])) {
                answer[left] = 1
            } else {
                answer[left] = 0
            }
        }
    } else {
        middle := left + (right - left) / 2
        solve_time_tree(node * 2, left, middle, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, parent, set_size,
            history_child, history_root, history_size, history_count, answer)
        solve_time_tree(node * 2 + 1, middle, right, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, parent, set_size,
            history_child, history_root, history_size, history_count, answer)
    }
    rollback_to(checkpoint, parent, set_size, history_child, history_root,
                history_size, history_count)
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

@(export)
offline_dynamic_connectivity :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
    if input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EVENTS do return -1
    vertex_count := int(input[0])
    event_count := int(input[1])
    if length != c.size_t(2 + 4 * event_count) do return -1

    operation: [MAX_EVENTS]i64
    first: [MAX_EVENTS]i64
    second: [MAX_EVENTS]i64
    edge_left: [MAX_EVENTS]i64
    edge_right: [MAX_EVENTS]i64
    start_time: [MAX_EVENTS]int
    used_id: [MAX_EVENTS]bool
    active: [MAX_EVENTS]bool
    query_count := 0
    for time := 0; time < event_count; time += 1 {
        offset := 2 + 4 * time
        operation[time] = input[offset]
        first[time] = input[offset + 1]
        second[time] = input[offset + 2]
        third := input[offset + 3]
        if operation[time] == 0 {
            edge_id := first[time]
            if edge_id < 0 || edge_id >= MAX_EVENTS || second[time] < 0 ||
                second[time] >= i64(vertex_count) || third < 0 ||
                third >= i64(vertex_count) || used_id[int(edge_id)] do return -1
            used_id[int(edge_id)] = true
            active[int(edge_id)] = true
            start_time[int(edge_id)] = time
            edge_left[int(edge_id)] = second[time]
            edge_right[int(edge_id)] = third
        } else if operation[time] == 1 {
            edge_id := first[time]
            if edge_id < 0 || edge_id >= MAX_EVENTS || !active[int(edge_id)] ||
                second[time] != 0 || third != 0 do return -1
            active[int(edge_id)] = false
        } else if operation[time] == 2 {
            if first[time] < 0 || first[time] >= i64(vertex_count) ||
                second[time] < 0 || second[time] >= i64(vertex_count) || third != 0 do return -1
            query_count += 1
        } else {
            return -1
        }
    }

    required := 8 * query_count
    if output == nil || capacity < c.size_t(required) do return -2
    bucket_count: [TREE_NODES]int
    buckets: [TREE_NODES * MAX_EVENTS]int
    for edge_id := 0; edge_id < MAX_EVENTS; edge_id += 1 {
        if !used_id[edge_id] do continue
        end_time := event_count
        if !active[edge_id] {
            for time := start_time[edge_id] + 1; time < event_count; time += 1 {
                if operation[time] == 1 && first[time] == i64(edge_id) {
                    end_time = time
                    break
                }
            }
        }
        if start_time[edge_id] < end_time && event_count != 0 {
            add_interval(1, 0, event_count, start_time[edge_id], end_time,
                         edge_id, &bucket_count[0], &buckets[0])
        }
    }

    parent: [MAX_VERTICES]int
    set_size: [MAX_VERTICES]int
    for vertex := 0; vertex < vertex_count; vertex += 1 {
        parent[vertex] = vertex
        set_size[vertex] = 1
    }
    history_child: [MAX_VERTICES]int
    history_root: [MAX_VERTICES]int
    history_size: [MAX_VERTICES]int
    history_count := 0
    answer: [MAX_EVENTS]i64
    if event_count != 0 {
        solve_time_tree(1, 0, event_count, &operation[0], &first[0], &second[0],
            &edge_left[0], &edge_right[0], &bucket_count[0], &buckets[0],
            &parent[0], &set_size[0], &history_child[0], &history_root[0],
            &history_size[0], &history_count, &answer[0])
    }

    written := 0
    for time := 0; time < event_count; time += 1 {
        if operation[time] == 2 {
            store_i64_le(output, written, answer[time])
            written += 8
        }
    }
    return i64(written)
}
