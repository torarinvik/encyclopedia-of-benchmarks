/// Direct permutation port of TheAlgorithms/Python Project Euler 43.
fn nextPermutation(digits: *[10]i64) bool {
    var i: isize = 8;
    while (i >= 0 and digits[@intCast(i)] >= digits[@intCast(i + 1)])) : (i -= 1) {}
    if (i < 0) return false;
    const ui: usize = @intCast(i);
    var j: usize = 9;
    while (digits[j] <= digits[ui]) : (j -= 1) {}
    const temp = digits[ui]; digits[ui] = digits[j]; digits[j] = temp;
    var left = ui + 1; var right: usize = 9;
    while (left < right) : ({ left += 1; right -= 1; }) { const swap = digits[left]; digits[left] = digits[right]; digits[right] = swap; }
    return true;
}

export fn problem43(n: i64) i64 {
    if (n != 10) return -1;
    var digits = [10]i64{0,1,2,3,4,5,6,7,8,9};
    const divisors = [4]i64{7,11,13,17};
    var total: i64 = 0;
    var more = true;
    while (more) {
        if (@rem(digits[3],2) == 0 and @rem(digits[2]+digits[3]+digits[4],3) == 0 and @rem(digits[5],5) == 0) {
            var valid = true;
            for (0..4) |index| if (@rem(digits[index+4]*100+digits[index+5]*10+digits[index+6],divisors[index]) != 0) { valid = false; };
            if (valid) { var value: i64 = 0; for (digits) |digit| value = value*10+digit; total += value; }
        }
        more = nextPermutation(&digits);
    }
    return total;
}
