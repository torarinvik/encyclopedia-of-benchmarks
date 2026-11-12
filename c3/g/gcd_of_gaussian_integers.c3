module gcd_of_gaussian_integers;

const usz MAX_T = 8;
const long MAX_COMPONENT = 1000000;

fn long nearest_quotient(long numerator, long denominator) {
    long sign = numerator < 0 ? -1 : 1;
    long magnitude = numerator < 0 ? -numerator : numerator;
    long quotient = magnitude / denominator;
    long remainder = magnitude % denominator;
    if (2 * remainder >= denominator) quotient += 1;
    return sign * quotient;
}

fn void gaussian_gcd(long ar, long ai, long br, long bi,
                     long* result_real, long* result_imaginary) {
    while (br != 0 || bi != 0) {
        long denominator = br * br + bi * bi;
        long qr = nearest_quotient(ar * br + ai * bi, denominator);
        long qi = nearest_quotient(ai * br - ar * bi, denominator);
        long rr = ar - (qr * br - qi * bi);
        long ri = ai - (qr * bi + qi * br);
        ar = br;
        ai = bi;
        br = rr;
        bi = ri;
    }
    if (ar != 0 || ai != 0) {
        for (usz rotation = 0; rotation < 4 && !(ar > 0 && ai >= 0); rotation += 1) {
            long old_real = ar;
            ar = -ai;
            ai = old_real;
        }
    }
    *result_real = ar;
    *result_imaginary = ai;
}

fn void write_u32(char* output, usz offset, u32 value) {
    output[offset] = (char)(value & 255);
    output[offset + 1] = (char)((value >> 8) & 255);
    output[offset + 2] = (char)((value >> 16) & 255);
    output[offset + 3] = (char)((value >> 24) & 255);
}

fn long gcd_of_gaussian_integers(long* input, usz length, char* output, usz capacity)
    @export("gcd_of_gaussian_integers") {
    if (input == null || length < 5 || length > 1 + 4 * MAX_T) return -1;
    long t64 = input[0];
    if (t64 < 1 || t64 > (long)MAX_T) return -1;
    usz t = (usz)t64;
    if (length != 1 + 4 * t) return -1;

    long[4 * MAX_T] values = zeroed;
    for (usz index = 0; index < 4 * t; index += 1) {
        long value = input[index + 1];
        if (value < -MAX_COMPONENT || value > MAX_COMPONENT) return -1;
        values[index] = value;
    }
    usz required = 8 * t;
    if (output == null || capacity < required) return -2;

    for (usz test = 0; test < t; test += 1) {
        long real = 0, imaginary = 0;
        gaussian_gcd(values[4 * test], values[4 * test + 1],
                     values[4 * test + 2], values[4 * test + 3],
                     &real, &imaginary);
        write_u32(output, 8 * test, (u32)real);
        write_u32(output, 8 * test + 4, (u32)imaginary);
    }
    return (long)required;
}
