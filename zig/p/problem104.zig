const MAX_FIBONACCI_INDEX: u32 = 1_000_002;
const MAX_LIMBS: usize = 24_000;
const LIMB_BASE: u64 = 1_000_000_000;

fn is_pandigital_1_to_9(value_value: u32) bool {
    var value = value_value;
    var mask: u16 = 0;
    for (0..9) |_| {
        const digit = value % 10;
        const bit = @as(u16, 1) << @intCast(digit);
        if (digit == 0 or (mask & bit) != 0) return false;
        mask |= bit;
        value /= 10;
    }
    return value == 0 and mask == 0x3fe;
}
fn power_of_ten(exponent: u32) u32 {
    var value: u32 = 1;
    for (0..exponent) |_| value *= 10;
    return value;
}
fn leading_nine_digits(limbs: [*]const u32, length: usize) u32 {
    const top = limbs[length - 1];
    var width: u32 = 0;
    var value = top;
    while (value > 0) : (value /= 10) width += 1;
    if (width >= 9 or length == 1) return top;
    const fill = 9 - width;
    const next_prefix = limbs[length - 2] / power_of_ten(width);
    return top * power_of_ten(fill) + next_prefix;
}

export fn problem104(placeholder: i64) i64 {
    if (placeholder != 0) return -1;
    var first_buffer: [MAX_LIMBS]u32 = @splat(0);
    var second_buffer: [MAX_LIMBS]u32 = @splat(0);
    first_buffer[0] = 1;
    second_buffer[0] = 1;
    var previous: [*]u32 = first_buffer[0..].ptr;
    var current: [*]u32 = second_buffer[0..].ptr;
    var previous_length: usize = 1;
    var current_length: usize = 1;
    for (3..MAX_FIBONACCI_INDEX + 1) |index_value| {
        const index: u32 = @intCast(index_value);
        const sum_length = @max(previous_length, current_length);
        var carry: u64 = 0;
        for (0..sum_length) |limb| {
            const left: u64 = if (limb < previous_length) previous[limb] else 0;
            const right: u64 = if (limb < current_length) current[limb] else 0;
            const sum = left + right + carry;
            previous[limb] = @intCast(sum % LIMB_BASE);
            carry = sum / LIMB_BASE;
        }
        var next_length = sum_length;
        if (carry != 0) {
            if (next_length == MAX_LIMBS) return -1;
            previous[next_length] = @intCast(carry);
            next_length += 1;
        }
        const temporary = previous;
        previous = current;
        current = temporary;
        previous_length = current_length;
        current_length = next_length;
        if (is_pandigital_1_to_9(current[0])
            and is_pandigital_1_to_9(leading_nine_digits(current, current_length))) return @intCast(index);
    }
    return -1;
}
