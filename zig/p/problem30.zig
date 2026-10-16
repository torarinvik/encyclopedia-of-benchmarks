fn digitFifthPower(digit: i64) i64 {
    return digit * digit * digit * digit * digit;
}

pub export fn problem30(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var total: i64 = 0;
    var number: i64 = 1_000;
    while (number < 1_000_000) : (number += 1) {
        var remaining = number;
        var digit_sum: i64 = 0;
        while (remaining > 0) {
            digit_sum += digitFifthPower(remaining % 10);
            remaining /= 10;
        }
        if (digit_sum == number) total += number;
    }
    return total;
}
