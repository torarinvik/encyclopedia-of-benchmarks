const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;
const MAX_STATES: usize = 2 * MAX_PATTERN + 2;
const ALPHABET: usize = 4;

const SuffixAutomaton = struct {
    transition: [MAX_STATES][ALPHABET]i64,
    suffix_link: [MAX_STATES]i64,
    max_length: [MAX_STATES]i64,
    state_count: usize,
};

fn init_sam(sam: *SuffixAutomaton) void {
    sam.state_count = 1;
    for (0..MAX_STATES) |state| {
        sam.suffix_link[state] = -1;
        sam.max_length[state] = 0;
        for (0..ALPHABET) |symbol| sam.transition[state][symbol] = -1;
    }
}

fn extend(sam: *SuffixAutomaton, last: i64, symbol: usize) i64 {
    if (sam.state_count >= MAX_STATES) return -1;
    const current = sam.state_count;
    sam.state_count += 1;
    sam.max_length[current] = sam.max_length[@intCast(last)] + 1;
    var state = last;
    while (state >= 0 and sam.transition[@intCast(state)][symbol] < 0) {
        sam.transition[@intCast(state)][symbol] = @intCast(current);
        state = sam.suffix_link[@intCast(state)];
    }
    if (state < 0) {
        sam.suffix_link[current] = 0;
    } else {
        const target = sam.transition[@intCast(state)][symbol];
        if (sam.max_length[@intCast(state)] + 1 == sam.max_length[@intCast(target)]) {
            sam.suffix_link[current] = target;
        } else {
            if (sam.state_count >= MAX_STATES) return -1;
            const clone = sam.state_count;
            sam.state_count += 1;
            sam.transition[clone] = sam.transition[@intCast(target)];
            sam.suffix_link[clone] = sam.suffix_link[@intCast(target)];
            sam.max_length[clone] = sam.max_length[@intCast(state)] + 1;
            while (state >= 0 and sam.transition[@intCast(state)][symbol] == target) {
                sam.transition[@intCast(state)][symbol] = @intCast(clone);
                state = sam.suffix_link[@intCast(state)];
            }
            sam.suffix_link[@intCast(target)] = @intCast(clone);
            sam.suffix_link[current] = @intCast(clone);
        }
    }
    return @intCast(current);
}

fn search(sam: *const SuffixAutomaton, text: []const i64, m: usize) i64 {
    var state: usize = 0;
    var matched: i64 = 0;
    var count: i64 = 0;
    var sum: i64 = 0;
    var xor_offsets: i64 = 0;
    for (text, 0..) |value, position| {
        const symbol: usize = @intCast(value);
        var target = sam.transition[state][symbol];
        if (target >= 0) {
            matched += 1;
            state = @intCast(target);
        } else {
            while (state != 0 and sam.transition[state][symbol] < 0)
                state = @intCast(sam.suffix_link[state]);
            target = sam.transition[state][symbol];
            if (target >= 0) {
                matched = sam.max_length[state] + 1;
                state = @intCast(target);
            } else {
                matched = 0;
                state = 0;
            }
        }
        if (@as(usize, @intCast(matched)) == m) {
            const start: i64 = @intCast(position + 1 - m);
            count += 1;
            sum += start;
            xor_offsets ^= start;
        }
    }
    return (count << 36) | (sum << 12) | xor_offsets;
}

export fn forward_dawg_matching(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 0 or n_value > @as(i64, @intCast(MAX_TEXT)) or
        m_value < 1 or m_value > @as(i64, @intCast(MAX_PATTERN))) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + n + m) return -1;
    for (0..n + m) |index| {
        if (input[2 + index] < 0 or input[2 + index] >= @as(i64, @intCast(ALPHABET))) return -1;
    }
    var pattern = [_]i64{0} ** MAX_PATTERN;
    for (0..m) |index| pattern[index] = input[2 + n + index];
    var sam: SuffixAutomaton = undefined;
    init_sam(&sam);
    var last: i64 = 0;
    for (pattern[0..m]) |symbol| {
        last = extend(&sam, last, @intCast(symbol));
        if (last < 0) return -1;
    }
    return search(&sam, input[2 .. 2 + n], m);
}
