const MAX_TERM_LENGTH: usize = 256;

export fn count_and_say(term_index: i64, output: [*]u8,
    output_capacity: usize) i64 {
    if (term_index < 1 or term_index > 19) return -1;
    var current: [MAX_TERM_LENGTH]u8 = [_]u8{0} ** MAX_TERM_LENGTH;
    var next: [MAX_TERM_LENGTH]u8 = [_]u8{0} ** MAX_TERM_LENGTH;
    var current_length: usize = 1;
    current[0] = '1';
    var term: i64 = 1;
    while (term < term_index) : (term += 1) {
        var next_length: usize = 0;
        var index: usize = 0;
        while (index < current_length) {
            var end = index + 1;
            while (end < current_length and current[end] == current[index]) : (end += 1) {}
            const run_length = end - index;
            if (next_length + 2 > MAX_TERM_LENGTH) return -1;
            next[next_length] = '0' + @as(u8, @intCast(run_length));
            next[next_length + 1] = current[index];
            next_length += 2;
            index = end;
        }
        @memcpy(current[0..next_length], next[0..next_length]);
        current_length = next_length;
    }
    if (output_capacity < current_length) return -2;
    for (0..current_length) |index| output[index] = current[index];
    return @intCast(current_length);
}
