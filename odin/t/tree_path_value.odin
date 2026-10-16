package tree_path_value

import "core:c"

@(export)
tree_path_value :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
    if packed == nil || length < 1 || length > 121 do return -1
    if packed[0] < 1 || packed[0] > 14 do return -1
    depth := int(packed[0])
    count := int(length) - 1
    if count == 0 do return 0

    values: [120]i64
    left_children: [120]int
    right_children: [120]int
    for index := 0; index < count; index += 1 {
        values[index] = packed[index + 1]
        left_children[index] = -1
        right_children[index] = -1
        if index == 0 && (values[index] < -1000 || values[index] > 1000) do return -1
        if index > 0 && (values[index] < 1 || values[index] > 1000) do return -1
    }

    row_start, width := 0, 1
    for row_start < count {
        for column := 0; column < width; column += 1 {
            if row_start + column >= count do break
            parent := row_start + column
            left_index := row_start + width + column
            right_index := left_index + 1
            if left_index < count do left_children[parent] = left_index
            if right_index < count do right_children[parent] = right_index
        }
        row_start += width
        width += 1
    }

    pivot := 0
    maximum := values[0]
    for left_children[pivot] >= 0 {
        stack_node: [16]int
        stack_steps: [16]int
        stack_sum: [16]i64
        stack_size := 1
        stack_node[0] = pivot
        stack_steps[0] = depth
        stack_sum[0] = maximum
        for stack_size > 0 {
            stack_size -= 1
            node := stack_node[stack_size]
            steps := stack_steps[stack_size]
            sum := stack_sum[stack_size]
            if steps == 0 {
                if sum > maximum { maximum = sum; pivot = node }
                continue
            }
            if right_children[node] >= 0 {
                child := right_children[node]
                stack_node[stack_size] = child
                stack_steps[stack_size] = steps - 1
                stack_sum[stack_size] = sum + values[child]
                stack_size += 1
            }
            if left_children[node] >= 0 {
                child := left_children[node]
                stack_node[stack_size] = child
                stack_steps[stack_size] = steps - 1
                stack_sum[stack_size] = sum + values[child]
                stack_size += 1
            } else if sum > maximum {
                maximum = sum
                pivot = node
            }
        }
    }
    return maximum
}
