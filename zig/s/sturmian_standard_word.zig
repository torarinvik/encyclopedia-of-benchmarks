const MAX_STEPS: usize = 4;
const MAX_WORD: usize = 41;

pub export fn sturmian_standard_word(values: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > 6) return -1;
    const input = values.?;
    const steps_word = input[0];
    if (steps_word < 0 or steps_word > MAX_STEPS) return -1;
    const steps: usize = @intCast(steps_word);
    if (length != steps + 1) return -1;

    var directives: [MAX_STEPS]i64 = [_]i64{0} ** MAX_STEPS;
    for (0..steps) |i| {
        const repeat = input[i + 1];
        if ((i == 0 and (repeat < 0 or repeat > 2)) or
            (i != 0 and (repeat < 1 or repeat > 2))) return -1;
        directives[i] = repeat;
    }

    var previous: [MAX_WORD]u8 = undefined;
    var current: [MAX_WORD]u8 = undefined;
    var following: [MAX_WORD]u8 = undefined;
    previous[0] = 'b';
    current[0] = 'a';
    var previous_length: usize = 1;
    var current_length: usize = 1;
    for (0..steps) |step| {
        const repeat: usize = @intCast(directives[step]);
        const following_length = current_length * repeat + previous_length;
        var position: usize = 0;
        for (0..repeat) |_| {
            for (0..current_length) |i| {
                following[position] = current[i];
                position += 1;
            }
        }
        for (0..previous_length) |i| {
            following[position] = previous[i];
            position += 1;
        }
        @memcpy(previous[0..current_length], current[0..current_length]);
        @memcpy(current[0..following_length], following[0..following_length]);
        previous_length = current_length;
        current_length = following_length;
    }

    if (output == null or capacity < current_length) return -2;
    @memcpy(output.?[0..current_length], current[0..current_length]);
    return @intCast(current_length);
}
