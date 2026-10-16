const MAX_FACES: i64 = 8;
const MAX_DICE: i64 = 8;
const MAX_TARGET: i64 = 64;

export fn dice_throw(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length != 3) return -1;
    const input = values.?;
    const faces_value = input[0];
    const dice_value = input[1];
    const target_value = input[2];
    if (faces_value < 1 or faces_value > MAX_FACES or dice_value < 1 or dice_value > MAX_DICE or
        target_value < 0 or target_value > MAX_TARGET) return -1;
    const faces: usize = @intCast(faces_value);
    const dice: usize = @intCast(dice_value);
    const target: usize = @intCast(target_value);

    var table: [9][65]i64 = @splat(@splat(0));
    for (1..@min(faces, target) + 1) |total| table[1][total] = 1;
    for (2..dice + 1) |die| {
        for (1..target + 1) |total| {
            for (1..@min(total - 1, faces) + 1) |face| {
                table[die][total] += table[die - 1][total - face];
            }
        }
    }
    return table[dice][target];
}
