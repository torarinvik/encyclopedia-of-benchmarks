const MAX_SIZE: usize = 1024;
const INVALID: i64 = -2_147_483_649;

fn swapValues(values: *[MAX_SIZE]i32, left: usize, right: usize) void {
    const temporary = values[left];
    values[left] = values[right];
    values[right] = temporary;
}

fn selectBfprt(values: *[MAX_SIZE]i32, left_value: usize, right_value: usize, rank: usize) i32 {
    var left = left_value;
    var right = right_value;
    while (left < right) {
        const count = right - left + 1;
        const groups = (count + 4) / 5;
        for (0..groups) |group| {
            const group_left = left + group * 5;
            const group_right = @min(right, group_left + 4);
            for ((group_left + 1)..(group_right + 1)) |index| {
                var cursor = index;
                while (cursor > group_left and values[cursor - 1] > values[cursor]) {
                    swapValues(values, cursor - 1, cursor);
                    cursor -= 1;
                }
            }
            const median = group_left + (group_right - group_left + 1) / 2;
            swapValues(values, left + group, median);
        }

        var pivot = values[left];
        if (groups > 1) pivot = selectBfprt(values, left, left + groups - 1, left + groups / 2);
        var less = left;
        var current = left;
        var greater = right + 1;
        while (current < greater) {
            if (values[current] < pivot) {
                swapValues(values, less, current);
                less += 1;
                current += 1;
            } else if (values[current] > pivot) {
                greater -= 1;
                swapValues(values, current, greater);
            } else {
                current += 1;
            }
        }
        if (rank < less) {
            right = less - 1;
        } else if (rank >= greater) {
            left = greater;
        } else {
            return values[rank];
        }
    }
    return values[left];
}

/// Return the one-based kth-smallest signed 32-bit value, or INVALID.
export fn bfprt(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2) return INVALID;
    const count_value = input[0];
    const rank_value = input[1];
    if (count_value < 1 or count_value > @as(i64, @intCast(MAX_SIZE))) return INVALID;
    const count: usize = @intCast(count_value);
    if (length != count + 2 or rank_value < 1 or rank_value > count_value) return INVALID;

    var values: [MAX_SIZE]i32 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 2];
        if (value < -2_147_483_648 or value > 2_147_483_647) return INVALID;
        values[index] = @intCast(value);
    }
    return @intCast(selectBfprt(&values, 0, count - 1, @intCast(rank_value - 1)));
}
