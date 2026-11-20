const MAX_LIMIT: i64 = 100_000;
const MAX_QUEUE: usize = 70_000;

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    if (@rem(value, 2) == 0) return value == 2;
    var divisor: i64 = 3;
    while (divisor * divisor <= value) : (divisor += 2) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn search(base: i64, digits: i64) i64 {
    var queue: [MAX_QUEUE]i64 = @splat(0);
    var end: usize = 0;
    var value: i64 = 2;
    while (value < base) : (value += 1) {
        if (isPrime(value)) {
            queue[end] = value;
            end += 1;
        }
    }
    var best = queue[end - 1];
    var level_start: usize = 0;
    var level_end = end;
    var place = base;
    var width: i64 = 1;
    while (width < digits and level_start < level_end) : (width += 1) {
        for (level_start..level_end) |index| {
            const suffix = queue[index];
            var leading: i64 = 1;
            while (leading < base) : (leading += 1) {
                const candidate = leading * place + suffix;
                if (isPrime(candidate)) {
                    if (end >= MAX_QUEUE) return -1;
                    queue[end] = candidate;
                    end += 1;
                    if (candidate > best) best = candidate;
                }
            }
        }
        level_start = level_end;
        level_end = end;
        place *= base;
    }
    return best;
}

export fn left_truncatable_prime_search(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 3) return -1;
    const values = input.?[0..length];
    const base = values[0];
    const digits = values[1];
    if (length != 2 or base < 3 or base > 16 or digits < 1 or digits > 10) return -1;
    var limit: i64 = 1;
    var step: i64 = 0;
    while (step < digits) : (step += 1) limit *= base;
    if (limit > MAX_LIMIT) return -1;
    return search(base, digits);
}
