const MAX_TEXT: usize = 64;
const MAX_PATTERN: usize = 16;
const MAX_ALPHABET: usize = 16;
const MAX_PARSEABLE_INPUT: usize = 84;
const MAX_OUTPUT_BYTES: usize = 520;

fn storeWord(output: []u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn patternPair(pattern: []const i64, previous: []const i32,
    current: usize, prefix_position: usize) bool {
    const prior = previous[current];
    if (prior < 0 or @as(i32, @intCast(current)) - prior > @as(i32, @intCast(prefix_position))) {
        return previous[prefix_position] < 0;
    }
    const distance: usize = current - @as(usize, @intCast(prior));
    return pattern[prefix_position] == pattern[prefix_position - distance];
}

fn textPair(text: []const i64, text_position: usize, pattern_position: usize,
    previous: []const i32, last_text: []const i32) bool {
    const prior = previous[pattern_position];
    const symbol: usize = @intCast(text[text_position]);
    if (prior < 0) {
        return last_text[symbol] < @as(i32, @intCast(text_position - pattern_position));
    }
    const distance: usize = pattern_position - @as(usize, @intCast(prior));
    return text[text_position] == text[text_position - distance];
}

export fn parameterized_pattern_matching_kmp(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_PARSEABLE_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, MAX_TEXT) or
        input[1] < 1 or input[1] > @as(i64, MAX_PATTERN) or
        input[2] < 1 or input[2] > @as(i64, MAX_ALPHABET)) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    const alphabet_size: i64 = input[2];
    if (length != 3 + n + m) return -1;

    var text: [MAX_TEXT]i64 = @splat(0);
    var pattern: [MAX_PATTERN]i64 = @splat(0);
    for (0..n + m) |index| {
        const symbol = input[3 + index];
        if (symbol < 0 or symbol >= alphabet_size) return -1;
        if (index < n) text[index] = symbol else pattern[index - n] = symbol;
    }

    var previous: [MAX_PATTERN]i32 = @splat(-1);
    var last_pattern: [MAX_ALPHABET]i32 = @splat(-1);
    for (0..m) |index| {
        const symbol: usize = @intCast(pattern[index]);
        previous[index] = last_pattern[symbol];
        last_pattern[symbol] = @intCast(index);
    }

    var failure: [MAX_PATTERN]usize = @splat(0);
    for (1..m) |current| {
        var matched = failure[current - 1];
        while (matched > 0 and !patternPair(pattern[0..], previous[0..], current, matched)) {
            matched = failure[matched - 1];
        }
        if (patternPair(pattern[0..], previous[0..], current, matched)) matched += 1;
        failure[current] = matched;
    }

    var last_text: [MAX_ALPHABET]i32 = @splat(-1);
    var matches: [MAX_TEXT]i64 = @splat(0);
    var match_count: usize = 0;
    var matched: usize = 0;
    if (m <= n) {
        for (0..n) |text_position| {
            while (true) {
                if (textPair(text[0..], text_position, matched, previous[0..], last_text[0..])) {
                    matched += 1;
                    if (matched == m) {
                        matches[match_count] = @intCast(text_position + 1 - m);
                        match_count += 1;
                        matched = failure[m - 1];
                    }
                    break;
                }
                if (matched == 0) break;
                matched = failure[matched - 1];
            }
            const symbol: usize = @intCast(text[text_position]);
            last_text[symbol] = @intCast(text_position);
        }
    }

    const output_bytes = 8 * (match_count + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    storeWord(staged[0..], 0, @intCast(match_count));
    for (0..match_count) |index| storeWord(staged[0..], index + 1, matches[index]);
    const output = output_opt.?;
    for (0..output_bytes) |index| output[index] = staged[index];
    return @intCast(output_bytes);
}
