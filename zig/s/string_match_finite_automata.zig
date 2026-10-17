const MAX_TEXT_LENGTH: usize = 256;
const MAX_PATTERN_LENGTH: usize = 32;
const ALPHABET_SIZE: usize = 128;
const TRANSITION_TABLE_SIZE: usize = (MAX_PATTERN_LENGTH + 1) * ALPHABET_SIZE;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH + 1;

fn nextState(pattern: [*]const i64, pattern_length: usize, state: usize, symbol: i64) usize {
    if (state < pattern_length and symbol == pattern[state]) return state + 1;
    var candidate = state;
    while (candidate > 0) {
        if (pattern[candidate - 1] == symbol) {
            var prefix_matches = true;
            var index: usize = 0;
            while (index + 1 < candidate) : (index += 1) {
                if (pattern[index] != pattern[state - candidate + index + 1]) {
                    prefix_matches = false;
                    break;
                }
            }
            if (prefix_matches) return candidate;
        }
        candidate -= 1;
    }
    return 0;
}

fn storeI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| {
        output[offset + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
    }
}

export fn string_match_finite_automata(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const raw_text_length = values[0];
    const raw_pattern_length = values[1];
    if (raw_text_length < 0 or raw_text_length > @as(i64, @intCast(MAX_TEXT_LENGTH)) or
        raw_pattern_length < 1 or raw_pattern_length > @as(i64, @intCast(MAX_PATTERN_LENGTH))) return -1;
    const text_length: usize = @intCast(raw_text_length);
    const pattern_length: usize = @intCast(raw_pattern_length);
    if (length != 2 + text_length + pattern_length) return -1;
    for (0..text_length + pattern_length) |index| {
        const symbol = values[2 + index];
        if (symbol < 0 or symbol >= @as(i64, @intCast(ALPHABET_SIZE))) return -1;
    }

    const text = values + 2;
    const pattern = text + text_length;
    var transitions: [TRANSITION_TABLE_SIZE]i32 = @splat(0);
    for (0..pattern_length + 1) |state| {
        for (0..ALPHABET_SIZE) |symbol| {
            transitions[state * ALPHABET_SIZE + symbol] =
                @intCast(nextState(pattern, pattern_length, state, @intCast(symbol)));
        }
    }

    var matches: [MAX_TEXT_LENGTH]i32 = @splat(0);
    var match_count: usize = 0;
    var state: usize = 0;
    for (0..text_length) |index| {
        state = @intCast(transitions[state * ALPHABET_SIZE + @as(usize, @intCast(text[index]))]);
        if (state == pattern_length) {
            matches[match_count] = @intCast(index + 1 - pattern_length);
            match_count += 1;
        }
    }

    const byte_count = 4 * match_count;
    if (output == null or output_capacity < byte_count) return -2;
    for (0..match_count) |index| {
        storeI32Le(output, 4 * index, matches[index]);
    }
    return @intCast(byte_count);
}
