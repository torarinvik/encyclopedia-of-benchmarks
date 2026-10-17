const MAX_INPUT_LENGTH: usize = 2;

fn isPalindromic(value: u32) bool {
    var remaining = value;
    var reversed: u32 = 0;
    while (remaining > 0) {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
    }
    return reversed == value;
}

export fn euler_problem_4(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 3 or length != 1) return -1;
    const digits: u32 = @intCast(input[0]);
    var lower: u32 = 1;
    var digit: u32 = 1;
    while (digit < digits) : (digit += 1) lower *= 10;
    const upper = lower * 10 - 1;
    var maximum: u32 = 0;
    var left = lower;
    while (left <= upper) : (left += 1) {
        var right = lower;
        while (right <= upper) : (right += 1) {
            const product = left * right;
            if (product > maximum and isPalindromic(product)) maximum = product;
        }
    }
    return @intCast(maximum);
}
