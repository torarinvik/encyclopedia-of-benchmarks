const max_n: usize = 64;
const max_m: usize = max_n * (max_n - 1) / 2;
const max_input_values: usize = 2 + 2 * max_m;
const max_output_values: usize = 1 + 2 * max_n;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn connected_components_of_complement_graph(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > 64 or m_value < 0) return -1;
    if (m_value > n_value * (n_value - 1) / 2) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 2 * m) return -1;

    var graph: [max_n]u64 = @splat(0);
    for (0..m) |edge| {
        const left_value = input[2 + 2 * edge];
        const right_value = input[3 + 2 * edge];
        if (left_value < 0 or left_value >= n_value or right_value < 0 or
            right_value >= n_value or left_value == right_value) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        const bit = @as(u64, 1) << @intCast(right);
        if ((graph[left] & bit) != 0) return -1;
        graph[left] |= bit;
        graph[right] |= @as(u64, 1) << @intCast(left);
    }

    var remaining: [max_n]usize = undefined;
    var queue: [max_n]usize = undefined;
    var label: [max_n]i64 = undefined;
    for (0..n) |vertex| {
        remaining[vertex] = vertex;
        label[vertex] = -1;
    }
    var remaining_count = n;
    var component_count: usize = 0;
    while (remaining_count > 0) {
        remaining_count -= 1;
        const root = remaining[remaining_count];
        label[root] = @intCast(component_count);
        var head: usize = 0;
        var tail: usize = 1;
        queue[0] = root;
        while (head < tail) {
            const current = queue[head];
            head += 1;
            var position: usize = 0;
            while (position < remaining_count) {
                const candidate = remaining[position];
                if (((graph[current] >> @intCast(candidate)) & 1) != 0) {
                    position += 1;
                } else {
                    remaining_count -= 1;
                    remaining[position] = remaining[remaining_count];
                    label[candidate] = @intCast(component_count);
                    queue[tail] = candidate;
                    tail += 1;
                }
            }
        }
        component_count += 1;
    }

    var staged: [max_output_values]i64 = undefined;
    var used: usize = 0;
    staged[used] = @intCast(component_count);
    used += 1;
    var emitted: [max_n]bool = @splat(false);
    for (0..n) |first| {
        const component: usize = @intCast(label[first]);
        if (emitted[component]) continue;
        emitted[component] = true;
        var component_size: usize = 0;
        for (0..n) |vertex| {
            if (label[vertex] == @as(i64, @intCast(component))) component_size += 1;
        }
        staged[used] = @intCast(component_size);
        used += 1;
        for (0..n) |vertex| {
            if (label[vertex] == @as(i64, @intCast(component))) {
                staged[used] = @intCast(vertex);
                used += 1;
            }
        }
    }

    const required = 8 * used;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..used) |index| storeI64Le(output, 8 * index, staged[index]);
    return @intCast(required);
}
