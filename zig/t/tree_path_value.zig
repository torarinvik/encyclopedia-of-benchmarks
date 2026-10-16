/// Port of Go Problem18's chunked search over its triangle-shaped DAG.
export fn tree_path_value(packed: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 121) return -1;
    if (packed[0] < 1 or packed[0] > 14) return -1;
    const depth: usize = @intCast(packed[0]);
    const count = length - 1;
    if (count == 0) return 0;

    var values: [120]i64 = undefined;
    var left_children: [120]isize = undefined;
    var right_children: [120]isize = undefined;
    for (0..count) |index| {
        values[index] = packed[index + 1];
        left_children[index] = -1;
        right_children[index] = -1;
        if ((index == 0 and (values[index] < -1000 or values[index] > 1000))
            or (index > 0 and (values[index] < 1 or values[index] > 1000))) return -1;
    }

    var row_start: usize = 0;
    var width: usize = 1;
    while (row_start < count) {
        for (0..width) |column| {
            if (row_start + column >= count) break;
            const parent = row_start + column;
            const left_index = row_start + width + column;
            const right_index = left_index + 1;
            if (left_index < count) left_children[parent] = @intCast(left_index);
            if (right_index < count) right_children[parent] = @intCast(right_index);
        }
        row_start += width;
        width += 1;
    }

    var pivot: usize = 0;
    var maximum = values[0];
    while (left_children[pivot] >= 0) {
        var stack_node: [16]usize = undefined;
        var stack_steps: [16]usize = undefined;
        var stack_sum: [16]i64 = undefined;
        var stack_size: usize = 1;
        stack_node[0] = pivot;
        stack_steps[0] = depth;
        stack_sum[0] = maximum;
        while (stack_size > 0) {
            stack_size -= 1;
            const node = stack_node[stack_size];
            const steps = stack_steps[stack_size];
            const sum = stack_sum[stack_size];
            if (steps == 0) {
                if (sum > maximum) { maximum = sum; pivot = node; }
                continue;
            }
            if (right_children[node] >= 0) {
                const child: usize = @intCast(right_children[node]);
                stack_node[stack_size] = child;
                stack_steps[stack_size] = steps - 1;
                stack_sum[stack_size] = sum + values[child];
                stack_size += 1;
            }
            if (left_children[node] >= 0) {
                const child: usize = @intCast(left_children[node]);
                stack_node[stack_size] = child;
                stack_steps[stack_size] = steps - 1;
                stack_sum[stack_size] = sum + values[child];
                stack_size += 1;
            } else if (sum > maximum) {
                maximum = sum;
                pivot = node;
            }
        }
    }
    return maximum;
}
