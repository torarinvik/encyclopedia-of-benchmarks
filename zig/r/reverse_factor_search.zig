const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT_LENGTH: usize = 4227;
const MAX_STATES: usize = 2 * MAX_PATTERN + 1;

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 0 or n64 > @as(i64, @intCast(MAX_TEXT)) or
        m64 < 1 or m64 > @as(i64, @intCast(MAX_PATTERN))) return null;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (input.len != 2 + n + m) return null;
    var text: [MAX_TEXT]u8 = @splat(0);
    var pattern: [MAX_PATTERN]u8 = @splat(0);
    for (0..n) |q| {
        const value = input[2 + q];
        if (value < 0 or value > 3) return null;
        text[q] = @intCast(value);
    }
    for (0..m) |q| {
        const value = input[2 + n + q];
        if (value < 0 or value > 3) return null;
        pattern[q] = @intCast(value);
    }
    if (n < m) return 0;

    var transitions: [MAX_STATES * 4]i32 = @splat(-1);
    var suffix_link: [MAX_STATES]i32 = @splat(-1);
    var max_length: [MAX_STATES]i32 = @splat(0);
    var terminal: [MAX_STATES]bool = @splat(false);
    var state_count: usize = 1;
    var last: usize = 0;
    for (0..m) |pos| {
        const symbol: usize = @intCast(pattern[m - 1 - pos]);
        const current = state_count;
        state_count += 1;
        max_length[current] = max_length[last] + 1;
        var predecessor: isize = @intCast(last);
        while (predecessor >= 0 and transitions[@as(usize, @intCast(predecessor)) * 4 + symbol] < 0) {
            transitions[@as(usize, @intCast(predecessor)) * 4 + symbol] = @intCast(current);
            predecessor = @intCast(suffix_link[@intCast(predecessor)]);
        }
        if (predecessor < 0) {
            suffix_link[current] = 0;
        } else {
            const pred: usize = @intCast(predecessor);
            const target: usize = @intCast(transitions[pred * 4 + symbol]);
            if (max_length[pred] + 1 == max_length[target]) {
                suffix_link[current] = @intCast(target);
            } else {
                const clone = state_count;
                state_count += 1;
                for (0..4) |column| transitions[clone * 4 + column] = transitions[target * 4 + column];
                max_length[clone] = max_length[pred] + 1;
                suffix_link[clone] = suffix_link[target];
                while (predecessor >= 0 and
                    transitions[@as(usize, @intCast(predecessor)) * 4 + symbol] == @as(i32, @intCast(target))) {
                    transitions[@as(usize, @intCast(predecessor)) * 4 + symbol] = @intCast(clone);
                    predecessor = @intCast(suffix_link[@intCast(predecessor)]);
                }
                suffix_link[target] = @intCast(clone);
                suffix_link[current] = @intCast(clone);
            }
        }
        last = current;
    }
    var terminal_state: isize = @intCast(last);
    while (terminal_state >= 0) {
        terminal[@intCast(terminal_state)] = true;
        terminal_state = @intCast(suffix_link[@intCast(terminal_state)]);
    }

    var count: i64 = 0;
    var offset_sum: i64 = 0;
    var offset_xor: i64 = 0;
    var period: isize = @intCast(m);
    var start: usize = 0;
    while (start <= n - m) {
        var index: isize = @as(isize, @intCast(m)) - 1;
        var state: usize = 0;
        var shift: isize = @intCast(m);
        while (@as(isize, @intCast(start)) + index >= 0) {
            const text_index: usize = @intCast(@as(isize, @intCast(start)) + index);
            const symbol: usize = @intCast(text[text_index]);
            const target = transitions[state * 4 + symbol];
            if (target < 0) break;
            state = @intCast(target);
            if (terminal[state]) {
                period = shift;
                shift = index;
            }
            index -= 1;
        }
        if (index < 0) {
            count += 1;
            offset_sum += @intCast(start);
            offset_xor ^= @intCast(start);
            shift = period;
        }
        start += @intCast(shift);
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}

export fn reverse_factor_search(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
