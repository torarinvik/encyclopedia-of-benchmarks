const MAX_N: usize = 8;
const MAX_INPUT: usize = MAX_N + 1;
const MAX_CLIQUES: usize = 256;
const MAX_OUTPUT_BYTES: usize = 8 + MAX_CLIQUES;

const SearchState = struct {
    n: usize,
    adjacency: [MAX_N]u16,
    masks: [MAX_CLIQUES]u8,
    count: usize,
};

fn visit(state: *SearchState, clique: u16) void {
    state.masks[state.count] = @intCast(clique);
    state.count += 1;
    var minimum = state.n;
    for (0..state.n) |vertex| {
        if (clique & (@as(u16, 1) << @intCast(vertex)) != 0) {
            minimum = vertex;
            break;
        }
    }
    for (0..minimum) |vertex| {
        const bit = @as(u16, 1) << @intCast(vertex);
        if (clique & bit == 0 and state.adjacency[vertex] & clique == clique)
            visit(state, clique | bit);
    }
}

fn store_i64_le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn clique_reverse_search_enumeration(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > MAX_N or length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    var state = SearchState{ .n = n, .adjacency = @splat(0), .masks = @splat(0), .count = 0 };
    for (0..n) |vertex| {
        const raw = input[vertex + 1];
        if (raw < 0 or raw >= (@as(i64, 1) << @intCast(n)) or
            (raw & (@as(i64, 1) << @intCast(vertex))) != 0) return -1;
        state.adjacency[vertex] = @intCast(raw);
    }
    for (0..n) |left| {
        var right = left + 1;
        while (right < n) : (right += 1) {
            const edge_left = state.adjacency[left] & (@as(u16, 1) << @intCast(right)) != 0;
            const edge_right = state.adjacency[right] & (@as(u16, 1) << @intCast(left)) != 0;
            if (edge_left != edge_right) return -1;
        }
    }
    visit(&state, 0);
    const required = 8 + state.count;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    store_i64_le(&staged, @intCast(state.count));
    for (0..state.count) |index| staged[8 + index] = state.masks[index];
    for (0..required) |byte| output[byte] = staged[byte];
    return @intCast(required);
}
