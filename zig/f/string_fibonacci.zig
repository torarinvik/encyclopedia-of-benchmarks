const MAX_N: i64 = 256;
const DECIMAL_CAPACITY: usize = 80;

fn addDecimal(
    left: *const [DECIMAL_CAPACITY]u8,
    leftLength: usize,
    right: *const [DECIMAL_CAPACITY]u8,
    rightLength: usize,
    result: *[DECIMAL_CAPACITY]u8,
) usize {
    var reversed: [DECIMAL_CAPACITY]u8 = undefined;
    var leftRemaining = leftLength;
    var rightRemaining = rightLength;
    var length: usize = 0;
    var carry: u8 = 0;
    while (leftRemaining > 0 or rightRemaining > 0 or carry != 0) {
        const leftDigit: u8 = if (leftRemaining > 0) blk: {
            leftRemaining -= 1;
            break :blk left.*[leftRemaining] - '0';
        } else 0;
        const rightDigit: u8 = if (rightRemaining > 0) blk: {
            rightRemaining -= 1;
            break :blk right.*[rightRemaining] - '0';
        } else 0;
        const sum: u16 = @as(u16, leftDigit) + @as(u16, rightDigit) + @as(u16, carry);
        reversed[length] = '0' + @as(u8, @intCast(sum % 10));
        length += 1;
        carry = @intCast(sum / 10);
    }
    for (0..length) |i| result.*[i] = reversed[length - 1 - i];
    result.*[length] = 0;
    return length;
}

export fn string_fibonacci(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length != 1) return -1;
    const input_ptr = input.?;
    const n = input_ptr[0];
    if (n < 0 or n > MAX_N) return -1;

    var fib_minus_one: [DECIMAL_CAPACITY]u8 = undefined;
    var fib_minus_two: [DECIMAL_CAPACITY]u8 = undefined;
    fib_minus_one[0] = '1';
    fib_minus_two[0] = '0';
    var minus_one_length: usize = 1;
    var minus_two_length: usize = 1;
    for (0..@intCast(n)) |_| {
        var sum: [DECIMAL_CAPACITY]u8 = undefined;
        const sum_length = addDecimal(&fib_minus_one, minus_one_length,
            &fib_minus_two, minus_two_length, &sum);
        for (0..minus_one_length) |i| fib_minus_two[i] = fib_minus_one[i];
        minus_two_length = minus_one_length;
        for (0..sum_length) |i| fib_minus_one[i] = sum[i];
        fib_minus_one[sum_length] = 0;
        minus_one_length = sum_length;
    }

    if (output == null or capacity < minus_two_length) return -2;
    const output_ptr = output.?;
    for (0..minus_two_length) |i| output_ptr[i] = fib_minus_two[i];
    return @intCast(minus_two_length);
}
