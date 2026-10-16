module problem104;

const uint MAX_FIBONACCI_INDEX = 1000002;
const usz MAX_LIMBS = 24000;
const ulong LIMB_BASE = 1000000000ul;

fn bool is_pandigital_1_to_9(uint value) {
    ushort mask = 0;
    for (usz index = 0; index < 9; index++) {
        uint digit = value % 10;
        ushort bit = (ushort)(1 << digit);
        if (digit == 0 || (mask & bit) != 0) return false;
        mask |= bit;
        value /= 10;
    }
    return value == 0 && mask == 0x3fe;
}
fn uint power_of_ten(uint exponent) {
    uint value = 1;
    while (exponent > 0) { value *= 10; exponent--; }
    return value;
}
fn uint leading_nine_digits(uint* limbs, usz length) {
    uint top = limbs[length - 1], width = 0;
    for (uint value = top; value > 0; value /= 10) width++;
    if (width >= 9 || length == 1) return top;
    uint fill = 9 - width;
    uint next_prefix = limbs[length - 2] / power_of_ten(width);
    return top * power_of_ten(fill) + next_prefix;
}

fn long problem104(long placeholder) @export("problem104") {
    if (placeholder != 0) return -1;
    u32[MAX_LIMBS] first_buffer = {1};
    u32[MAX_LIMBS] second_buffer = {1};
    u32* previous = &first_buffer[0];
    u32* current = &second_buffer[0];
    usz previous_length = 1, current_length = 1;

    for (uint index = 3; index <= MAX_FIBONACCI_INDEX; index++) {
        usz sum_length = previous_length > current_length ? previous_length : current_length;
        ulong carry = 0;
        for (usz limb = 0; limb < sum_length; limb++) {
            ulong left = limb < previous_length ? (ulong)previous[limb] : 0;
            ulong right = limb < current_length ? (ulong)current[limb] : 0;
            ulong sum = left + right + carry;
            previous[limb] = (uint)(sum % LIMB_BASE);
            carry = sum / LIMB_BASE;
        }
        usz next_length = sum_length;
        if (carry != 0) {
            if (next_length == MAX_LIMBS) return -1;
            previous[next_length++] = (uint)carry;
        }
        u32* temporary = previous;
        previous = current;
        current = temporary;
        previous_length = current_length;
        current_length = next_length;
        if (is_pandigital_1_to_9(current[0])
            && is_pandigital_1_to_9(leading_nine_digits(current, current_length))) return (long)index;
    }
    return -1;
}
