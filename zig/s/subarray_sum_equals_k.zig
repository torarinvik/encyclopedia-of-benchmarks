const INVALID_RESULT: i64 = -9223372036854775807 - 1;
const MAX_ITEMS: usize = 512;
const TABLE_SIZE: usize = 2048;

fn slot_for(value: i64) usize {
    const magnitude = if (value < 0) -value else value;
    return @intCast(@rem(magnitude, 2048));
}

pub export fn subarray_sum_equals_k(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_ITEMS + 2) return INVALID_RESULT;
    const count_value = input[0];
    const target = input[1];
    if (count_value < 0 or count_value > 512 or target < -2147483648 or target > 2147483647) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    if (length != count + 2) return INVALID_RESULT;
    for (0..count) |index| {
        const value = input[index + 2];
        if (value < -2147483648 or value > 2147483647) return INVALID_RESULT;
    }

    var keys: [TABLE_SIZE]i64 = @splat(0);
    var frequencies: [TABLE_SIZE]i64 = @splat(0);
    frequencies[0] = 1;
    var prefix_sum: i64 = 0;
    var result: i64 = 0;
    for (0..count) |index| {
        prefix_sum += input[index + 2];
        const required = prefix_sum - target;
        var slot = slot_for(required);
        while (frequencies[slot] != 0 and keys[slot] != required) slot = (slot + 1) % TABLE_SIZE;
        result += frequencies[slot];

        slot = slot_for(prefix_sum);
        while (frequencies[slot] != 0 and keys[slot] != prefix_sum) slot = (slot + 1) % TABLE_SIZE;
        if (frequencies[slot] == 0) keys[slot] = prefix_sum;
        frequencies[slot] += 1;
    }
    return result;
}
