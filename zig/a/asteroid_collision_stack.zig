const MAX_N: usize = 64;
const MAX_INPUT: usize = 66;

pub export fn asteroid_collision_stack(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length == 0 or length > MAX_INPUT) return -1;
    const values = input.?;
    const n_word = values[0];
    if (n_word < 0 or n_word > MAX_N or length != @as(usize, @intCast(n_word)) + 1) return -1;

    var stack = [_]i8{0} ** MAX_N;
    var top: usize = 0;
    for (0..@intCast(n_word)) |i| {
        const word = values[i + 1];
        if (word == 0 or word < -127 or word > 127) return -1;
        const incoming: i8 = @intCast(word);
        var alive = true;
        while (alive and top > 0 and stack[top - 1] > 0 and incoming < 0) {
            const left_size: i16 = stack[top - 1];
            const right_size: i16 = -@as(i16, incoming);
            if (left_size < right_size) {
                top -= 1;
            } else if (left_size == right_size) {
                top -= 1;
                alive = false;
            } else {
                alive = false;
            }
        }
        if (alive) {
            stack[top] = incoming;
            top += 1;
        }
    }

    const required = top + 1;
    if (output == null or capacity < required) return -2;
    const bytes = output.?;
    bytes[0] = @intCast(top);
    for (0..top) |i| {
        bytes[i + 1] = @truncate(@as(u64, @bitCast(@as(i64, stack[i]))));
    }
    return @intCast(required);
}
