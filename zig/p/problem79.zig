const LOGINS = [_]i64{
    319, 680, 180, 690, 129, 620, 762, 689, 762, 318,
    368, 710, 720, 710, 629, 168, 160, 689, 716, 731,
    736, 729, 316, 729, 729, 710, 769, 290, 719, 680,
    318, 389, 162, 289, 162, 718, 729, 319, 790, 680,
    890, 362, 319, 760, 316, 729, 380, 319, 728, 716,
};

fn nextPermutation(digits: *[10]i64, length: usize) bool {
    var pivot: isize = @as(isize, @intCast(length)) - 2;
    while (pivot >= 0 and digits[@intCast(pivot)] >= digits[@intCast(pivot + 1)]) : (pivot -= 1) {}
    if (pivot < 0) return false;
    var successor = length - 1;
    while (digits[successor] <= digits[@intCast(pivot)]) : (successor -= 1) {}
    const temp = digits[@intCast(pivot)];
    digits[@intCast(pivot)] = digits[successor];
    digits[successor] = temp;
    var left: usize = @intCast(pivot + 1);
    var right = length - 1;
    while (left < right) {
        const value = digits[left]; digits[left] = digits[right]; digits[right] = value;
        left += 1;
        right -= 1;
    }
    return true;
}

export fn problem79(placeholder: i64) i64 {
    if (placeholder != 0) return -1;
    var present = [_]bool{false} ** 10;
    for (LOGINS) |login| {
        present[@intCast(@divTrunc(login, 100))] = true;
        present[@intCast(@mod(@divTrunc(login, 10), 10))] = true;
        present[@intCast(@mod(login, 10))] = true;
    }
    var digits = [_]i64{0} ** 10;
    var length: usize = 0;
    for (0..10) |digit| {
        if (present[digit]) { digits[length] = @intCast(digit); length += 1; }
    }
    while (true) {
        var positions = [_]i64{-1} ** 10;
        for (0..length) |index| positions[@intCast(digits[index])] = @intCast(index);
        var satisfied = true;
        for (LOGINS) |login| {
            const first: usize = @intCast(@divTrunc(login, 100));
            const second: usize = @intCast(@mod(@divTrunc(login, 10), 10));
            const third: usize = @intCast(@mod(login, 10));
            if (!(positions[first] < positions[second] and positions[second] < positions[third])) { satisfied = false; break; }
        }
        if (satisfied) {
            var passcode: i64 = 0;
            for (0..length) |index| passcode = passcode * 10 + digits[index];
            return passcode;
        }
        if (!nextPermutation(&digits, length)) break;
    }
    return -1;
}
