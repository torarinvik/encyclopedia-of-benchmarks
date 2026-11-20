package divide_combine_tree_incremental

import "core:c"

MAX_N :: 16
MAX_NODES :: 31
TREE_SIZE :: 68

dct_add :: proc "contextless" (node, left, right, ql, qr, delta: int,
    minimum, lazy: []int) {
    if ql <= left && right <= qr {
        minimum[node] += delta
        lazy[node] += delta
        return
    }
    middle := (left + right) / 2
    if lazy[node] != 0 {
        tag := lazy[node]
        minimum[node * 2] += tag
        minimum[node * 2 + 1] += tag
        lazy[node * 2] += tag
        lazy[node * 2 + 1] += tag
        lazy[node] = 0
    }
    if ql <= middle && qr >= left do dct_add(node * 2, left, middle, ql, qr, delta, minimum, lazy)
    if qr > middle && ql <= right do dct_add(node * 2 + 1, middle + 1, right, ql, qr, delta, minimum, lazy)
    if minimum[node * 2] < minimum[node * 2 + 1] {
        minimum[node] = minimum[node * 2]
    } else {
        minimum[node] = minimum[node * 2 + 1]
    }
}

dct_first_zero :: proc "contextless" (node, left, right: int, minimum: []int) -> int {
    if left == right do return left
    middle := (left + right) / 2
    if minimum[node * 2] == 0 do return dct_first_zero(node * 2, left, middle, minimum)
    return dct_first_zero(node * 2 + 1, middle + 1, right, minimum)
}

dct_connected :: proc "contextless" (left, right: int, logs, range_min, range_max: []int) -> bool {
    level := logs[right - left + 1]
    other := right + 1 - (1 << level)
    low := range_min[level * MAX_N + left]
    if range_min[level * MAX_N + other] < low do low = range_min[level * MAX_N + other]
    high := range_max[level * MAX_N + left]
    if range_max[level * MAX_N + other] > high do high = range_max[level * MAX_N + other]
    return high - low == right - left
}

@(export)
divide_combine_tree_incremental :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 18 do return -1
    n_value := input[0]
    if n_value < 1 || n_value > MAX_N || length != c.size_t(n_value + 1) do return -1
    n := int(n_value)
    permutation: [MAX_N]int
    seen: [MAX_N]bool
    for i in 0 ..< n {
        value := input[i + 1]
        if value < 0 || value >= i64(n) || seen[int(value)] do return -1
        permutation[i] = int(value)
        seen[int(value)] = true
    }

    logs: [MAX_N + 1]int
    for i := 2; i <= n; i += 1 do logs[i] = logs[i / 2] + 1
    levels := logs[n] + 1
    range_min: [MAX_N * MAX_N]int
    range_max: [MAX_N * MAX_N]int
    for i in 0 ..< n {
        range_min[i] = permutation[i]
        range_max[i] = permutation[i]
    }
    for level in 1 ..< levels {
        half := 1 << (level - 1)
        width := 2 * half
        for start := 0; start + width <= n; start += 1 {
            a := range_min[(level - 1) * MAX_N + start]
            b := range_min[(level - 1) * MAX_N + start + half]
            if a < b { range_min[level * MAX_N + start] = a } else { range_min[level * MAX_N + start] = b }
            a = range_max[(level - 1) * MAX_N + start]
            b = range_max[(level - 1) * MAX_N + start + half]
            if a > b { range_max[level * MAX_N + start] = a } else { range_max[level * MAX_N + start] = b }
        }
    }

    segment_min: [TREE_SIZE]int
    lazy: [TREE_SIZE]int
    node_left: [MAX_NODES]int
    node_right: [MAX_NODES]int
    node_combine: [MAX_NODES]bool
    node_last: [MAX_NODES]int
    node_stack: [MAX_N]int
    min_stack: [MAX_N]int
    max_stack: [MAX_N]int
    node_top, min_top, max_top, node_count := 0, 0, 0, 0
    for ending in 0 ..< n {
        value := permutation[ending]
        for min_top > 0 && permutation[min_stack[min_top - 1]] >= value {
            min_top -= 1
            position := min_stack[min_top]
            start := 0
            if min_top > 0 do start = min_stack[min_top - 1] + 1
            dct_add(1, 0, n - 1, start, position, permutation[position], segment_min[:], lazy[:])
        }
        for max_top > 0 && permutation[max_stack[max_top - 1]] <= value {
            max_top -= 1
            position := max_stack[max_top]
            start := 0
            if max_top > 0 do start = max_stack[max_top - 1] + 1
            dct_add(1, 0, n - 1, start, position, -permutation[position], segment_min[:], lazy[:])
        }
        start := 0
        if min_top > 0 do start = min_stack[min_top - 1] + 1
        dct_add(1, 0, n - 1, start, ending, -value, segment_min[:], lazy[:])
        min_stack[min_top] = ending
        min_top += 1
        start = 0
        if max_top > 0 do start = max_stack[max_top - 1] + 1
        dct_add(1, 0, n - 1, start, ending, value, segment_min[:], lazy[:])
        max_stack[max_top] = ending
        max_top += 1

        leftmost := dct_first_zero(1, 0, n - 1, segment_min[:])
        current := node_count
        node_count += 1
        node_left[current] = ending
        node_right[current] = ending
        while node_top > 0 && node_left[node_stack[node_top - 1]] >= leftmost {
            top := node_stack[node_top - 1]
            if node_combine[top] && dct_connected(node_last[top], ending, logs[:], range_min[:], range_max[:]) {
                node_right[top] = ending
                node_last[top] = node_left[current]
                node_top -= 1
                current = node_stack[node_top]
            } else if dct_connected(node_left[top], ending, logs[:], range_min[:], range_max[:]) {
                merged := node_count
                node_count += 1
                node_left[merged] = node_left[top]
                node_right[merged] = ending
                node_combine[merged] = true
                node_last[merged] = node_left[current]
                node_top -= 1
                current = merged
            } else {
                merged := node_count
                node_count += 1
                node_left[merged] = -1
                node_right[merged] = ending
                node_top -= 1
                for node_top > 0 && !dct_connected(node_left[node_stack[node_top - 1]], ending, logs[:], range_min[:], range_max[:]) {
                    node_top -= 1
                }
                if node_top == 0 do return -1
                node_top -= 1
                base := node_stack[node_top]
                node_left[merged] = node_left[base]
                current = merged
            }
        }
        node_stack[node_top] = current
        node_top += 1
        dct_add(1, 0, n - 1, 0, ending, -1, segment_min[:], lazy[:])
    }

    for i in 1 ..< node_count {
        left := node_left[i]
        right := node_right[i]
        j := i
        for j > 0 && (node_left[j - 1] > left || (node_left[j - 1] == left && node_right[j - 1] > right)) {
            node_left[j] = node_left[j - 1]
            node_right[j] = node_right[j - 1]
            j -= 1
        }
        node_left[j] = left
        node_right[j] = right
    }
    checksum: i64 = 0
    for i in 0 ..< node_count {
        checksum += i64(i + 1) * (i64(node_left[i] + 1) * i64(n + 1) + i64(node_right[i] + 1))
    }
    return checksum
}
