module ary3;

const usz MAX_LENGTH = 4096;

fn usz decimal_digits(uint value) {
    usz count = 1;
    while (value >= 10) { value /= 10; count++; }
    return count;
}

fn void write_decimal(uint value, char* output) {
    char[10] reversed;
    usz count = 0;
    do {
        reversed[count++] = (char)(48 + value % 10);
        value /= 10;
    } while (value != 0);
    for (usz index = 0; index < count; index++) output[index] = reversed[count - index - 1];
}

fn long ary3(long length, char* output, usz output_capacity) @export("ary3") {
    if (length < 1 || length > (long)MAX_LENGTH) return -1;
    usz n = (usz)length;
    int[4096] x;
    int[4096] y;
    for (usz index = 0; index < n; index++) {
        x[index] = (int)(index + 1);
        y[index] = 0;
    }
    for (usz pass = 0; pass < 1000; pass++) {
        for (usz index = n; index > 0; index--) {
            usz position = index - 1;
            y[position] += x[position];
        }
    }

    uint first = (uint)y[0];
    uint last = (uint)y[n - 1];
    usz first_digits = decimal_digits(first);
    usz required = first_digits + 2 + decimal_digits(last);
    if (output == null || output_capacity < required) return -2;
    write_decimal(first, output);
    output[first_digits] = (char)32;
    write_decimal(last, output + first_digits + 1);
    output[required - 1] = (char)10;
    return (long)required;
}
