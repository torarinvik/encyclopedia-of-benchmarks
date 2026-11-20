const MAX_STATES: usize = 4;
const MAX_ACTIONS: usize = 3;
const MAX_RECORDS: usize = 12;
const MAX_OUTPUT_WORDS: usize = 13;

const Fraction = struct { numerator: i64, denominator: i64 };
const Context = struct {
    rewards: [MAX_RECORDS]i64 = @splat(0),
    successors: [MAX_RECORDS]i64 = @splat(0),
    policy: [MAX_STATES]usize = @splat(0),
    values: [MAX_STATES]Fraction = @splat(.{ .numerator = 0, .denominator = 1 }),
};

fn gcdU64(a_value: u64, b_value: u64) u64 {
    var a = a_value;
    var b = b_value;
    while (b != 0) {
        const remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

fn reduceFraction(numerator: i64, denominator: i64) Fraction {
    const magnitude: u64 = if (numerator < 0) @intCast(-numerator) else @intCast(numerator);
    const divisor = gcdU64(magnitude, @intCast(denominator));
    return .{ .numerator = @divTrunc(numerator, @as(i64, @intCast(divisor))),
        .denominator = @divTrunc(denominator, @as(i64, @intCast(divisor))) };
}

fn powerI64(base: i64, exponent: usize) i64 {
    var result: i64 = 1;
    for (0..exponent) |_| result *= base;
    return result;
}

fn extendValue(reward: i64, successor: Fraction, p: i64, q: i64) Fraction {
    return reduceFraction(reward * successor.denominator * q + p * successor.numerator,
        successor.denominator * q);
}

fn evaluatePolicy(context: *Context, states: usize, actions: usize, p: i64, q: i64) void {
    for (0..states) |start| {
        var first_seen = [_]i32{-1} ** MAX_STATES;
        var path = [_]usize{0} ** MAX_STATES;
        var path_length: usize = 0;
        var current = start;
        while (first_seen[current] < 0) {
            first_seen[current] = @intCast(path_length);
            path[path_length] = current;
            path_length += 1;
            const state = path[path_length - 1];
            const record = state * actions + context.policy[state];
            current = @intCast(context.successors[record]);
        }
        const cycle_start: usize = @intCast(first_seen[current]);
        const cycle_length = path_length - cycle_start;
        var cycle_numerator: i64 = 0;
        for (0..cycle_length) |j| {
            const state = path[cycle_start + j];
            const record = state * actions + context.policy[state];
            cycle_numerator += context.rewards[record] * powerI64(p, j) * powerI64(q, cycle_length - j);
        }
        context.values[path[cycle_start]] = reduceFraction(cycle_numerator,
            powerI64(q, cycle_length) - powerI64(p, cycle_length));

        var j = path_length;
        while (j > cycle_start + 1) {
            const index = j - 1;
            const state = path[index];
            const next_state = if (index + 1 < path_length) path[index + 1] else path[cycle_start];
            const record = state * actions + context.policy[state];
            context.values[state] = extendValue(context.rewards[record], context.values[next_state], p, q);
            j -= 1;
        }
        j = cycle_start;
        while (j > 0) {
            const index = j - 1;
            const state = path[index];
            const record = state * actions + context.policy[state];
            context.values[state] = extendValue(context.rewards[record], context.values[path[index + 1]], p, q);
            j -= 1;
        }
    }
}

fn improvePolicy(context: *Context, states: usize, actions: usize, p: i64, q: i64) usize {
    var changed: usize = 0;
    for (0..states) |state| {
        var best_action: usize = 0;
        const best_record = state * actions;
        const best_next: usize = @intCast(context.successors[best_record]);
        var best = extendValue(context.rewards[best_record], context.values[best_next], p, q);
        for (1..actions) |action| {
            const record = state * actions + action;
            const next_state: usize = @intCast(context.successors[record]);
            const candidate = extendValue(context.rewards[record], context.values[next_state], p, q);
            if (candidate.numerator * best.denominator > best.numerator * candidate.denominator) {
                best_action = action;
                best = candidate;
            }
        }
        if (context.policy[state] != best_action) {
            context.policy[state] = best_action;
            changed += 1;
        }
    }
    return changed;
}

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn mdp_policy_iteration(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > 28) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_STATES)) or
        values[1] < 1 or values[1] > @as(i64, @intCast(MAX_ACTIONS)) or
        values[3] < 1 or values[3] > 4 or values[2] < 0 or values[2] >= values[3]) return -1;
    const states: usize = @intCast(values[0]);
    const actions: usize = @intCast(values[1]);
    const p = values[2];
    const q = values[3];
    if (length != 4 + 2 * states * actions) return -1;
    var context = Context{};
    for (0..states * actions) |i| {
        const reward = values[4 + 2 * i];
        const successor = values[5 + 2 * i];
        if (reward < -20 or reward > 20 or successor < 0 or successor >= @as(i64, @intCast(states))) return -1;
        context.rewards[i] = reward;
        context.successors[i] = successor;
    }
    var policy_count: usize = 1;
    for (0..states) |_| policy_count *= actions;
    var stable = false;
    for (0..(policy_count + 1)) |_| {
        evaluatePolicy(&context, states, actions, p, q);
        if (improvePolicy(&context, states, actions, p, q) == 0) { stable = true; break; }
    }
    if (!stable) return -1;
    var words = [_]i64{0} ** MAX_OUTPUT_WORDS;
    words[0] = @intCast(states);
    for (0..states) |state| {
        words[1 + state] = @intCast(context.policy[state]);
        words[1 + states + 2 * state] = context.values[state].numerator;
        words[2 + states + 2 * state] = context.values[state].denominator;
    }
    const output_bytes = (1 + 3 * states) * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    writeI64Le(output.?[0..output_bytes], 0, @intCast(words[0]));
    for (1..1 + 3 * states) |i| writeI64Le(output.?[0..output_bytes], i * 8, words[i]);
    return @intCast(output_bytes);
}
