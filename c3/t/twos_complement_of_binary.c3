module twos_complement_of_binary;

const long MAX_BINARY_DIGIT_NUMERAL = 1111111111111111;

fn long twos_complement_of_binary(long value) @export("twos_complement_of_binary") {
    if (value < 0 || value > MAX_BINARY_DIGIT_NUMERAL) return -1;
    if (value == 0) return 0;

    long remaining = value;
    while (remaining > 0) {
        long digit = remaining % 10;
        if (digit != 0 && digit != 1) return -1;
        remaining /= 10;
    }

    remaining = value;
    long reversed = 0;
    long width = 0;
    while (remaining > 0 && remaining % 10 == 0) {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
        width++;
    }
    if (remaining > 0) {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
        width++;
    }
    while (remaining > 0) {
        long digit = remaining % 10;
        reversed = reversed * 10 + (digit == 1 ? 0 : 1);
        remaining /= 10;
        width++;
    }

    long result = 0;
    while (width > 0) {
        result = result * 10 + reversed % 10;
        reversed /= 10;
        width--;
    }
    return result;
}
