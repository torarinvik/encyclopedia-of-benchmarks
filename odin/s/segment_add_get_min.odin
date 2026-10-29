package segment_add_get_min

import "core:c"

Max_Initial_Segments :: 16
Max_Operations :: 32
Domain_Low :: i64(-32)
Domain_High :: i64(31)
Domain_Right :: i64(32)
Coefficient_Limit :: i64(1000)
Infinity_Value :: i64(1_000_000_000_000)
Checksum_Offset :: i64(33_001)
Tree_Capacity :: 4 * 64 + 8
Max_Input_Length :: 2 + 4 * Max_Initial_Segments + 5 * Max_Operations

Node :: struct {
    slope, intercept: i64,
    occupied: bool,
}

Tree :: struct { nodes: [Tree_Capacity]Node }

evaluate :: proc "contextless" (slope, intercept, x: i64) -> i64 {
    return slope * x + intercept
}

add_line :: proc "contextless" (tree: ^Tree, node: int, low, high, slope, intercept: i64) {
    if !tree.nodes[node].occupied {
        tree.nodes[node].slope = slope
        tree.nodes[node].intercept = intercept
        tree.nodes[node].occupied = true
        return
    }
    middle := low + (high - low) / 2
    candidate_slope, candidate_intercept := slope, intercept
    if evaluate(candidate_slope, candidate_intercept, middle) < evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, middle) {
        candidate_slope, tree.nodes[node].slope = tree.nodes[node].slope, candidate_slope
        candidate_intercept, tree.nodes[node].intercept = tree.nodes[node].intercept, candidate_intercept
    }
    if low == high do return
    if evaluate(candidate_slope, candidate_intercept, low) < evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, low) {
        add_line(tree, 2 * node, low, middle, candidate_slope, candidate_intercept)
    } else if evaluate(candidate_slope, candidate_intercept, high) < evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, high) {
        add_line(tree, 2 * node + 1, middle + 1, high, candidate_slope, candidate_intercept)
    }
}

add_segment :: proc "contextless" (tree: ^Tree, node: int, low, high, query_low, query_high, slope, intercept: i64) {
    if query_high <= low || high < query_low do return
    if query_low <= low && high < query_high {
        add_line(tree, node, low, high, slope, intercept)
        return
    }
    middle := low + (high - low) / 2
    add_segment(tree, 2 * node, low, middle, query_low, query_high, slope, intercept)
    add_segment(tree, 2 * node + 1, middle + 1, high, query_low, query_high, slope, intercept)
}

minimum_at :: proc "contextless" (tree: ^Tree, node: int, low, high, x: i64) -> i64 {
    best := Infinity_Value
    if tree.nodes[node].occupied do best = evaluate(tree.nodes[node].slope, tree.nodes[node].intercept, x)
    if low == high do return best
    middle := low + (high - low) / 2
    go_left := x <= middle
    nested := minimum_at(tree, (if go_left { 2 * node } else { 2 * node + 1 }),
                         (if go_left { low } else { middle + 1 }),
                         (if go_left { middle } else { high }), x)
    if nested < best do best = nested
    return best
}

valid_segment :: proc "contextless" (left, right, slope, intercept: i64) -> bool {
    return left >= Domain_Low && left < right && right <= Domain_Right &&
        slope >= -Coefficient_Limit && slope <= Coefficient_Limit &&
        intercept >= -Coefficient_Limit && intercept <= Coefficient_Limit
}

@(export)
segment_add_get_min :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > c.size_t(Max_Input_Length) do return -1
    initial_value, operation_value := values[0], values[1]
    if initial_value < 0 || initial_value > i64(Max_Initial_Segments) ||
        operation_value < 0 || operation_value > i64(Max_Operations) do return -1
    initial_count, operation_count := int(initial_value), int(operation_value)

    tree := Tree{}
    position := 2
    for index := 0; index < initial_count; index += 1 {
        if int(length) - position < 4 do return -1
        left, right, slope, intercept := values[position], values[position + 1], values[position + 2], values[position + 3]
        if !valid_segment(left, right, slope, intercept) do return -1
        add_segment(&tree, 1, Domain_Low, Domain_High, left, right, slope, intercept)
        position += 4
    }

    checksum, query_number := i64(0), i64(0)
    for index := 0; index < operation_count; index += 1 {
        if position >= int(length) do return -1
        opcode := values[position]
        position += 1
        if opcode == 0 {
            if int(length) - position < 4 do return -1
            left, right, slope, intercept := values[position], values[position + 1], values[position + 2], values[position + 3]
            if !valid_segment(left, right, slope, intercept) do return -1
            add_segment(&tree, 1, Domain_Low, Domain_High, left, right, slope, intercept)
            position += 4
        } else if opcode == 1 {
            if position >= int(length) do return -1
            x := values[position]
            position += 1
            if x < Domain_Low || x > Domain_High do return -1
            answer := minimum_at(&tree, 1, Domain_Low, Domain_High, x)
            query_number += 1
            checksum += query_number * (answer + Checksum_Offset)
        } else {
            return -1
        }
    }
    if position != int(length) do return -1
    return checksum
}
