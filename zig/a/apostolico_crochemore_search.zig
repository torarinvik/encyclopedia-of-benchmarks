const MAX_TEXT_LENGTH: usize = 4096;
const MAX_PATTERN_LENGTH: usize = 128;
const MAX_PARSEABLE_LENGTH: usize = 4227;
const PATTERN_SENTINEL: u8 = 4;

fn buildKmpNext(pattern: []const u8, pattern_length: usize, next: *[MAX_PATTERN_LENGTH + 1]i64) void {
    var i: usize = 0;
    var j: i64 = -1;
    next[0] = -1;
    while (i < pattern_length) {
        while (j > -1 and pattern[i] != pattern[@intCast(j)]) {
            j = next[@intCast(j)];
        }
        i += 1;
        j += 1;
        const following = if (i < pattern_length) pattern[i] else PATTERN_SENTINEL;
        if (following == pattern[@intCast(j)]) {
            next[i] = next[@intCast(j)];
        } else {
            next[i] = j;
        }
    }
}

export fn apostolico_crochemore_search(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    const text_length_value = input[0];
    const pattern_length_value = input[1];
    if (text_length_value < 0 or text_length_value > 4096 or
        pattern_length_value < 1 or pattern_length_value > 128) return -1;
    const text_length: usize = @intCast(text_length_value);
    const pattern_length: usize = @intCast(pattern_length_value);
    if (length != 2 + text_length + pattern_length) return -1;

    var text = [_]u8{0} ** MAX_TEXT_LENGTH;
    var pattern = [_]u8{0} ** MAX_PATTERN_LENGTH;
    for (0..text_length) |index| {
        const value = input[2 + index];
        if (value < 0 or value > 3) return -1;
        text[index] = @intCast(value);
    }
    const pattern_offset = 2 + text_length;
    for (0..pattern_length) |index| {
        const value = input[pattern_offset + index];
        if (value < 0 or value > 3) return -1;
        pattern[index] = @intCast(value);
    }

    var kmp_next = [_]i64{0} ** (MAX_PATTERN_LENGTH + 1);
    buildKmpNext(pattern[0..], pattern_length, &kmp_next);

    var ell: usize = 1;
    while (ell < pattern_length and pattern[ell - 1] == pattern[ell]) : (ell += 1) {}
    if (ell == pattern_length) ell = 0;

    var match_count: i64 = 0;
    var sum_offsets: i64 = 0;
    var xor_offsets: i64 = 0;
    if (text_length >= pattern_length) {
        var i = ell;
        var j: usize = 0;
        var k: usize = 0;
        while (j <= text_length - pattern_length) {
            while (i < pattern_length and pattern[i] == text[j + i]) : (i += 1) {}
            if (i >= pattern_length) {
                while (k < ell and pattern[k] == text[j + k]) : (k += 1) {}
                if (k >= ell) {
                    match_count += 1;
                    sum_offsets += @intCast(j);
                    xor_offsets ^= @intCast(j);
                }
            }

            j += @intCast(@as(i64, @intCast(i)) - kmp_next[i]);
            if (i == ell) {
                if (k > 0) k -= 1;
            } else if (kmp_next[i] <= @as(i64, @intCast(ell))) {
                k = if (kmp_next[i] > 0) @intCast(kmp_next[i]) else 0;
                i = ell;
            } else {
                k = ell;
                i = @intCast(kmp_next[i]);
            }
        }
    }

    return (match_count << 36) | (sum_offsets << 12) | xor_offsets;
}
