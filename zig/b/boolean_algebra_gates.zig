const MAX_INPUT_COUNT: usize = 4096;
const INVALID_RESULT: i64 = -1;

/// Evaluate the pinned Java source's Boolean gates over a flat 0/1 array.
export fn boolean_algebra_gates(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT_COUNT + 2) return INVALID_RESULT;
    const gate = values[0];
    const count = values[1];
    if (gate < 0 or gate > 5 or count < 0 or count > MAX_INPUT_COUNT) return INVALID_RESULT;
    if (@as(usize, @intCast(count)) != length - 2) return INVALID_RESULT;
    if (gate == 2 and count != 1) return INVALID_RESULT;
    var result: i64 = if (gate == 0 or gate == 4) 1 else 0;
    for (0..@as(usize, @intCast(count))) |index| {
        const bit = values[index + 2];
        if (bit != 0 and bit != 1) return INVALID_RESULT;
        if (gate == 0 or gate == 4) result &= bit
        else if (gate == 1 or gate == 5) result |= bit
        else if (gate == 2) result = 1 - bit
        else result ^= bit;
    }
    if (gate == 4 or gate == 5) result = 1 - result;
    return result;
}
