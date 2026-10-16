// Port of Go Problem18's chunked search over its triangle-shaped DAG.
module tree_path_value

@[export: 'tree_path_value']
pub fn tree_path_value(packed &i64, length usize) i64 {
    if length == 0 || length > 121 { return -1 }
    unsafe {
        if packed[0] < 1 || packed[0] > 14 { return -1 }
        depth := int(packed[0])
        count := int(length) - 1
        if count == 0 { return 0 }

        mut values := [120]i64{}
        mut left_children := [120]int{}
        mut right_children := [120]int{}
        for index in 0 .. count {
            values[index] = packed[index + 1]
            left_children[index] = -1
            right_children[index] = -1
            if index == 0 && (values[index] < -1000 || values[index] > 1000) { return -1 }
            if index > 0 && (values[index] < 1 || values[index] > 1000) { return -1 }
        }

        mut row_start := 0
        mut width := 1
        for row_start < count {
            for column in 0 .. width {
                if row_start + column >= count { break }
                parent := row_start + column
                left_index := row_start + width + column
                right_index := left_index + 1
                if left_index < count { left_children[parent] = left_index }
                if right_index < count { right_children[parent] = right_index }
            }
            row_start += width
            width++
        }

        mut pivot := 0
        mut maximum := values[0]
        for left_children[pivot] >= 0 {
            mut stack_node := [16]int{}
            mut stack_steps := [16]int{}
            mut stack_sum := [16]i64{}
            mut stack_size := 1
            stack_node[0] = pivot
            stack_steps[0] = depth
            stack_sum[0] = maximum
            for stack_size > 0 {
                stack_size--
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
                    stack_size++
                }
                if left_children[node] >= 0 {
                    child := left_children[node]
                    stack_node[stack_size] = child
                    stack_steps[stack_size] = steps - 1
                    stack_sum[stack_size] = sum + values[child]
                    stack_size++
                } else if sum > maximum {
                    maximum = sum
                    pivot = node
                }
            }
        }
        return maximum
    }
}
