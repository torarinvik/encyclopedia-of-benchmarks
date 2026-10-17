const MAX_STAGE_COUNT: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_STAGE_COUNT;

export fn pipeline(values: ?[*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    if (values == null) return -1;

    const items = values.?;
    const initial = items[0];
    const stage_count = items[1];
    if (initial < 0 or initial > 2 or stage_count < 1 or stage_count > MAX_STAGE_COUNT) return -1;
    if (length != 2 + 2 * @as(usize, @intCast(stage_count))) return -1;

    var result = initial;
    for (0..@as(usize, @intCast(stage_count))) |index| {
        const operation = items[2 + 2 * index];
        const argument = items[3 + 2 * index];
        if (argument < 0 or argument > 2) return -1;
        if (operation == 0) {
            result += argument;
        } else if (operation == 1) {
            result *= argument;
        } else return -1;
    }
    return result;
}
