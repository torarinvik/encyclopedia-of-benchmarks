export fn rescale(input: [*c]const i64, length: usize) i64 {
    const max_draws: i64 = 256;
    const max_input_length: usize = 260;
    if (input == null or length < 3 or length > max_input_length) return -1;
    const max_value = input[0];
    const new_max = input[1];
    const draw_count = input[2];
    if (max_value < 2 or max_value > 64 or new_max < 1 or new_max > 256
        or draw_count < 1 or draw_count > max_draws) return -1;
    if (length != 3 + @as(usize, @intCast(draw_count))) return -1;
    for (0..@as(usize, @intCast(draw_count))) |index| {
        const draw = input[3 + index];
        if (draw < 0 or draw >= max_value) return -1;
    }

    var cursor: usize = 0;
    if (new_max == max_value) return input[3];

    if (new_max < max_value) {
        const threshold = max_value - @mod(max_value, new_max);
        while (cursor < @as(usize, @intCast(draw_count))) : (cursor += 1) {
            const draw = input[3 + cursor];
            if (draw < threshold) return @mod(draw, new_max);
        }
        return -1;
    }

    var result: i64 = 0;
    var power: i64 = 1;
    while (power < new_max) {
        if (cursor >= @as(usize, @intCast(draw_count))) return -1;
        result += power * input[3 + cursor];
        cursor += 1;
        power *= max_value;
    }
    if (power == new_max) return result;

    const threshold = power - @mod(power, new_max);
    while (result >= threshold) {
        result = 0;
        power = 1;
        while (power < new_max) {
            if (cursor >= @as(usize, @intCast(draw_count))) return -1;
            result += power * input[3 + cursor];
            cursor += 1;
            power *= max_value;
        }
    }
    return @mod(result, new_max);
}
