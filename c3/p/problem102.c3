// Count triangles whose strict interior contains the origin.
module problem102;

const usz MAX_VALUES = 6000;
const long MIN_COORD = -1000;
const long MAX_COORD = 1000;

fn long origin_inside(long x1, long y1, long x2, long y2, long x3, long y3) {
    long abx = x2 - x1, aby = y2 - y1;
    long acx = x3 - x1, acy = y3 - y1;
    long denominator = acx * aby - acy * abx;
    long numerator_a = -(x1 * aby - y1 * abx);
    long numerator_b = x1 * acy - y1 * acx;
    if (denominator == 0) return -1;
    if (denominator < 0) {
        denominator = -denominator;
        numerator_a = -numerator_a;
        numerator_b = -numerator_b;
    }
    return numerator_a > 0 && numerator_b > 0 && numerator_a + numerator_b < denominator;
}

fn long problem102(long* input, usz length) @export("problem102") {
    if (input == null || length < 6 || length > MAX_VALUES || length % 6 != 0) return -1;
    for (usz index = 0; index < length; index++)
        if (input[index] < MIN_COORD || input[index] > MAX_COORD) return -1;
    long count = 0;
    for (usz offset = 0; offset < length; offset += 6) {
        long inside = origin_inside(input[offset], input[offset + 1], input[offset + 2],
                                    input[offset + 3], input[offset + 4], input[offset + 5]);
        if (inside < 0) return -1;
        count += inside;
    }
    return count;
}
