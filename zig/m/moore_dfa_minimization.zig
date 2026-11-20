const MAX_STATES: usize = 8;
const MAX_ALPHABET: usize = 3;

export fn moore_dfa_minimization(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > 29) return -1;
    const input = input_opt.?[0..length];
    const n64 = input[0];
    const alphabet64 = input[1];
    const start64 = input[2];
    const accepting = input[3];
    if (n64 < 1 or n64 > @as(i64, MAX_STATES)
        or alphabet64 < 1 or alphabet64 > @as(i64, MAX_ALPHABET)) return -1;
    if (start64 < 0 or start64 >= n64 or accepting < 0
        or accepting >= (@as(i64, 1) << @as(u6, @intCast(n64)))) return -1;
    const n: usize = @intCast(n64);
    const alphabet: usize = @intCast(alphabet64);
    if (length != 4 + n * alphabet) return -1;

    var transitions: [MAX_STATES][MAX_ALPHABET]usize = @splat(@splat(0));
    for (0..n) |state| {
        for (0..alphabet) |symbol| {
            const target = input[4 + state * alphabet + symbol];
            if (target < 0 or target >= n64) return -1;
            transitions[state][symbol] = @intCast(target);
        }
    }
    var labels: [MAX_STATES]usize = @splat(0);
    var refined: [MAX_STATES]usize = @splat(0);
    var acceptance_id: [2]i8 = .{-1, -1};
    var classes: usize = 0;
    for (0..n) |state| {
        const bit: usize = @intCast((accepting >> @as(u6, @intCast(state))) & 1);
        if (acceptance_id[bit] < 0) {
            acceptance_id[bit] = @intCast(classes);
            classes += 1;
        }
        labels[state] = @intCast(acceptance_id[bit]);
    }

    var rounds: usize = 0;
    while (true) {
        var signatures: [MAX_STATES]usize = @splat(0);
        var signature_count: usize = 0;
        for (0..n) |state| {
            var signature = labels[state];
            for (0..alphabet) |symbol| signature = signature * MAX_STATES + labels[transitions[state][symbol]];
            var id: usize = 0;
            while (id < signature_count and signatures[id] != signature) : (id += 1) {}
            if (id == signature_count) {
                signatures[signature_count] = signature;
                signature_count += 1;
            }
            refined[state] = id;
        }
        var changed = false;
        for (0..n) |state| {
            if (refined[state] != labels[state]) changed = true;
        }
        if (!changed) {
            classes = signature_count;
            break;
        }
        @memcpy(labels[0..n], refined[0..n]);
        classes = signature_count;
        rounds += 1;
    }

    var packed: i64 = (@as(i64, @intCast(classes)) << 28) | (@as(i64, @intCast(rounds)) << 24);
    for (0..n) |state| packed |= @as(i64, @intCast(labels[state])) << @as(u6, @intCast(3 * state));
    return packed;
}
