const MAX_N: usize = 4;
const MAX_INPUT: usize = 2;
const MAX_WORDS: usize = 97;

const SearchState = struct {
    n: usize,
    permutation: [MAX_N]i64,
    staged: [MAX_WORDS]i64,
    cursor: usize,
};

fn visit(state: *SearchState) void {
    for (0..state.n) |index| {
        state.staged[state.cursor] = state.permutation[index];
        state.cursor += 1;
    }
    var reverse_point = state.n;
    for (0..state.n - 1) |index| {
        if (state.permutation[index] > state.permutation[index + 1]) {
            reverse_point = index + 1;
            break;
        }
    }
    for (1..reverse_point) |child| {
        const temporary = state.permutation[child - 1];
        state.permutation[child - 1] = state.permutation[child];
        state.permutation[child] = temporary;
        visit(state);
        state.permutation[child] = state.permutation[child - 1];
        state.permutation[child - 1] = temporary;
    }
    if (reverse_point + 2 <= state.n and
        state.permutation[reverse_point - 1] < state.permutation[reverse_point + 1])
    {
        const left = reverse_point;
        const temporary = state.permutation[left];
        state.permutation[left] = state.permutation[left + 1];
        state.permutation[left + 1] = temporary;
        visit(state);
        state.permutation[left + 1] = state.permutation[left];
        state.permutation[left] = temporary;
    }
}

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn reverse_search_permutation_enumeration(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (length != 1 or n_value < 1 or n_value > MAX_N) return -1;
    const n: usize = @intCast(n_value);
    var count: usize = 1;
    for (2..n + 1) |factor| count *= factor;
    const words = 1 + n * count;
    const required = words * 8;
    if (output_opt == null or capacity < required) return -2;

    var state = SearchState{ .n = n, .permutation = @splat(0), .staged = @splat(0), .cursor = 1 };
    state.staged[0] = @intCast(count);
    for (0..n) |index| state.permutation[index] = @intCast(index + 1);
    visit(&state);
    const output = output_opt.?;
    for (0..words) |word| store_i64_le(output, word * 8, state.staged[word]);
    return @intCast(required);
}
