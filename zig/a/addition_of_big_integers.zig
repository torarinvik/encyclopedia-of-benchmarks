const Operand = struct {
    start: usize,
    digits: usize,
    negative: bool,
};

fn parseOperand(input: [*c]const i64, start: usize, text_length: usize) ?Operand {
    if (text_length == 0 or text_length > 33) return null;
    const negative = input[start] == 45;
    const digit_start = start + @as(usize, if (negative) 1 else 0);
    const digit_count = text_length - @as(usize, if (negative) 1 else 0);
    if (digit_count == 0 or digit_count > 32) return null;
    for (0..digit_count) |index| {
        const byte = input[digit_start + index];
        if (byte < 48 or byte > 57 or (index == 0 and digit_count > 1 and byte == 48)) return null;
    }
    if (negative and digit_count == 1 and input[digit_start] == 48) return null;
    return .{ .start = digit_start, .digits = digit_count, .negative = negative };
}

fn compareMagnitude(input: [*c]const i64, a: Operand, b: Operand) i32 {
    if (a.digits != b.digits) return if (a.digits > b.digits) 1 else -1;
    for (0..a.digits) |index| {
        const da = input[a.start + index];
        const db = input[b.start + index];
        if (da != db) return if (da > db) 1 else -1;
    }
    return 0;
}

export fn addition_of_big_integers(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 68) return -1;
    const raw_a = input[0];
    const raw_b = input[1];
    if (raw_a < 1 or raw_a > 33 or raw_b < 1 or raw_b > 33) return -1;
    const len_a: usize = @intCast(raw_a);
    const len_b: usize = @intCast(raw_b);
    if (length != 2 + len_a + len_b) return -1;
    const a = parseOperand(input, 2, len_a) orelse return -1;
    const b = parseOperand(input, 2 + len_a, len_b) orelse return -1;

    var reversed = [_]u8{0} ** 33;
    var digits: usize = 0;
    var negative = false;
    if (a.negative == b.negative) {
        negative = a.negative;
        const width = @max(a.digits, b.digits);
        var carry: i64 = 0;
        for (0..width) |offset| {
            const da: i64 = if (offset < a.digits) input[a.start + a.digits - 1 - offset] - 48 else 0;
            const db: i64 = if (offset < b.digits) input[b.start + b.digits - 1 - offset] - 48 else 0;
            const total = da + db + carry;
            reversed[digits] = @intCast(@mod(total, 10));
            digits += 1;
            carry = @divTrunc(total, 10);
        }
        if (carry != 0) {
            reversed[digits] = @intCast(carry);
            digits += 1;
        }
    } else {
        const order = compareMagnitude(input, a, b);
        if (order == 0) {
            reversed[0] = 0;
            digits = 1;
        } else {
            const larger = if (order > 0) a else b;
            const smaller = if (order > 0) b else a;
            negative = larger.negative;
            var borrow: i64 = 0;
            for (0..larger.digits) |offset| {
                const da = input[larger.start + larger.digits - 1 - offset] - 48;
                const db: i64 = if (offset < smaller.digits)
                    input[smaller.start + smaller.digits - 1 - offset] - 48 else 0;
                const digit = da - db - borrow;
                borrow = if (digit < 0) 1 else 0;
                reversed[digits] = @intCast(if (digit < 0) digit + 10 else digit);
                digits += 1;
            }
            while (digits > 1 and reversed[digits - 1] == 0) digits -= 1;
        }
    }

    const output_length = digits + @as(usize, if (negative) 1 else 0);
    if (output == null or capacity < output_length) return -2;
    var cursor: usize = 0;
    if (negative) {
        output[cursor] = 45;
        cursor += 1;
    }
    for (0..digits) |index| {
        output[cursor] = 48 + reversed[digits - 1 - index];
        cursor += 1;
    }
    return @intCast(output_length);
}
