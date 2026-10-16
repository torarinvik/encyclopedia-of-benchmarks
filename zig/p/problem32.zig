fn next_permutation(digits: *[9]i64) bool {
    var pivot: isize = 7;
    while (pivot >= 0 and digits[@intCast(pivot)] >= digits[@intCast(pivot + 1)]) : (pivot -= 1) {}
    if (pivot < 0) return false;
    var successor: usize = 8;
    const pivot_index: usize = @intCast(pivot);
    while (digits[successor] <= digits[pivot_index]) : (successor -= 1) {}
    const temporary = digits[pivot_index];
    digits[pivot_index] = digits[successor];
    digits[successor] = temporary;
    var left: usize = pivot_index + 1;
    var right: usize = 8;
    while (left < right) {
        const value = digits[left];
        digits[left] = digits[right];
        digits[right] = value;
        left += 1;
        right -= 1;
    }
    return true;
}

export fn problem32(ignored: i64) i64 {
    if (ignored != 0) return -1;
    var digits = [9]i64{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    var seen = [_]bool{false} ** 10000;
    var sum: i64 = 0;
    var more = true;
    while (more) {
        const product = digits[5] * 1000 + digits[6] * 100 + digits[7] * 10 + digits[8];
        const two_digit = digits[0] * 10 + digits[1];
        const three_digit = digits[2] * 100 + digits[3] * 10 + digits[4];
        const four_digit = digits[1] * 1000 + digits[2] * 100 + digits[3] * 10 + digits[4];
        if (two_digit * three_digit == product or digits[0] * four_digit == product) {
            const product_index: usize = @intCast(product);
            if (!seen[product_index]) {
                seen[product_index] = true;
                sum += product;
            }
        }
        more = next_permutation(&digits);
    }
    return sum;
}
