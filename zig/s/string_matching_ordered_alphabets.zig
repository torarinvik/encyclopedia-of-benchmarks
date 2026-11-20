const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;

fn advance_maximal_suffix(input: [*]const i64, base: usize, length: usize,
                          left: *isize, right: *isize, offset: *isize, period: *isize) void {
    while (right.* + offset.* < @as(isize, @intCast(length))) {
        const left_index: usize = @intCast(left.* + offset.*);
        const right_index: usize = @intCast(right.* + offset.*);
        const a = input[base + left_index];
        const b = input[base + right_index];
        if (a == b) {
            if (offset.* == period.*) {
                right.* += period.*;
                offset.* = 1;
            } else {
                offset.* += 1;
            }
        } else if (a > b) {
            right.* += offset.*;
            offset.* = 1;
            period.* = right.* - left.*;
        } else {
            left.* = right.*;
            right.* += 1;
            offset.* = 1;
            period.* = 1;
        }
    }
}

fn prefix_repeats(input: [*]const i64, base: usize, shift: usize, last_index: usize) bool {
    for (0..(last_index + 1)) |q| {
        if (input[base + q] != input[base + shift + q]) return false;
    }
    return true;
}

export fn string_matching_ordered_alphabets(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_TEXT)) or
        input[1] < 1 or input[1] > @as(i64, @intCast(MAX_PATTERN))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + n + m) return -1;
    const pattern_start = 2 + n;
    for (0..n) |q| if (input[2 + q] < 0 or input[2 + q] > 3) return -1;
    for (0..m) |q| if (input[pattern_start + q] < 0 or input[pattern_start + q] > 3) return -1;
    if (n < m) return 0;

    var alignment: isize = 0;
    var matched: isize = 0;
    var suffix_left: isize = -1;
    var suffix_right: isize = 0;
    var suffix_offset: isize = 1;
    var period: isize = 1;
    var count: i64 = 0;
    var offset_sum: i64 = 0;
    var offset_xor: i64 = 0;
    while (alignment <= @as(isize, @intCast(n - m))) {
        while (alignment + matched < @as(isize, @intCast(n)) and matched < @as(isize, @intCast(m)) and
            input[pattern_start + @as(usize, @intCast(matched))] ==
                input[2 + @as(usize, @intCast(alignment + matched))]) : (matched += 1) {}
        if (matched == 0) {
            alignment += 1;
            suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1;
            continue;
        }
        if (matched == @as(isize, @intCast(m))) {
            count += 1;
            offset_sum += @intCast(alignment);
            offset_xor ^= @intCast(alignment);
            if (alignment == @as(isize, @intCast(n - m))) break;
        }

        const base = 2 + @as(usize, @intCast(alignment));
        advance_maximal_suffix(input, base, @as(usize, @intCast(matched + 1)),
                               &suffix_left, &suffix_right, &suffix_offset, &period);
        const reusable = suffix_left < 0 or
            (suffix_left < period and prefix_repeats(input, base, @intCast(period), @intCast(suffix_left)));
        if (reusable) {
            alignment += period;
            matched -= period;
            if (matched < 0) matched = 0;
            if (suffix_right - suffix_left > period) {
                suffix_right -= period;
            } else {
                suffix_left = -1;
                suffix_right = 0;
                suffix_offset = 1;
                period = 1;
            }
        } else {
            const conservative = @min(matched - suffix_left - 1, suffix_right + 1);
            const certified = @max(suffix_left + 1, conservative);
            alignment += certified + 1;
            matched = 0;
            suffix_left = -1; suffix_right = 0; suffix_offset = 1; period = 1;
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
