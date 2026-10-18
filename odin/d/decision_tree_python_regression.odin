package decision_tree_python_regression

import "core:c"
import "core:math"

MAX_QUERIES :: 12
MAX_TREE_NODES :: 23

Tree_Node :: struct {
    prediction: f64,
    boundary: f64,
    left: int,
    right: int,
    is_leaf: bool,
}

mean_y :: proc(input: [^]f64, samples, start, count: int) -> f64 {
    total: f64 = 0
    for i := 0; i < count; i += 1 { total += input[3+samples+start+i] }
    return total/f64(count)
}

feature_mse :: proc(input: [^]f64, start, count: int, prediction: f64) -> f64 {
    total: f64 = 0
    for i := 0; i < count; i += 1 {
        difference := input[3+start+i]-prediction
        total += difference*difference
    }
    return total/f64(count)
}

build_tree :: proc(input: [^]f64, samples, start, count, depth, min_leaf: int,
        nodes: [^]Tree_Node, next_node: ^int) -> int {
    node := next_node^
    next_node^ += 1
    total_mean := mean_y(input, samples, start, count)
    if count < 2*min_leaf || depth == 1 {
        nodes[node].prediction = total_mean
        nodes[node].is_leaf = true
        return node
    }
    best_split := 0
    minimum_error := 2.0*feature_mse(input, start, count, total_mean)
    for split := min_leaf; split <= count-min_leaf; split += 1 {
        left_mean := mean_y(input, samples, start, split)
        right_count := count-split
        right_mean := mean_y(input, samples, start+split, right_count)
        error := feature_mse(input, start, split, left_mean) + feature_mse(input, start+split, right_count, right_mean)
        if error < minimum_error { best_split = split; minimum_error = error }
    }
    if best_split == 0 {
        nodes[node].prediction = total_mean
        nodes[node].is_leaf = true
        return node
    }
    nodes[node].boundary = input[3+start+best_split]
    nodes[node].is_leaf = false
    nodes[node].left = build_tree(input, samples, start, best_split, depth-1, min_leaf, nodes, next_node)
    nodes[node].right = build_tree(input, samples, start+best_split, count-best_split, depth-1, min_leaf, nodes, next_node)
    return node
}

predict_tree :: proc(nodes: [^]Tree_Node, root: int, query: f64) -> f64 {
    node := root
    for !nodes[node].is_leaf {
        if query >= nodes[node].boundary { node = nodes[node].right } else { node = nodes[node].left }
    }
    return nodes[node].prediction
}

@(export)
decision_tree_python_regression :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 8 || input_length > 41 do return -1
    for i in 0..<3 {
        if !math.is_finite(input[i]) || math.trunc(input[i]) != input[i] do return -1
    }
    if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6 || input[2] < 2 || input[2] > 12 do return -1
    depth, min_leaf, samples := int(input[0]), int(input[1]), int(input[2])
    query_count_index := 3+2*samples
    if input_length <= c.size_t(query_count_index) do return -1
    query_value := input[query_count_index]
    if !math.is_finite(query_value) || math.trunc(query_value) != query_value || query_value < 1 || query_value > 12 do return -1
    queries := int(query_value)
    if input_length != c.size_t(query_count_index+1+queries) || input_length > 40 do return -1
    for i in 3..<query_count_index {
        if !math.is_finite(input[i]) || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 8 do return -1
    }
    for i in query_count_index+1..<int(input_length) {
        if !math.is_finite(input[i]) || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 8 do return -1
    }
    tree: [MAX_TREE_NODES]Tree_Node
    next_node := 0
    root := build_tree(input, samples, 0, samples, depth, min_leaf, &tree[0], &next_node)
    staged: [MAX_QUERIES+1]f64
    staged[0] = f64(queries)
    for i in 0..<queries { staged[i+1] = predict_tree(&tree[0], root, input[query_count_index+1+i]) }
    if output == nil || output_capacity < c.size_t(queries+1) do return -2
    for i in 0..<queries+1 { output[i] = staged[i] }
    return i64(queries+1)
}
