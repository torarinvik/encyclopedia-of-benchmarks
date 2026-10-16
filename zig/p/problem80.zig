const LIMBS = 16;
const BASE: u64 = 1_000_000_000;
const Big = [LIMBS]u64;
fn mulAdd(src: *const Big, factor: u64, add: u64, dst: *Big) void {
    var carry = add;
    for (0..LIMBS) |i| { const value = src[i] * factor + carry; dst[i] = value % BASE; carry = value / BASE; }
}
fn ge(left: *const Big, right: *const Big) bool {
    var i = LIMBS;
    while (i > 0) { i -= 1; if (left[i] != right[i]) return left[i] > right[i]; }
    return true;
}
fn subtract(left: *Big, right: *const Big) void {
    var borrow: u64 = 0;
    for (0..LIMBS) |i| { const amount = right[i] + borrow; if (left[i] < amount) { left[i] = left[i] + BASE - amount; borrow = 1; } else { left[i] -= amount; borrow = 0; } }
}
export fn problem80(placeholder: i64) i64 {
    if (placeholder != 0) return -1;
    var answer: i64 = 0;
    for (2..100) |number_index| {
        const number: u64 = @intCast(number_index);
        var integer_root: u64 = 0;
        while ((integer_root + 1) * (integer_root + 1) <= number) : (integer_root += 1) {}
        if (integer_root * integer_root == number) continue;
        var root: Big = @splat(0); var remainder: Big = @splat(0); var scaled: Big = @splat(0); var trial: Big = @splat(0);
        var digit_sum: i64 = 0;
        for (0..100) |step| {
            mulAdd(&remainder, 100, if (step == 0) number else 0, &remainder);
            var digit: i64 = 9;
            while (digit >= 0) : (digit -= 1) { mulAdd(&root, 20, @intCast(digit), &scaled); mulAdd(&scaled, @intCast(digit), 0, &trial); if (ge(&remainder, &trial)) break; }
            subtract(&remainder, &trial);
            mulAdd(&root, 10, @intCast(digit), &root);
            digit_sum += digit;
        }
        answer += digit_sum;
    }
    return answer;
}
