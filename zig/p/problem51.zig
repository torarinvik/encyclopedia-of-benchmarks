const PRIME_LIMIT: usize = 1_000_000;
const PRIME: u8 = 1;
const FILTERED_PRIME: u8 = 2;
const FILTERED_CHECKED: u8 = 3;
const CHECKED_NONPRIME: u8 = 4;
const CHECKED_OTHER_PRIME: u8 = 5;

fn repeatedExtraDigits(value: i64) usize {
    var counts = [_]usize{0} ** 10;
    var length: usize = 0;
    var remaining = value;
    while (remaining > 0) {
        counts[@intCast(@mod(remaining, 10))] += 1;
        length += 1;
        remaining = @divTrunc(remaining, 10);
    }
    var distinct: usize = 0;
    for (counts) |count| {
        if (count > 0) distinct += 1;
    }
    return length - distinct;
}

fn countDigit(value: i64, digit: i64) usize {
    var count: usize = 0;
    var remaining = value;
    while (remaining > 0) {
        if (@mod(remaining, 10) == digit) count += 1;
        remaining = @divTrunc(remaining, 10);
    }
    return count;
}

fn replaceAll(value: i64, digit: i64, replacement: i64) i64 {
    var result = value;
    var remaining = value;
    var place: i64 = 1;
    while (remaining > 0) {
        if (@mod(remaining, 10) == digit) result += (replacement - digit) * place;
        remaining = @divTrunc(remaining, 10);
        place *= 10;
    }
    return result;
}

pub export fn problem51(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var state: [PRIME_LIMIT]u8 = @splat(0);
    for (2..PRIME_LIMIT) |value| {
        state[value] = PRIME;
    }
    var prime_value: usize = 2;
    while (prime_value * prime_value < PRIME_LIMIT) : (prime_value += 1) {
        if (state[prime_value] != PRIME) continue;
        var multiple = prime_value * prime_value;
        while (multiple < PRIME_LIMIT) : (multiple += prime_value) {
            state[multiple] = 0;
        }
    }
    for (2..PRIME_LIMIT) |value| {
        if (state[value] == PRIME and repeatedExtraDigits(@intCast(value)) >= 3) {
            state[value] = FILTERED_PRIME;
        }
    }
    var number: usize = 2;
    while (number < PRIME_LIMIT) : (number += 1) {
        if (state[number] != FILTERED_PRIME) continue;
        const value: i64 = @intCast(number);
        var place: i64 = 1;
        while (@divTrunc(value, place) >= 10) : (place *= 10) {}
        var seen_digits = [_]bool{false} ** 10;
        while (place > 0) : (place = @divTrunc(place, 10)) {
            const digit: usize = @intCast(@mod(@divTrunc(value, place), 10));
            if (seen_digits[digit] or countDigit(value, @intCast(digit)) < 2) continue;
            seen_digits[digit] = true;
            var family_count: usize = 0;
            var family_minimum: i64 = 9223372036854775807;
            var replacement: i64 = 0;
            while (replacement <= 9) : (replacement += 1) {
                const member = replaceAll(value, @intCast(digit), replacement);
                const member_index: usize = @intCast(member);
                if (state[member_index] == FILTERED_PRIME) {
                    state[member_index] = FILTERED_CHECKED;
                } else if (state[member_index] == 0) {
                    state[member_index] = CHECKED_NONPRIME;
                } else if (state[member_index] == PRIME) {
                    state[member_index] = CHECKED_OTHER_PRIME;
                }
                if (state[member_index] == FILTERED_PRIME or state[member_index] == FILTERED_CHECKED) {
                    family_count += 1;
                    if (member < family_minimum) family_minimum = member;
                }
            }
            if (family_count == 8) return family_minimum;
        }
    }
    return -1;
}
