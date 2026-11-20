package offline_dynamic_bipartiteness

import "core:c"

MAX_VERTICES :: 16
MAX_EVENTS :: 64
MAX_INPUT_VALUES :: 2 + 4 * MAX_EVENTS + 1
TREE_NODES :: 4 * MAX_EVENTS + 8

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

constrain_opposite :: proc "contextless" (left, right: int,
    parent, set_size, xor_parent: [^]int,
    history_kind, history_child, history_root, history_size, history_xor: [^]int,
    history_count, contradictions: ^int) {
    root_left, root_right := left, right
    parity_left, parity_right := 0, 0
    for parent[root_left] != root_left {
        parity_left ^= xor_parent[root_left]
        root_left = parent[root_left]
    }
    for parent[root_right] != root_right {
        parity_right ^= xor_parent[root_right]
        root_right = parent[root_right]
    }
    if root_left == root_right {
        if parity_left ^ parity_right != 1 {
            history_kind[history_count^] = 1
            history_count^ += 1
            contradictions^ += 1
        }
        return
    }
    if set_size[root_left] > set_size[root_right] {
        root_left, root_right = root_right, root_left
    }
    history_kind[history_count^] = 0
    history_child[history_count^] = root_left
    history_root[history_count^] = root_right
    history_size[history_count^] = set_size[root_right]
    history_xor[history_count^] = xor_parent[root_left]
    history_count^ += 1
    parent[root_left] = root_right
    xor_parent[root_left] = parity_left ^ parity_right ^ 1
    set_size[root_right] += set_size[root_left]
}

rollback_to :: proc "contextless" (checkpoint: int,
    parent, set_size, xor_parent: [^]int,
    history_kind, history_child, history_root, history_size, history_xor: [^]int,
    history_count, contradictions: ^int) {
    for history_count^ > checkpoint {
        history_count^ -= 1
        entry := history_count^
        if history_kind[entry] == 1 {
            contradictions^ -= 1
        } else {
            child, root := history_child[entry], history_root[entry]
            parent[child] = child
            xor_parent[child] = history_xor[entry]
            set_size[root] = history_size[entry]
        }
    }
}

solve_time_tree :: proc "contextless" (node, left, right: int,
    operation, edge_left, edge_right: [^]i64,
    bucket_count, buckets: [^]int,
    parent, set_size, xor_parent: [^]int,
    history_kind, history_child, history_root, history_size, history_xor: [^]int,
    history_count, contradictions: ^int, answer: [^]i64) {
    checkpoint := history_count^
    for entry := 0; entry < bucket_count[node]; entry += 1 {
        edge_id := buckets[node * MAX_EVENTS + entry]
        constrain_opposite(int(edge_left[edge_id]), int(edge_right[edge_id]),
            parent, set_size, xor_parent, history_kind, history_child,
            history_root, history_size, history_xor, history_count, contradictions)
    }
    if right - left == 1 {
        if operation[left] == 2 {
            if contradictions^ == 0 {
                answer[left] = 1
            } else {
                answer[left] = 0
            }
        }
    } else {
        middle := left + (right - left) / 2
        solve_time_tree(node * 2, left, middle, operation, edge_left, edge_right,
            bucket_count, buckets, parent, set_size, xor_parent, history_kind,
            history_child, history_root, history_size, history_xor, history_count,
            contradictions, answer)
        solve_time_tree(node * 2 + 1, middle, right, operation, edge_left, edge_right,
            bucket_count, buckets, parent, set_size, xor_parent, history_kind,
            history_child, history_root, history_size, history_xor, history_count,
            contradictions, answer)
    }
    rollback_to(checkpoint, parent, set_size, xor_parent, history_kind,
        history_child, history_root, history_size, history_xor,
        history_count, contradictions)
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

@(export)
offline_dynamic_bipartiteness :: proc "c" (input: [^]i64, length: c.size_t,
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
                second[time] > third || third >= i64(vertex_count) || used_id[int(edge_id)] do return -1
            for prior := 0; prior < MAX_EVENTS; prior += 1 {
                if active[prior] && edge_left[prior] == second[time] && edge_right[prior] == third do return -1
            }
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
            if first[time] != 0 || second[time] != 0 || third != 0 do return -1
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
    xor_parent: [MAX_VERTICES]int
    for vertex := 0; vertex < vertex_count; vertex += 1 {
        parent[vertex] = vertex
        set_size[vertex] = 1
    }
    history_kind: [MAX_EVENTS]int
    history_child: [MAX_EVENTS]int
    history_root: [MAX_EVENTS]int
    history_size: [MAX_EVENTS]int
    history_xor: [MAX_EVENTS]int
    history_count := 0
    contradictions := 0
    answer: [MAX_EVENTS]i64
    if event_count != 0 {
        solve_time_tree(1, 0, event_count, &operation[0], &edge_left[0],
            &edge_right[0], &bucket_count[0], &buckets[0], &parent[0],
            &set_size[0], &xor_parent[0], &history_kind[0], &history_child[0],
            &history_root[0], &history_size[0], &history_xor[0],
            &history_count, &contradictions, &answer[0])
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
