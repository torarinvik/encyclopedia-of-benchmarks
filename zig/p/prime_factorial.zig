const MAX_INPUT: i64 = 4096;
const MAX_DISTINCT_FACTORS = 5;

fn isPrimeBySourceTrialDivision(candidate: i64) bool {
    if (candidate == 2) return true;
    const half_candidate = @divTrunc(candidate, 2) + 1;
    var divisor: i64 = 2;
    while (divisor <= half_candidate) : (divisor += 1) {
        if (@rem(candidate, divisor) == 0) return false;
        if (divisor == half_candidate) return true;
    }
    return false;
}

export fn prime_factorial(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 2 or value > MAX_INPUT) return -1;
    var factors: [MAX_DISTINCT_FACTORS]u32 = undefined;
    var count: usize = 0;
    var candidate: i64 = 2;
    while (candidate <= value) : (candidate += 1) {
        if (isPrimeBySourceTrialDivision(candidate) and @rem(value, candidate) == 0) {
            factors[count] = @intCast(candidate);
            count += 1;
        }
    }
    const required = count * 4;
    if (output_capacity < required) return -2;
    var position: usize = 0;
    for (factors[0..count]) |factor| {
        for (0..4) |byte_index| {
            const shift: u5 = @intCast(byte_index * 8);
            output[position] = @truncate(factor >> shift);
            position += 1;
        }
    }
    return @intCast(position);
}
