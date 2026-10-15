const MAX_INPUT: i64 = 67_108_863;

fn highestPowerPosition(value: i64) u6 {
    var position: u6 = 0;
    var power: i64 = 1;
    while (power <= @divTrunc(value, 2)) {
        power *= 2;
        position += 1;
    }
    return position;
}

fn countSetBitsRecursive(value: i64) i64 {
    if (value == 0) return 0;
    const position = highestPowerPosition(value);
    const power: i64 = @as(i64, 1) << position;
    const bits_at_position: i64 = if (position == 0) 0 else @as(i64, @intCast(position)) * @divTrunc(power, 2);
    const remaining_numbers = value - power + 1;
    return bits_at_position + remaining_numbers + countSetBitsRecursive(value - power);
}

/// Count set bits across every integer from 1 through value, inclusive.
export fn count_set_bits(value: i64) i64 {
    if (value < 0 or value > MAX_INPUT) return -1;
    return countSetBitsRecursive(value);
}
