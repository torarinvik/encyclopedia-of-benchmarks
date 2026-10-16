module complex_arithmetic;

const long MAX_COMPONENT = 100000L;
const usz OUTPUT_BYTES = 16;

fn void store_i64_le(long value, char* output, usz position) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[position + byte] = (char)((bits >> (byte * 8)) & 255uL);
    }
}

fn long complex_arithmetic(long* input, usz length, char* output, usz output_capacity)
    @export("complex_arithmetic") {
    if (input == null || length != 5) return -1;
    long operation = input[0];
    long ar = input[1];
    long ai = input[2];
    long br = input[3];
    long bi = input[4];
    if (operation < 0 || operation > 5 || ar < -MAX_COMPONENT || ar > MAX_COMPONENT ||
        ai < -MAX_COMPONENT || ai > MAX_COMPONENT || br < -MAX_COMPONENT ||
        br > MAX_COMPONENT || bi < -MAX_COMPONENT || bi > MAX_COMPONENT) return -1;

    long real_result = 0;
    long imaginary_result = 0;
    if (operation == 0) {
        real_result = ar + br;
        imaginary_result = ai + bi;
    } else if (operation == 1) {
        real_result = ar - br;
        imaginary_result = ai - bi;
    } else if (operation == 2) {
        real_result = ar * br - ai * bi;
        imaginary_result = ar * bi + ai * br;
    } else if (operation == 3) {
        long denominator = br * br + bi * bi;
        if (denominator == 0) return -1;
        long real_numerator = ar * br + ai * bi;
        long imaginary_numerator = ai * br - ar * bi;
        if (real_numerator % denominator != 0 || imaginary_numerator % denominator != 0) return -1;
        real_result = real_numerator / denominator;
        imaginary_result = imaginary_numerator / denominator;
    } else if (operation == 4) {
        real_result = ar;
        imaginary_result = -ai;
    } else {
        real_result = ar == br && ai == bi ? 1 : 0;
    }
    if (output_capacity < OUTPUT_BYTES || output == null) return -2;
    store_i64_le(real_result, output, 0);
    store_i64_le(imaginary_result, output, 8);
    return 2;
}
