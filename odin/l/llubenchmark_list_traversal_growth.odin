package llubenchmark_list_traversal_growth

import "core:c"

MAX_LISTS :: 4
MAX_INITIAL_LENGTH :: 4
MAX_ITERATIONS :: 16
MAX_NODES :: 36

store_le_i64 :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8((bits >> (8 * byte)) & 255)
    }
}

@(export)
llubenchmark_list_traversal_growth :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length != 3 do return -1
    list_value, initial_value, iteration_value := input[0], input[1], input[2]
    if list_value < 1 || list_value > MAX_LISTS || initial_value < 1 ||
       initial_value > MAX_INITIAL_LENGTH || iteration_value < 0 ||
       iteration_value > MAX_ITERATIONS do return -1
    if output == nil || output_capacity < 16 do return -2
    list_count, initial_length, iterations := int(list_value), int(initial_value), int(iteration_value)

    next_node: [MAX_NODES]i64 = {}
    node_count: [MAX_NODES]i64 = {}
    head: [MAX_LISTS]i64 = {}
    tail: [MAX_LISTS]i64 = {}
    for i := 0; i < MAX_NODES; i += 1 do next_node[i] = -1
    for i := 0; i < MAX_LISTS; i += 1 { head[i] = -1; tail[i] = -1 }
    allocated := 0
    for level := 0; level < initial_length; level += 1 {
        for list := 0; list < list_count; list += 1 {
            node := allocated
            allocated += 1
            next_node[node] = head[list]
            head[list] = i64(node)
            if tail[list] == -1 do tail[list] = i64(node)
        }
    }
    accumulate: i64 = 0
    growth_milli := 0
    for pass := 0; pass < iterations; pass += 1 {
        for list := 0; list < list_count; list += 1 {
            node := head[list]
            for node != -1 {
                index := int(node)
                accumulate += node_count[index]
                node_count[index] += 1
                node = next_node[index]
            }
        }
        growth_milli += 333
        insertions := growth_milli / 1000
        growth_milli -= insertions * 1000
        for ordinal := insertions; ordinal > 0; ordinal -= 1 {
            for list := 0; list < list_count; list += 1 {
                node := allocated
                allocated += 1
                node_count[node] = i64(list + ordinal)
                next_node[node] = -1
                next_node[int(tail[list])] = i64(node)
                tail[list] = i64(node)
            }
        }
    }
    store_le_i64(output, 0, accumulate)
    store_le_i64(output, 8, i64(allocated))
    return 2
}
