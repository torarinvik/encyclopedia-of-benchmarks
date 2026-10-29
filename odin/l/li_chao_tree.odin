package li_chao_tree

import "core:c"

Max_Operations :: 512
Max_Nodes :: Max_Operations * 24 + 1
Domain_Low :: i64(-1_000_000)
Domain_High :: i64(1_000_000)
Coefficient_Limit :: i64(1_000)
Checksum_Offset :: i64(1_000_001_001)

Node :: struct {
    slope, intercept: i64,
    left, right: int,
    occupied: bool,
}
Tree :: struct { nodes: [Max_Nodes]Node, used: int, root: int }

evaluate :: proc "contextless" (slope, intercept, x: i64) -> i64 {
    return slope * x + intercept
}

allocate :: proc "contextless" (tree: ^Tree) -> int {
    if tree.used >= Max_Nodes do return -1
    id := tree.used
    tree.used += 1
    tree.nodes[id].left = -1
    tree.nodes[id].right = -1
    tree.nodes[id].occupied = false
    return id
}

insert_at :: proc "contextless" (tree: ^Tree, id: int, low, high, slope, intercept: i64) -> bool {
    if !tree.nodes[id].occupied {
        tree.nodes[id].slope = slope
        tree.nodes[id].intercept = intercept
        tree.nodes[id].occupied = true
        return true
    }

    middle := low + (high - low) / 2
    candidate_slope, candidate_intercept := slope, intercept
    if evaluate(candidate_slope, candidate_intercept, middle) < evaluate(tree.nodes[id].slope, tree.nodes[id].intercept, middle) {
        candidate_slope, tree.nodes[id].slope = tree.nodes[id].slope, candidate_slope
        candidate_intercept, tree.nodes[id].intercept = tree.nodes[id].intercept, candidate_intercept
    }
    if low == high do return true

    go_left := false
    next_low, next_high := middle + 1, high
    if evaluate(candidate_slope, candidate_intercept, low) < evaluate(tree.nodes[id].slope, tree.nodes[id].intercept, low) {
        go_left = true
        next_low, next_high = low, middle
    } else if evaluate(candidate_slope, candidate_intercept, high) >= evaluate(tree.nodes[id].slope, tree.nodes[id].intercept, high) {
        return true
    }

    child := tree.nodes[id].right
    if go_left do child = tree.nodes[id].left
    if child < 0 {
        child = allocate(tree)
        if child < 0 do return false
        if go_left do tree.nodes[id].left = child else tree.nodes[id].right = child
    }
    return insert_at(tree, child, next_low, next_high, candidate_slope, candidate_intercept)
}

add_line :: proc "contextless" (tree: ^Tree, slope, intercept: i64) -> bool {
    if tree.root < 0 {
        tree.root = allocate(tree)
        if tree.root < 0 do return false
    }
    return insert_at(tree, tree.root, Domain_Low, Domain_High, slope, intercept)
}

minimum_at :: proc "contextless" (tree: ^Tree, id: int, low, high, x: i64) -> i64 {
    node := tree.nodes[id]
    best := evaluate(node.slope, node.intercept, x)
    if low == high do return best
    middle := low + (high - low) / 2
    go_left := x <= middle
    child := node.right
    if go_left do child = node.left
    if child >= 0 {
        nested := minimum_at(tree, child, (if go_left { low } else { middle + 1 }),
                             (if go_left { middle } else { high }), x)
        if nested < best do best = nested
    }
    return best
}

@(export)
li_chao_tree :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || length > c.size_t(1 + 3 * Max_Operations) do return -1
    if values[0] < 0 || values[0] > i64(Max_Operations) do return -1
    operation_count := int(values[0])
    if length != c.size_t(1 + 3 * operation_count) do return -1

    tree := Tree{}
    tree.root = -1
    inserted, query_number, checksum := 0, i64(0), i64(0)
    for operation := 0; operation < operation_count; operation += 1 {
        offset := 1 + 3 * operation
        opcode, first, second := values[offset], values[offset + 1], values[offset + 2]
        if opcode == 0 {
            if first < -Coefficient_Limit || first > Coefficient_Limit || second < -Coefficient_Limit || second > Coefficient_Limit do return -1
            if !add_line(&tree, first, second) do return -1
            inserted += 1
        } else if opcode == 1 {
            if first < Domain_Low || first > Domain_High || second != 0 || inserted == 0 do return -1
            answer := minimum_at(&tree, tree.root, Domain_Low, Domain_High, first)
            query_number += 1
            checksum += i64(query_number) * (answer + Checksum_Offset)
        } else {
            return -1
        }
    }
    return checksum
}
