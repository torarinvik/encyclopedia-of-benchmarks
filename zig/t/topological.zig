/// Source-faithful port of TheAlgorithms/Go graph.Topological.
export fn topological(values: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 66 or (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 or values[0] > 64) return -2;
    const vertices: usize = @intCast(values[0]);
    const edge_count = (length - 1) / 2;
    var dependencies: [64]u8 = @splat(0);
    var adjacency: [64]u64 = @splat(0);
    var answer: [96]u8 = undefined;

    for (0..edge_count) |edge| {
        const origin_value = values[1 + 2 * edge];
        const destination_value = values[2 + 2 * edge];
        if (origin_value < 0 or destination_value < 0 or
            @as(u64, @intCast(origin_value)) >= vertices or
            @as(u64, @intCast(destination_value)) >= vertices) return -2;
        const origin: usize = @intCast(origin_value);
        const destination: usize = @intCast(destination_value);
        dependencies[destination] += 1;
        adjacency[origin] |= @as(u64, 1) << @intCast(destination);
    }

    var answer_count: usize = 0;
    for (0..vertices) |root| {
        if (dependencies[root] != 0) continue;
        var stack: [64]usize = undefined;
        var top: usize = 0;
        stack[top] = root;
        top += 1;
        while (top > 0) {
            top -= 1;
            const origin = stack[top];
            answer[answer_count] = @intCast(origin);
            answer_count += 1;
            for (0..vertices) |destination| {
                const edge_mask = @as(u64, 1) << @intCast(destination);
                if ((adjacency[origin] & edge_mask) != 0) {
                    var in_stack = false;
                    for (0..top) |index| {
                        if (stack[index] == destination) {
                            in_stack = true;
                            break;
                        }
                    }
                    if (!in_stack) {
                        stack[top] = destination;
                        top += 1;
                    }
                }
                adjacency[origin] &= ~edge_mask;
                adjacency[destination] &= ~(@as(u64, 1) << @intCast(origin));
            }
        }
    }

    if (output_capacity < answer_count) return -2;
    for (0..answer_count) |index| output[index] = answer[index];
    return @intCast(answer_count);
}
