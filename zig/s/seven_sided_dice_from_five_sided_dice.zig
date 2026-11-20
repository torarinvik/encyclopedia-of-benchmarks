const max_draws: usize = 256;
const max_input_length: usize = max_draws + 2;

export fn seven_sided_dice_from_five_sided_dice(
    input_opt: ?[*]const i64,
    length: usize,
    output_opt: ?[*]u8,
    capacity: usize,
) i64 {
    if (input_opt == null or length < 1 or length > max_input_length) return -1;
    const input = input_opt.?;
    const draw_count_value = input[0];
    if (draw_count_value < 0 or
        draw_count_value > @as(i64, @intCast(max_draws))) return -1;
    const draw_count: usize = @intCast(draw_count_value);
    if (length != draw_count + 1) return -1;
    for (0..draw_count) |index| {
        if (input[index + 1] < 0 or input[index + 1] > 4) return -1;
    }

    var staged: [max_draws]u8 = undefined;
    var written: usize = 0;
    var value: i64 = 0;
    var range: i64 = 1;
    for (0..draw_count) |index| {
        value = 5 * value + input[index + 1];
        range *= 5;
        while (range >= 7) {
            const accepted = range - @rem(range, 7);
            if (value < accepted) {
                staged[written] = @intCast(@rem(value, 7) + 1);
                written += 1;
                value = @divTrunc(value, 7);
                range = @divTrunc(accepted, 7);
            } else {
                value -= accepted;
                range -= accepted;
            }
        }
    }

    if (output_opt == null or capacity < written) return -2;
    const output = output_opt.?;
    for (0..written) |index| output[index] = staged[index];
    return @intCast(written);
}
