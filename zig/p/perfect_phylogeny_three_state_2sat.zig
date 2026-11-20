const MAX_TAXA: usize = 8;
const MAX_CHARACTERS: usize = 8;
const MAX_LITERALS: usize = 48;
const MAX_INPUT: usize = 67;
const Graph = [MAX_LITERALS][MAX_LITERALS]bool;

fn addClause(graph: *Graph, reverse: *Graph, left: usize, right: usize) void {
    const from_left = left ^ 1;
    const from_right = right ^ 1;
    graph[from_left][right] = true;
    reverse[right][from_left] = true;
    graph[from_right][left] = true;
    reverse[left][from_right] = true;
}

fn solve(values: []const i64) i64 {
    if (values.len < 2 or values.len > MAX_INPUT) return -1;
    if (values[0] < 1 or values[0] > MAX_TAXA or values[1] < 0 or values[1] > MAX_CHARACTERS) return -1;
    const taxa: usize = @intCast(values[0]);
    const characters: usize = @intCast(values[1]);
    if (values.len != 2 + taxa * characters) return -1;

    var masks: [MAX_CHARACTERS][3]u16 = @splat(@splat(0));
    for (0..taxa) |taxon| {
        for (0..characters) |character| {
            const state = values[2 + taxon * characters + character];
            if (state < 0 or state > 2) return -1;
            masks[character][@intCast(state)] |= @as(u16, 1) << @intCast(taxon);
        }
    }

    var graph: Graph = @splat(@splat(false));
    var reverse: Graph = @splat(@splat(false));
    for (0..characters) |character| {
        const v0 = 3 * character;
        addClause(&graph, &reverse, 2 * v0, 2 * (v0 + 1));
        addClause(&graph, &reverse, 2 * v0, 2 * (v0 + 2));
        addClause(&graph, &reverse, 2 * (v0 + 1), 2 * (v0 + 2));
        var present: usize = 0;
        var missing: usize = 0;
        for (0..3) |state| {
            if (masks[character][state] == 0) {
                missing = state;
            } else {
                present += 1;
            }
        }
        if (present == 2) {
            const absent_literal = 2 * (3 * character + missing) + 1;
            addClause(&graph, &reverse, absent_literal, absent_literal);
        }
    }
    const universe: u16 = (@as(u16, 1) << @intCast(taxa)) - 1;
    for (0..characters) |left_character| {
        for (left_character + 1..characters) |right_character| {
            for (0..3) |left_state| {
                const left = masks[left_character][left_state];
                for (0..3) |right_state| {
                    const right = masks[right_character][right_state];
                    if (left & right != 0 and left & universe & ~right != 0
                        and right & universe & ~left != 0 and universe & ~(left | right) != 0)
                    {
                        const left_variable = 3 * left_character + left_state;
                        const right_variable = 3 * right_character + right_state;
                        addClause(&graph, &reverse, 2 * left_variable + 1, 2 * right_variable + 1);
                    }
                }
            }
        }
    }

    const literal_count = 6 * characters;
    var seen: [MAX_LITERALS]bool = @splat(false);
    var order: [MAX_LITERALS]usize = @splat(0);
    var stack: [MAX_LITERALS]usize = @splat(0);
    var next_index: [MAX_LITERALS]usize = @splat(0);
    var order_count: usize = 0;
    for (0..literal_count) |start| {
        if (seen[start]) continue;
        var top: usize = 1;
        stack[0] = start;
        seen[start] = true;
        while (top > 0) {
            const vertex = stack[top - 1];
            var next = next_index[vertex];
            while (next < literal_count and (!graph[vertex][next] or seen[next])) : (next += 1) {}
            if (next < literal_count) {
                next_index[vertex] = next + 1;
                seen[next] = true;
                stack[top] = next;
                top += 1;
            } else {
                order[order_count] = vertex;
                order_count += 1;
                top -= 1;
            }
        }
    }
    var component: [MAX_LITERALS]i16 = @splat(-1);
    var label: i16 = 0;
    while (order_count > 0) {
        order_count -= 1;
        const start = order[order_count];
        if (component[start] >= 0) continue;
        var top: usize = 1;
        stack[0] = start;
        component[start] = label;
        while (top > 0) {
            top -= 1;
            const vertex = stack[top];
            for (0..literal_count) |next| {
                if (reverse[vertex][next] and component[next] < 0) {
                    component[next] = label;
                    stack[top] = next;
                    top += 1;
                }
            }
        }
        label += 1;
    }
    for (0..3 * characters) |variable| {
        if (component[2 * variable] == component[2 * variable + 1]) return 0;
    }
    return 1;
}

export fn perfect_phylogeny_three_state_2sat(input_ptr: ?[*]const i64, length: usize) i64 {
    const input = input_ptr orelse return -1;
    if (length < 2 or length > MAX_INPUT) return -1;
    return solve(input[0..length]);
}
