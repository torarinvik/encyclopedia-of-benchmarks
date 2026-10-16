module hexa_decimal_to_binary;

fn int hex_digit(long code) {
    if (code >= '0' && code <= '9') return (int)(code - '0');
    if (code >= 'A' && code <= 'F') return (int)(code - 'A' + 10);
    if (code >= 'a' && code <= 'f') return (int)(code - 'a' + 10);
    return -1;
}

fn long hexa_decimal_to_binary(long* input, usz length, char* output, usz output_capacity)
        @export("hexa_decimal_to_binary") {
    if (input == null || length == 0 || length > 65) return -1;
    usz first_digit = 0;
    bool negative = false;
    if (input[0] == '-') { negative = true; first_digit = 1; }
    else if (input[0] == '+') first_digit = 1;
    if (first_digit == length) return -1;
    ulong value = 0;
    ulong limit = negative ? 2147483648ul : 2147483647ul;
    for (usz index = first_digit; index < length; index++) {
        int digit = hex_digit(input[index]);
        if (digit < 0 || value > (limit - (ulong)digit) / 16) return -1;
        value = value * 16 + (ulong)digit;
    }
    uint bits = negative ? (uint)(4294967296ul - value) : (uint)value;
    usz width = 0;
    for (uint remaining = bits; remaining != 0; remaining >>= 1) width++;
    if (negative && value != 0) width = 32;
    else if (width < 8) width = 8;
    char[32] buffer;
    uint remaining = bits;
    for (usz position = width; position > 0;) {
        position--;
        buffer[position] = (char)('0' + remaining % 2);
        remaining >>= 1;
    }
    if (width > output_capacity || output == null) return -2;
    for (usz index = 0; index < width; index++) output[index] = buffer[index];
    return (long)width;
}
