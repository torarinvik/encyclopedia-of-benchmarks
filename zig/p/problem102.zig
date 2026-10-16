/// Count triangles whose strict interior contains the origin.
const MAX_VALUES: usize = 6_000;
const MIN_COORD: i64 = -1_000;
const MAX_COORD: i64 = 1_000;

fn originInside(x1: i64, y1: i64, x2: i64, y2: i64, x3: i64, y3: i64) i64 {
    const abx = x2 - x1;
    const aby = y2 - y1;
    const acx = x3 - x1;
    const acy = y3 - y1;
    var denominator = acx * aby - acy * abx;
    var numerator_a = -(x1 * aby - y1 * abx);
    var numerator_b = x1 * acy - y1 * acx;
    if (denominator == 0) return -1;
    if (denominator < 0) {
        denominator = -denominator;
        numerator_a = -numerator_a;
        numerator_b = -numerator_b;
    }
    return if (numerator_a > 0 and numerator_b > 0 and numerator_a + numerator_b < denominator) 1 else 0;
}

pub export fn problem102(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 6 or length > MAX_VALUES or length % 6 != 0) return -1;
    for (0..length) |index| {
        if (input[index] < MIN_COORD or input[index] > MAX_COORD) return -1;
    }
    var count: i64 = 0;
    var offset: usize = 0;
    while (offset < length) : (offset += 6) {
        const inside = originInside(
            input[offset], input[offset + 1], input[offset + 2],
            input[offset + 3], input[offset + 4], input[offset + 5],
        );
        if (inside < 0) return -1;
        count += inside;
    }
    return count;
}
