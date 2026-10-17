package k_d_tree

import "core:c"
import "core:math"

INVALID_RESULT :: i64(-1)
OUTPUT_ERROR :: i64(-2)

Node :: struct { point: int, left: int, right: int }

partition_five :: proc(ids: []int, points: ^[15][3]f64, from, to, axis: int) -> int {
    middle := (from + to) / 2
    for i := from; i <= middle; i += 1 {
        minimum := i
        for j := i + 1; j <= to; j += 1 {
            if points^[ids[j]][axis] < points^[ids[minimum]][axis] do minimum = j
        }
        ids[i], ids[minimum] = ids[minimum], ids[i]
    }
    return middle
}

select_kth :: proc(ids: []int, points: ^[15][3]f64, from, to, rank, axis: int) -> int

choose_median_of_medians :: proc(ids: []int, points: ^[15][3]f64, from, to, axis: int) -> int {
    if to - from < 5 do return partition_five(ids, points, from, to, axis)
    medians_to := from
    for start := from; start <= to - 4; start += 5 {
        median := partition_five(ids, points, start, start + 4, axis)
        ids[median], ids[medians_to] = ids[medians_to], ids[median]
        medians_to += 1
    }
    remainder := (to - from + 1) % 5
    if remainder == 0 {
        medians_to -= 1
    } else {
        median := partition_five(ids, points, to - remainder + 1, to, axis)
        ids[median], ids[medians_to] = ids[medians_to], ids[median]
    }
    medians_count := medians_to - from + 1
    return select_kth(ids, points, from, medians_to, (medians_count + 1) / 2, axis)
}

partition_three_way :: proc(ids: []int, points: ^[15][3]f64, from, to, pivot_index, axis: int) -> (int, int) {
    pivot := points^[ids[pivot_index]][axis]
    i, j, k := from, from, to
    for j <= k {
        value := points^[ids[j]][axis]
        if value < pivot {
            ids[i], ids[j] = ids[j], ids[i]
            i += 1
            j += 1
        } else if pivot < value {
            ids[j], ids[k] = ids[k], ids[j]
            if k == 0 do break
            k -= 1
        } else {
            j += 1
        }
    }
    return i - 1, k + 1
}

select_kth :: proc(ids: []int, points: ^[15][3]f64, from, to, rank, axis: int) -> int {
    first, last, target_rank := from, to, rank
    for first < last {
        pivot := choose_median_of_medians(ids, points, first, last, axis)
        smaller_to, larger_from := partition_three_way(ids, points, first, last, pivot, axis)
        absolute_index := first + target_rank - 1
        if absolute_index <= smaller_to {
            last = smaller_to
        } else if absolute_index < larger_from {
            return absolute_index
        } else {
            target_rank -= larger_from - first
            first = larger_from
        }
    }
    return first
}

build_tree :: proc(points: ^[15][3]f64, indices: []int, dimension, depth: int,
    nodes: ^[15]Node, used: ^int) -> int {
    if len(indices) == 0 do return -1
    axis := depth % dimension
    ordered := [15]int{}
    for i in 0..<len(indices) { ordered[i] = indices[i] }
    middle := select_kth(ordered[:len(indices)], points, 0, len(indices) - 1,
                         (len(indices) + 1) / 2, axis)
    current := used^
    used^ += 1
    nodes^[current] = Node{point = ordered[middle], left = -1, right = -1}
    left_ids := [15]int{}
    for i in 0..<middle { left_ids[i] = ordered[i] }
    right_count := len(indices) - middle - 1
    right_ids := [15]int{}
    for i in 0..<right_count { right_ids[i] = ordered[middle + 1 + i] }
    nodes^[current].left = build_tree(points, left_ids[:middle], dimension, depth + 1, nodes, used)
    nodes^[current].right = build_tree(points, right_ids[:right_count], dimension, depth + 1, nodes, used)
    return current
}

search_tree :: proc(points: ^[15][3]f64, nodes: ^[15]Node, current, axis, dimension: int,
    query: ^[3]f64, best: ^f64, best_point: ^int) {
    if current < 0 do return
    node := nodes^[current]
    point := points^[node.point]
    squared := f64(0)
    for a in 0..<dimension {
        delta := query^[a] - point[a]
        squared += delta * delta
    }
    distance := math.sqrt(squared)
    if distance < best^ { best^ = distance; best_point^ = node.point }
    go_left := query^[axis] <= point[axis]
    near := node.right
    far := node.left
    if go_left { near = node.left; far = node.right }
    next_axis := (axis + 1) % dimension
    search_tree(points, nodes, near, next_axis, dimension, query, best, best_point)
    if best^ >= math.abs(point[axis] - query^[axis]) {
        search_tree(points, nodes, far, next_axis, dimension, query, best, best_point)
    }
}

finite_integer_range :: proc(value: f64, low, high: f64) -> bool {
    return !math.is_nan(value) && !math.is_inf(value) && value >= low && value <= high && f64(i64(value)) == value
}

@(export)
k_d_tree :: proc "c" (input: [^]f64, length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 51 do return INVALID_RESULT
    if !finite_integer_range(input[0], 2, 3) do return INVALID_RESULT
    dimension := int(input[0])
    if !finite_integer_range(input[1], 1, 15) do return INVALID_RESULT
    count := int(input[1])
    if int(length) != 2 + dimension * (count + 1) do return INVALID_RESULT
    query := [3]f64{}
    for axis in 0..<dimension {
        value := input[2 + axis]
        if !finite_integer_range(value, -1000, 1000) do return INVALID_RESULT
        query[axis] = value
    }
    points := [15][3]f64{}
    for i in 0..<count {
        for axis in 0..<dimension {
            value := input[2 + dimension + i * dimension + axis]
            if !finite_integer_range(value, -1000, 1000) do return INVALID_RESULT
            points[i][axis] = value
        }
    }
    for axis in 0..<dimension {
        for i in 0..<count {
            for j in i + 1..<count { if points[i][axis] == points[j][axis] do return INVALID_RESULT }
        }
    }
    smallest := f64(1.0e300)
    nearest_count := 0
    for i in 0..<count {
        squared := f64(0)
        for axis in 0..<dimension {
            delta := query[axis] - points[i][axis]
            squared += delta * delta
        }
        if squared < smallest { smallest = squared; nearest_count = 1 }
        else if squared == smallest { nearest_count += 1 }
    }
    if nearest_count != 1 do return INVALID_RESULT
    output_length := dimension + 1
    if output == nil || int(capacity) < output_length do return OUTPUT_ERROR
    indices := [15]int{}
    for i in 0..<count { indices[i] = i }
    nodes := [15]Node{}
    used := 0
    root := build_tree(&points, indices[:count], dimension, 0, &nodes, &used)
    best := f64(1.0e300)
    best_point := 0
    search_tree(&points, &nodes, root, 0, dimension, &query, &best, &best_point)
    output[0] = best
    for axis in 0..<dimension { output[axis + 1] = points[best_point][axis] }
    return i64(output_length)
}
