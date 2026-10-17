const MAX_TEXT: usize = 256;
const MAX_QUERIES: usize = 128;
const MAX_STATES: usize = 2 * MAX_TEXT;
const MAX_INPUT_LENGTH: usize = 33283;
const MAX_VALID_INPUT_LENGTH: usize = 33282;
const ALPHABET: usize = 128;

const State = struct {
    length: usize,
    link: i32,
    next: [ALPHABET]i32,
};

fn initializeState(state: *State) void {
    state.length = 0;
    state.link = -1;
    state.next = @splat(-1);
}

fn buildAutomaton(states: *[MAX_STATES]State, text: *const [MAX_TEXT]usize, text_length: usize) usize {
    initializeState(&states[0]);
    var state_count: usize = 1;
    var last: usize = 0;
    for (0..text_length) |position| {
        const symbol = text[position];
        const current = state_count;
        state_count += 1;
        initializeState(&states[current]);
        states[current].length = states[last].length + 1;
        var previous: i32 = @intCast(last);
        while (previous != -1 and states[@intCast(previous)].next[symbol] == -1) {
            states[@intCast(previous)].next[symbol] = @intCast(current);
            previous = states[@intCast(previous)].link;
        }
        if (previous == -1) {
            states[current].link = 0;
        } else {
            const parent: usize = @intCast(previous);
            const next_state: usize = @intCast(states[parent].next[symbol]);
            if (states[parent].length + 1 == states[next_state].length) {
                states[current].link = @intCast(next_state);
            } else {
                const clone = state_count;
                state_count += 1;
                states[clone] = states[next_state];
                states[clone].length = states[parent].length + 1;
                while (previous != -1 and states[@intCast(previous)].next[symbol] == @as(i32, @intCast(next_state))) {
                    states[@intCast(previous)].next[symbol] = @intCast(clone);
                    previous = states[@intCast(previous)].link;
                }
                states[next_state].link = @intCast(clone);
                states[current].link = @intCast(clone);
            }
        }
        last = current;
    }
    return state_count;
}

fn findState(states: *const [MAX_STATES]State, pattern: *const [MAX_TEXT]usize, pattern_length: usize) ?usize {
    var current: usize = 0;
    for (0..pattern_length) |position| {
        const next_state = states[current].next[pattern[position]];
        if (next_state == -1) return null;
        current = @intCast(next_state);
    }
    return current;
}

fn countOccurrences(states: *const [MAX_STATES]State, state_count: usize,
    text: *const [MAX_TEXT]usize, text_length: usize,
    pattern: *const [MAX_TEXT]usize, pattern_length: usize) i64 {
    const pattern_state = findState(states, pattern, pattern_length) orelse return 0;
    var occurrences: [MAX_STATES]i64 = @splat(0);
    var by_length: [MAX_TEXT + 1]usize = @splat(0);
    var order: [MAX_STATES]usize = @splat(0);
    for (0..state_count) |state| by_length[states[state].length] += 1;
    for (1..text_length + 1) |length| by_length[length] += by_length[length - 1];
    var state = state_count;
    while (state > 0) {
        state -= 1;
        const length = states[state].length;
        by_length[length] -= 1;
        order[by_length[length]] = state;
    }
    var last: usize = 0;
    for (0..text_length) |position| {
        last = @intCast(states[last].next[text[position]]);
        occurrences[last] = 1;
    }
    var index = state_count;
    while (index > 0) {
        index -= 1;
        const current = order[index];
        const link = states[current].link;
        if (link != -1) occurrences[@intCast(link)] += occurrences[current];
    }
    return occurrences[pattern_state];
}

fn countDistinctSubstrings(states: *const [MAX_STATES]State, state_count: usize) i64 {
    var total: i64 = 0;
    for (1..state_count) |state| {
        const link: usize = @intCast(states[state].link);
        total += @intCast(states[state].length - states[link].length);
    }
    return total;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn suffix_automaton(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, MAX_TEXT)) return -1;
    const text_length: usize = @intCast(input[0]);
    const query_count_index = text_length + 1;
    if (length <= query_count_index or input[query_count_index] < 0 or input[query_count_index] > @as(i64, MAX_QUERIES)) return -1;
    const query_count: usize = @intCast(input[query_count_index]);
    if (length > MAX_VALID_INPUT_LENGTH) return -1;
    var text: [MAX_TEXT]usize = @splat(0);
    for (0..text_length) |position| {
        const symbol = input[position + 1];
        if (symbol < 0 or symbol >= @as(i64, ALPHABET)) return -1;
        text[position] = @intCast(symbol);
    }
    var states: [MAX_STATES]State = undefined;
    const state_count = buildAutomaton(&states, &text, text_length);
    var results: [MAX_QUERIES]i64 = @splat(0);
    var opcodes: [MAX_QUERIES]u8 = @splat(0);
    var cursor = query_count_index + 1;
    for (0..query_count) |query| {
        if (cursor + 1 >= length) return -1;
        const opcode_value = input[cursor];
        cursor += 1;
        const pattern_length_value = input[cursor];
        cursor += 1;
        if (opcode_value < 0 or opcode_value > 2 or pattern_length_value < 0 or pattern_length_value > @as(i64, MAX_TEXT)) return -1;
        const opcode: usize = @intCast(opcode_value);
        const pattern_length: usize = @intCast(pattern_length_value);
        if (opcode == 2 and pattern_length != 0) return -1;
        if (pattern_length > length - cursor) return -1;
        var pattern: [MAX_TEXT]usize = @splat(0);
        for (0..pattern_length) |position| {
            const symbol = input[cursor];
            cursor += 1;
            if (symbol < 0 or symbol >= @as(i64, ALPHABET)) return -1;
            pattern[position] = @intCast(symbol);
        }
        opcodes[query] = @intCast(opcode);
        if (opcode == 0) {
            results[query] = if (findState(&states, &pattern, pattern_length) != null) 1 else 0;
        } else if (opcode == 1) {
            results[query] = countOccurrences(&states, state_count, &text, text_length, &pattern, pattern_length);
        } else {
            results[query] = countDistinctSubstrings(&states, state_count);
        }
    }
    if (cursor != length) return -1;
    const output_bytes = query_count * 9;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..query_count) |query| {
        output[query * 9] = opcodes[query];
        storeI64Le(output, query * 9 + 1, results[query]);
    }
    return @intCast(output_bytes);
}
