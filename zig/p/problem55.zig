const MAX_LIMIT: i64 = 10_000;
const MAX_DIGITS: usize = 64;

fn reverse_add(digits: *[MAX_DIGITS]u8, length: usize) usize {
    var reverse_length = length;
    while (reverse_length > 0 and digits[length - reverse_length] == 0) : (reverse_length -= 1) {}
    const combined_length = @max(length, reverse_length);
    var next = [_]u8{0} ** MAX_DIGITS;
    var carry: u8 = 0;
    for (0..combined_length) |position| {
        const left = if (position < length) digits[position] else 0;
        const right = if (position < reverse_length) digits[length - 1 - position] else 0;
        const sum: u8 = left + right + carry;
        next[position] = sum % 10;
        carry = sum / 10;
    }
    var next_length = combined_length;
    if (carry > 0) {
        next[next_length] = carry;
        next_length += 1;
    }
    for (0..next_length) |index| digits[index] = next[index];
    return next_length;
}

fn is_palindrome(digits: *const [MAX_DIGITS]u8, length: usize) bool {
    for (0..length / 2) |left| {
        if (digits[left] != digits[length - 1 - left]) return false;
    }
    return true;
}

export fn problem55(limit: i64) i64 {
    if (limit < 0 or limit > MAX_LIMIT) return -1;
    var count: i64 = 0;
    var start: i64 = 1;
    while (start < limit) : (start += 1) {
        var digits = [_]u8{0} ** MAX_DIGITS;
        var length: usize = 0;
        var value: u64 = @intCast(start);
        while (value > 0) {
            digits[length] = @intCast(value % 10);
            length += 1;
            value /= 10;
        }
        var became_palindrome = false;
        for (0..50) |_| {
            length = reverse_add(&digits, length);
            if (is_palindrome(&digits, length)) {
                became_palindrome = true;
                break;
            }
        }
        if (!became_palindrome) count += 1;
    }
    return count;
}
