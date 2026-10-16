const max_limit: usize = 1_000_000;
const odd_slots: usize = max_limit / 2 + 1;

pub export fn problem35(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var odd_prime: [odd_slots]bool = @splat(false);
    for (1..odd_slots) |index| odd_prime[index] = true;

    var candidate: usize = 3;
    while (candidate <= max_limit / candidate) : (candidate += 2) {
        if (odd_prime[candidate / 2]) {
            var composite = candidate * candidate;
            while (composite <= max_limit) : (composite += 2 * candidate) {
                odd_prime[composite / 2] = false;
            }
        }
    }

    var count: i64 = 1;
    var number: usize = 3;
    while (number <= max_limit) : (number += 2) {
        if (!odd_prime[number / 2]) continue;
        var remaining = number;
        var has_even_digit = false;
        while (remaining > 0) {
            if ((remaining % 10) % 2 == 0) {
                has_even_digit = true;
                break;
            }
            remaining /= 10;
        }
        if (has_even_digit) continue;

        var power10: usize = 1;
        var digits: usize = 1;
        remaining = number;
        while (remaining >= 10) {
            power10 *= 10;
            remaining /= 10;
            digits += 1;
        }
        var rotation = number;
        var circular = true;
        for (0..digits) |_| {
            if (!odd_prime[rotation / 2]) {
                circular = false;
                break;
            }
            rotation = (rotation % 10) * power10 + rotation / 10;
        }
        if (circular) count += 1;
    }
    return count;
}
