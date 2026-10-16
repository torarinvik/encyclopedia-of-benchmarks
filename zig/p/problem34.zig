const DIGIT_FACTORIALS = [_]i64{ 1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880 };

pub export fn problem34(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var total: i64 = 0;
    var number: i64 = 3;
    while (number <= 2_540_160) : (number += 1) {
        var remaining = number;
        var digit_sum: i64 = 0;
        while (remaining > 0) {
            digit_sum += DIGIT_FACTORIALS[@intCast(remaining % 10)];
            remaining /= 10;
        }
        if (digit_sum == number) total += number;
    }
    return total;
}
