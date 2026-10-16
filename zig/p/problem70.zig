const MAX_N: i64 = 10_000_000;
const PRIME_LIMIT: usize = 3162;
const PRIME_CAPACITY: usize = 500;
const SEGMENT_SIZE: usize = 32768;

fn sameDigits(left_value: u32, right_value: u32) bool {
    var counts = [_]i32{0} ** 10;
    var left = left_value;
    while (left != 0) {
        counts[@intCast(left % 10)] += 1;
        left /= 10;
    }
    var right = right_value;
    while (right != 0) {
        counts[@intCast(right % 10)] -= 1;
        right /= 10;
    }
    for (counts) |count| if (count != 0) return false;
    return true;
}

pub export fn problem70(max_n: i64) i64 {
    if (max_n < 0 or max_n > MAX_N) return -1;
    const limit: u32 = @intCast(max_n);
    var prime_flags = [_]bool{false} ** (PRIME_LIMIT + 1);
    var primes: [PRIME_CAPACITY]u32 = undefined;
    var prime_count: usize = 0;
    var value: usize = 2;
    while (value <= PRIME_LIMIT and value <= @as(usize, limit) / value) : (value += 1) {
        prime_flags[value] = true;
    }
    var prime: usize = 2;
    while (prime <= PRIME_LIMIT and prime <= @as(usize, limit) / prime) : (prime += 1) {
        if (!prime_flags[prime]) continue;
        var multiple = prime * prime;
        while (multiple <= PRIME_LIMIT and multiple <= @as(usize, limit) / multiple) : (multiple += prime) {
            prime_flags[multiple] = false;
        }
    }
    value = 2;
    while (value <= PRIME_LIMIT and value <= @as(usize, limit) / value) : (value += 1) {
        if (prime_flags[value]) {
            primes[prime_count] = @intCast(value);
            prime_count += 1;
        }
    }

    var phi: [SEGMENT_SIZE]u32 = undefined;
    var remainder: [SEGMENT_SIZE]u32 = undefined;
    var best_n: u32 = 1;
    var best_phi: u32 = 0;
    var low: u32 = 0;
    while (low <= limit) {
        var high = low + @as(u32, @intCast(SEGMENT_SIZE)) - 1;
        if (high < low or high > limit) high = limit;
        const length: usize = @intCast(high - low + 1);
        for (0..length) |offset| {
            phi[offset] = low + @as(u32, @intCast(offset));
            remainder[offset] = low + @as(u32, @intCast(offset));
        }
        for (primes[0..prime_count]) |factor| {
            var first = low + (factor - @rem(low, factor)) % factor;
            if (first < factor) first = factor;
            var multiple = first;
            while (multiple <= high) {
                const offset: usize = @intCast(multiple - low);
                phi[offset] -= phi[offset] / factor;
                while (@rem(remainder[offset], factor) == 0) remainder[offset] /= factor;
                if (high - multiple < factor) break;
                multiple += factor;
            }
        }
        for (0..length) |offset| {
            if (remainder[offset] > 1) phi[offset] -= phi[offset] / remainder[offset];
            const number = low + @as(u32, @intCast(offset));
            if (number >= 2
                and @as(u64, number) * best_phi < @as(u64, best_n) * phi[offset]
                and sameDigits(number, phi[offset]))
            {
                best_n = number;
                best_phi = phi[offset];
            }
        }
        if (high == limit) break;
        low = high + 1;
    }
    return @intCast(best_n);
}
