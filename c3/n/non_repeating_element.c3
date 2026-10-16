module non_repeating_element;

const long MAX_VALUE = 1073741823L;

fn long non_repeating_element(long* values, usz length) @export("non_repeating_element") {
    if (length < 2 || length > 64 || (length & 1) != 0) return -1;
    int xor_result = 0;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > MAX_VALUE) return -1;
        xor_result ^= (int)values[index];
    }
    int rightmost_set_bit = xor_result & -xor_result;
    int num1 = 0;
    int num2 = 0;
    for (usz index = 0; index < length; index++) {
        int value = (int)values[index];
        if ((value & rightmost_set_bit) != 0) num1 ^= value;
        else num2 ^= value;
    }
    return ((long)num1 << 32) | (long)(uint)num2;
}
