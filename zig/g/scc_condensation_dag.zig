// Clean-room bounded Kosaraju plus condensation quotient construction.
const max_n: usize = 8;
const max_m: usize = 28;
const max_input: usize = 58;
const max_output: usize = 17;

export fn scc_condensation_dag(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 0 or n64 > 8 or m64 < 0 or m64 > 28) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 2 + 2 * m) return -1;

    var adjacency: [max_n]u16 = [_]u16{0} ** max_n;
    var reverse: [max_n]u16 = [_]u16{0} ** max_n;
    for (0..m) |edge| {
        const source = input[2 + 2 * edge];
        const target = input[3 + 2 * edge];
        if (source < 0 or source >= n64 or target < 0 or target >= n64) return -1;
        adjacency[@intCast(source)] |= @as(u16, 1) << @intCast(target);
        reverse[@intCast(target)] |= @as(u16, 1) << @intCast(source);
    }

    var visited: [max_n]bool = [_]bool{false} ** max_n;
    var order: [max_n]usize = [_]usize{0} ** max_n;
    var stack_vertex: [max_n]usize = [_]usize{0} ** max_n;
    var stack_next: [max_n]usize = [_]usize{0} ** max_n;
    var order_count: usize = 0;
    for (0..n) |start| {
        if (visited[start]) continue;
        var stack_size: usize = 1;
        stack_vertex[0] = start;
        stack_next[0] = 0;
        visited[start] = true;
        while (stack_size > 0) {
            const frame = stack_size - 1;
            const vertex = stack_vertex[frame];
            var candidate = stack_next[frame];
            while (candidate < n and (adjacency[vertex] & (@as(u16, 1) << @intCast(candidate))) == 0) : (candidate += 1) {}
            if (candidate < n) {
                stack_next[frame] = candidate + 1;
                if (!visited[candidate]) {
                    visited[candidate] = true;
                    stack_vertex[stack_size] = candidate;
                    stack_next[stack_size] = 0;
                    stack_size += 1;
                }
            } else {
                order[order_count] = vertex;
                order_count += 1;
                stack_size -= 1;
            }
        }
    }

    var raw_component: [max_n]i8 = [_]i8{-1} ** max_n;
    for (0..n) |vertex| visited[vertex] = false;
    var component_count: usize = 0;
    while (order_count > 0) {
        order_count -= 1;
        const start = order[order_count];
        if (visited[start]) continue;
        var stack_size: usize = 1;
        stack_vertex[0] = start;
        visited[start] = true;
        raw_component[start] = @intCast(component_count);
        while (stack_size > 0) {
            stack_size -= 1;
            const vertex = stack_vertex[stack_size];
            for (0..n) |next| {
                if ((reverse[vertex] & (@as(u16, 1) << @intCast(next))) != 0 and !visited[next]) {
                    visited[next] = true;
                    raw_component[next] = @intCast(component_count);
                    stack_vertex[stack_size] = next;
                    stack_size += 1;
                }
            }
        }
        component_count += 1;
    }

    var minimum: [max_n]usize = [_]usize{n} ** max_n;
    var raw_order: [max_n]usize = [_]usize{0} ** max_n;
    var canonical: [max_n]usize = [_]usize{0} ** max_n;
    var labels: [max_n]usize = [_]usize{0} ** max_n;
    var row_mask: [max_n]u8 = [_]u8{0} ** max_n;
    for (0..component_count) |component| raw_order[component] = component;
    for (0..n) |vertex| {
        const component: usize = @intCast(raw_component[vertex]);
        if (vertex < minimum[component]) minimum[component] = vertex;
    }
    var i: usize = 1;
    while (i < component_count) : (i += 1) {
        const key = raw_order[i];
        var j = i;
        while (j > 0 and minimum[raw_order[j - 1]] > minimum[key]) : (j -= 1) {
            raw_order[j] = raw_order[j - 1];
        }
        raw_order[j] = key;
    }
    for (0..component_count) |i| canonical[raw_order[i]] = i;
    for (0..n) |vertex| labels[vertex] = canonical[@intCast(raw_component[vertex])];
    for (0..n) |source| {
        for (0..n) |target| {
            if ((adjacency[source] & (@as(u16, 1) << @intCast(target))) == 0) continue;
            const left = labels[source];
            const right = labels[target];
            if (left != right) row_mask[left] |= @as(u8, 1) << @intCast(right);
        }
    }

    const output_size = 1 + n + component_count;
    if (output_opt == null or capacity < output_size) return -2;
    const output = output_opt.?;
    var staged: [max_output]u8 = [_]u8{0} ** max_output;
    staged[0] = @intCast(component_count);
    for (0..n) |vertex| staged[1 + vertex] = @intCast(labels[vertex]);
    for (0..component_count) |component| staged[1 + n + component] = row_mask[component];
    for (0..output_size) |index| output[index] = staged[index];
    return @intCast(output_size);
}
