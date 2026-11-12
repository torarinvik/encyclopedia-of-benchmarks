const MAX_QUERIES: usize = 128;
const MAX_RUNS: usize = 64;
const MAX_INPUT_LENGTH: usize = 16_384;
const MAX_OUTPUT_WORDS: usize = 32_768;
const MAX_COMPONENT: i64 = 1_000_000_000;

const Run = struct { direction: i64 = 0, count: i64 = 0 };
const Decoded = struct {
    numerator: i64,
    denominator: i64,
    lower_num: i64,
    lower_den: i64,
    upper_num: i64,
    upper_den: i64,
};

fn gcd(a_value: i64, b_value: i64) i64 {
    var a = a_value;
    var b = b_value;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn valid_fraction(numerator: i64, denominator: i64) bool {
    return numerator >= 1 and numerator <= MAX_COMPONENT and denominator >= 1 and
        denominator <= MAX_COMPONENT and gcd(numerator, denominator) == 1;
}

fn encode_path(numerator_value: i64, denominator_value: i64,
    runs: *[MAX_RUNS]Run) ?usize {
    var numerator = numerator_value;
    var denominator = denominator_value;
    var run_count: usize = 0;
    while (numerator != denominator) {
        if (run_count >= MAX_RUNS) return null;
        if (numerator < denominator) {
            const count = @divTrunc(denominator - 1, numerator);
            runs[run_count] = .{ .direction = 0, .count = count };
            denominator -= count * numerator;
        } else {
            const count = @divTrunc(numerator - 1, denominator);
            runs[run_count] = .{ .direction = 1, .count = count };
            numerator -= count * denominator;
        }
        run_count += 1;
    }
    return run_count;
}

fn decode_path(runs: []const Run) ?Decoded {
    var lower_num: i64 = 0;
    var lower_den: i64 = 1;
    var upper_num: i64 = 1;
    var upper_den: i64 = 0;
    var previous: i64 = -1;
    for (runs) |run| {
        if ((run.direction != 0 and run.direction != 1) or run.count < 1 or
            run.count > MAX_COMPONENT or run.direction == previous) return null;
        if (run.direction == 0) {
            upper_num += run.count * lower_num;
            upper_den += run.count * lower_den;
            if (upper_num > MAX_COMPONENT or upper_den > MAX_COMPONENT) return null;
        } else {
            lower_num += run.count * upper_num;
            lower_den += run.count * upper_den;
            if (lower_num > MAX_COMPONENT or lower_den > MAX_COMPONENT) return null;
        }
        previous = run.direction;
    }
    const numerator = lower_num + upper_num;
    const denominator = lower_den + upper_den;
    if (!valid_fraction(numerator, denominator)) return null;
    return .{ .numerator = numerator, .denominator = denominator,
        .lower_num = lower_num, .lower_den = lower_den,
        .upper_num = upper_num, .upper_den = upper_den };
}

fn common_prefix(left: []const Run, right: []const Run, prefix: *[MAX_RUNS]Run) usize {
    var i: usize = 0;
    var j: usize = 0;
    var count: usize = 0;
    var left_used: i64 = 0;
    var right_used: i64 = 0;
    while (i < left.len and j < right.len and left[i].direction == right[j].direction) {
        const left_remaining = left[i].count - left_used;
        const right_remaining = right[j].count - right_used;
        const shared = @min(left_remaining, right_remaining);
        prefix[count] = .{ .direction = left[i].direction, .count = shared };
        count += 1;
        left_used += shared;
        right_used += shared;
        if (left_used == left[i].count) { i += 1; left_used = 0; }
        if (right_used == right[j].count) { j += 1; right_used = 0; }
    }
    return count;
}

fn append_word(words: *[MAX_OUTPUT_WORDS]i64, word_count: *usize, value: i64) bool {
    if (word_count.* >= MAX_OUTPUT_WORDS) return false;
    words[word_count.*] = value;
    word_count.* += 1;
    return true;
}

export fn stern_brocot_tree(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const query_count = values[0];
    if (query_count < 1 or query_count > @as(i64, @intCast(MAX_QUERIES))) return -1;
    var words: [MAX_OUTPUT_WORDS]i64 = @splat(0);
    var word_count: usize = 0;
    var position: usize = 1;
    for (0..@intCast(query_count)) |_| {
        if (position >= length) return -1;
        const operation = values[position];
        position += 1;
        if (operation == 0) {
            if (position + 2 > length) return -1;
            const numerator = values[position];
            const denominator = values[position + 1];
            position += 2;
            if (!valid_fraction(numerator, denominator)) return -1;
            var runs: [MAX_RUNS]Run = @splat(.{});
            const run_count = encode_path(numerator, denominator, &runs) orelse return -1;
            if (!append_word(&words, &word_count, operation) or
                !append_word(&words, &word_count, @intCast(run_count))) return -1;
            for (runs[0..run_count]) |run| {
                if (!append_word(&words, &word_count, run.direction) or
                    !append_word(&words, &word_count, run.count)) return -1;
            }
        } else if (operation == 1) {
            if (position >= length) return -1;
            const raw_count = values[position];
            position += 1;
            if (raw_count < 0 or raw_count > @as(i64, @intCast(MAX_RUNS))) return -1;
            const run_count: usize = @intCast(raw_count);
            if (position + run_count * 2 > length) return -1;
            var runs: [MAX_RUNS]Run = @splat(.{});
            for (0..run_count) |i| {
                runs[i] = .{ .direction = values[position], .count = values[position + 1] };
                position += 2;
            }
            const decoded = decode_path(runs[0..run_count]) orelse return -1;
            if (!append_word(&words, &word_count, operation) or
                !append_word(&words, &word_count, decoded.numerator) or
                !append_word(&words, &word_count, decoded.denominator)) return -1;
        } else if (operation == 2) {
            if (position + 4 > length) return -1;
            const a = values[position];
            const b = values[position + 1];
            const c = values[position + 2];
            const d = values[position + 3];
            position += 4;
            if (!valid_fraction(a, b) or !valid_fraction(c, d)) return -1;
            var left: [MAX_RUNS]Run = @splat(.{});
            var right: [MAX_RUNS]Run = @splat(.{});
            var prefix: [MAX_RUNS]Run = @splat(.{});
            const left_count = encode_path(a, b, &left) orelse return -1;
            const right_count = encode_path(c, d, &right) orelse return -1;
            const prefix_count = common_prefix(left[0..left_count], right[0..right_count], &prefix);
            const decoded = decode_path(prefix[0..prefix_count]) orelse return -1;
            if (!append_word(&words, &word_count, operation) or
                !append_word(&words, &word_count, decoded.numerator) or
                !append_word(&words, &word_count, decoded.denominator)) return -1;
        } else if (operation == 3) {
            if (position + 3 > length) return -1;
            const depth = values[position];
            const numerator = values[position + 1];
            const denominator = values[position + 2];
            position += 3;
            if (depth < 1 or depth > MAX_COMPONENT or !valid_fraction(numerator, denominator)) return -1;
            var path: [MAX_RUNS]Run = @splat(.{});
            var prefix: [MAX_RUNS]Run = @splat(.{});
            const path_count = encode_path(numerator, denominator, &path) orelse return -1;
            var total_depth: i64 = 0;
            for (path[0..path_count]) |run| total_depth += run.count;
            if (!append_word(&words, &word_count, operation)) return -1;
            if (depth > total_depth) {
                if (!append_word(&words, &word_count, -1)) return -1;
            } else {
                var remaining = depth;
                var prefix_count: usize = 0;
                for (path[0..path_count]) |run| {
                    if (remaining == 0) break;
                    const take = @min(remaining, run.count);
                    prefix[prefix_count] = .{ .direction = run.direction, .count = take };
                    prefix_count += 1;
                    remaining -= take;
                }
                const decoded = decode_path(prefix[0..prefix_count]) orelse return -1;
                if (!append_word(&words, &word_count, decoded.numerator) or
                    !append_word(&words, &word_count, decoded.denominator)) return -1;
            }
        } else if (operation == 4) {
            if (position + 2 > length) return -1;
            const numerator = values[position];
            const denominator = values[position + 1];
            position += 2;
            if (!valid_fraction(numerator, denominator)) return -1;
            var path: [MAX_RUNS]Run = @splat(.{});
            const path_count = encode_path(numerator, denominator, &path) orelse return -1;
            const decoded = decode_path(path[0..path_count]) orelse return -1;
            for ([_]i64{ operation, decoded.lower_num, decoded.lower_den,
                         decoded.upper_num, decoded.upper_den }) |value| {
                if (!append_word(&words, &word_count, value)) return -1;
            }
        } else {
            return -1;
        }
    }
    if (position != length) return -1;
    const byte_count = word_count * 8;
    if (output_capacity < byte_count or output == null) return -2;
    const output_bytes = output.?[0..byte_count];
    for (0..word_count) |i| {
        const bits: u64 = @bitCast(words[i]);
        for (0..8) |byte| output_bytes[i * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return query_count;
}
