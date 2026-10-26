const MAX_VARIABLES: usize = 3;
const MAX_CUBES: usize = 27;
const MAX_STATES: usize = 256;
const MAX_INPUT_LENGTH: usize = 9;
const INF_COST: usize = 99;

fn cubeValid(care: usize, value: usize, status: [*]const i64, size: usize) bool {
    var cover: usize = 0;
    for (0..size) |minterm| {
        if ((minterm & care) == value) {
            if (status[minterm] == 0) return false;
            if (status[minterm] == 1) cover |= @as(usize, 1) << @intCast(minterm);
        }
    }
    return cover != 0;
}

fn lexBetter(candidate: u32, incumbent: u32, count: usize) bool {
    for (0..count) |index| {
        const bit = @as(u32, 1) << @intCast(index);
        const left = candidate & bit != 0;
        const right = incumbent & bit != 0;
        if (left != right) return left;
    }
    return false;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn quine_mccluskey_minimization(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values_ptr = input.?;
    const n_value = values_ptr[0];
    if (n_value < 1 or n_value > 3) return -1;
    const n: usize = @intCast(n_value);
    const size = @as(usize, 1) << @intCast(n);
    if (length != 1 + size) return -1;
    for (0..size) |minterm| {
        if (values_ptr[1 + minterm] < 0 or values_ptr[1 + minterm] > 2) return -1;
    }
    const status = values_ptr + 1;

    var cares: [MAX_CUBES]usize = [_]usize{0} ** MAX_CUBES;
    var values: [MAX_CUBES]usize = [_]usize{0} ** MAX_CUBES;
    var covers: [MAX_CUBES]usize = [_]usize{0} ** MAX_CUBES;
    var literal_counts: [MAX_CUBES]usize = [_]usize{0} ** MAX_CUBES;
    var prime_count: usize = 0;
    const full = size - 1;
    for (0..full + 1) |care| {
        for (0..full + 1) |value| {
            if ((value & ~care) != 0 or !cubeValid(care, value, status, size)) continue;
            var prime = true;
            for (0..n) |variable| {
                const bit = @as(usize, 1) << @intCast(variable);
                if ((care & bit) != 0 and cubeValid(care ^ bit, value & ~bit, status, size)) {
                    prime = false;
                    break;
                }
            }
            if (!prime) continue;
            var cover: usize = 0;
            for (0..size) |minterm| {
                if ((minterm & care) == value and status[minterm] == 1) {
                    cover |= @as(usize, 1) << @intCast(minterm);
                }
            }
            var literal_count: usize = 0;
            for (0..n) |variable| {
                if ((care & (@as(usize, 1) << @intCast(variable))) != 0) literal_count += 1;
            }
            cares[prime_count] = care;
            values[prime_count] = value;
            covers[prime_count] = cover;
            literal_counts[prime_count] = literal_count;
            prime_count += 1;
        }
    }
    var on_mask: usize = 0;
    for (0..size) |minterm| {
        if (status[minterm] == 1) on_mask |= @as(usize, 1) << @intCast(minterm);
    }
    const state_count = @as(usize, 1) << @intCast(size);
    var term_cost: [MAX_STATES]usize = [_]usize{INF_COST} ** MAX_STATES;
    var literal_cost: [MAX_STATES]usize = [_]usize{INF_COST} ** MAX_STATES;
    var selected: [MAX_STATES]u32 = [_]u32{0} ** MAX_STATES;
    term_cost[0] = 0;
    literal_cost[0] = 0;
    for (0..prime_count) |index| {
        const prime_bit = @as(u32, 1) << @intCast(index);
        var state = state_count;
        while (state > 0) {
            state -= 1;
            if (term_cost[state] == INF_COST) continue;
            const destination = state | covers[index];
            if (destination == state) continue;
            const new_terms = term_cost[state] + 1;
            const new_literals = literal_cost[state] + literal_counts[index];
            const new_selected = selected[state] | prime_bit;
            var better = new_terms < term_cost[destination];
            if (new_terms == term_cost[destination]) {
                better = new_literals < literal_cost[destination];
                if (new_literals == literal_cost[destination]) {
                    better = lexBetter(new_selected, selected[destination], prime_count);
                }
            }
            if (better) {
                term_cost[destination] = new_terms;
                literal_cost[destination] = new_literals;
                selected[destination] = new_selected;
            }
        }
    }
    const chosen = selected[on_mask];
    var term_count: usize = 0;
    for (0..prime_count) |index| {
        if ((chosen & (@as(u32, 1) << @intCast(index))) != 0) term_count += 1;
    }
    const output_bytes = 8 * (1 + 2 * term_count);
    if (output == null or capacity < output_bytes) return -2;
    const out = output.?;
    storeI64Le(out, 0, @intCast(term_count));
    var cursor: usize = 1;
    for (0..prime_count) |index| {
        if ((chosen & (@as(u32, 1) << @intCast(index))) != 0) {
            storeI64Le(out, cursor * 8, @intCast(cares[index]));
            cursor += 1;
            storeI64Le(out, cursor * 8, @intCast(values[index]));
            cursor += 1;
        }
    }
    return @intCast(output_bytes);
}
