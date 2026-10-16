const MAX_LIMIT: i64 = 100_000_000;
const HASH_CAPACITY: usize = 32768;
const HASH_MASK: usize = HASH_CAPACITY - 1;

fn isPalindrome(value: i64) bool {
    if (@mod(value, 10) == 0) return false;
    const original = value;
    var remaining = value;
    var reversed: i64 = 0;
    while (remaining > 0) {
        reversed = reversed * 10 + @mod(remaining, 10);
        remaining = @divTrunc(remaining, 10);
    }
    return original == reversed;
}

fn insertUnique(seen: *[HASH_CAPACITY]i64, value: i64) bool {
    var slot: usize = @intCast(((@as(u64, @intCast(value)) * 2_654_435_761) >> 17) & @as(u64, HASH_MASK));
    while (seen[slot] != 0 and seen[slot] != value) slot = (slot + 1) & HASH_MASK;
    if (seen[slot] == value) return false;
    seen[slot] = value;
    return true;
}

pub export fn problem125(limit: i64) i64 {
    if (limit < 0 or limit > MAX_LIMIT) return -1;
    var seen = [_]i64{0} ** HASH_CAPACITY;
    var total: i64 = 0;
    var first: i64 = 1;
    while (true) : (first += 1) {
        var last = first + 1;
        var sum = first * first + last * last;
        if (sum >= limit) break;
        while (sum < limit) {
            if (isPalindrome(sum) and insertUnique(&seen, sum)) total += sum;
            last += 1;
            sum += last * last;
        }
    }
    return total;
}
