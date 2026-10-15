module digit_separation;

// Separate signed decimal digits; direction 0 is reverse and 1 is forward.
fn long digit_separation(long* input, usz input_length, char* output,
        usz output_capacity) @export("digit_separation") {
    if (input == null || input_length != 2 || (input[1] != 0 && input[1] != 1)) return -1;
    long remaining = input[0];
    uint[20] digits;
    usz count = 0;
    if (remaining == 0) digits[count++] = 0;
    while (remaining != 0) {
        long remainder = remaining % 10;
        digits[count++] = (remainder < 0 ? -remainder : remainder).u32();
        remaining /= 10;
    }
    if (output == null || output_capacity < count) return -2;
    for (usz index = 0; index < count; index++) {
        usz source = input[1] == 0 ? index : count - index - 1;
        output[index] = digits[source].u8();
    }
    return count.long();
}
