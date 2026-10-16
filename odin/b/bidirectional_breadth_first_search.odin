package bidirectional_breadth_first_search

import "core:c"

Max_Dimension :: 8
Max_Cells :: Max_Dimension * Max_Dimension
Max_Input_Length :: 5 + Max_Cells
Max_Output_Values :: 1 + Max_Cells

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> (8 * byte))
    }
}

@(export)
bidirectional_breadth_first_search :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 5 || length > Max_Input_Length do return -1
    rows_value, cols_value := input[0], input[1]
    if rows_value < 1 || rows_value > Max_Dimension || cols_value < 1 || cols_value > Max_Dimension do return -1
    rows, cols := int(rows_value), int(cols_value)
    cells := rows * cols
    start_value, goal_value, blocked_count_value := input[2], input[3], input[4]
    if start_value < 0 || start_value >= i64(cells) || goal_value < 0 || goal_value >= i64(cells) || blocked_count_value < 0 || blocked_count_value > i64(cells) do return -1
    blocked_count := int(blocked_count_value)
    if length != c.size_t(5 + blocked_count) do return -1
    start, goal := int(start_value), int(goal_value)
    blocked: [Max_Cells]bool
    for index := 0; index < blocked_count; index += 1 {
        value := input[5 + index]
        if value < 0 || value >= i64(cells) do return -1
        cell := int(value)
        if blocked[cell] do return -1
        blocked[cell] = true
    }
    if blocked[start] || blocked[goal] do return -1

    distance: [2 * Max_Cells]i64
    parent: [2 * Max_Cells]i64
    for index := 0; index < 2 * Max_Cells; index += 1 { distance[index] = -1; parent[index] = -1 }
    queues: [2 * Max_Cells]int
    head: [2]int
    tail: [2]int
    tail[0], tail[1] = 1, 1
    distance[start] = 0
    distance[Max_Cells + goal] = 0
    queues[0], queues[Max_Cells] = start, goal
    meeting := -1
    if start == goal do meeting = start
    for meeting < 0 && head[0] < tail[0] && head[1] < tail[1] {
      for side := 0; side < 2; side += 1 {
        if meeting >= 0 do break
        layer_end := tail[side]
        for head[side] < layer_end {
            node := queues[side * Max_Cells + head[side]]
            head[side] += 1
            row, col := node / cols, node % cols
            neighbors := [4]int{-1, -1, -1, -1}
            if row > 0 do neighbors[0] = node - cols
            if col > 0 do neighbors[1] = node - 1
            if row + 1 < rows do neighbors[2] = node + cols
            if col + 1 < cols do neighbors[3] = node + 1
            for neighbor in neighbors {
                if neighbor < 0 || blocked[neighbor] || distance[side * Max_Cells + neighbor] >= 0 do continue
                distance[side * Max_Cells + neighbor] = distance[side * Max_Cells + node] + 1
                parent[side * Max_Cells + neighbor] = i64(node)
                queues[side * Max_Cells + tail[side]] = neighbor
                tail[side] += 1
                if distance[(1 - side) * Max_Cells + neighbor] >= 0 { meeting = neighbor; break }
            }
            if meeting >= 0 do break
        }
      }
    }
    encoded: [Max_Output_Values]i64
    value_count := 1
    if meeting < 0 {
        encoded[0] = 0
    } else {
        reverse_path: [Max_Cells]int
        prefix_count, path_count := 0, 0
        current := meeting
        for current >= 0 {
            reverse_path[prefix_count] = current
            prefix_count += 1
            if current == start do break
            current = int(parent[current])
        }
        for index := 0; index < prefix_count; index += 1 {
            encoded[1 + path_count] = i64(reverse_path[prefix_count - 1 - index])
            path_count += 1
        }
        current = int(parent[Max_Cells + meeting])
        for current >= 0 {
            encoded[1 + path_count] = i64(current)
            path_count += 1
            current = int(parent[Max_Cells + current])
        }
        encoded[0] = i64(path_count)
        value_count += path_count
    }
    required := value_count * 8
    if output == nil || capacity < c.size_t(required) do return -2
    for index := 0; index < value_count; index += 1 { put_i64(output, index * 8, encoded[index]) }
    return i64(required)
}
