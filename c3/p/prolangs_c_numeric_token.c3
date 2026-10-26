module prolangs_c_numeric_token;

fn void put_i32(char* out, usz at, int value) {
    uint bits = @bitcast(uint, value);
    for (usz b = 0; b < 4; b++) out[at + b] = (char)(bits >> (b * 8));
}

fn long prolangs_c_numeric_token(long* input, usz length, char* output, usz capacity)
    @export("prolangs_c_numeric_token") {
    if (input == null || length < 1 || length > 24) return -1;
    char[24] text;
    for (usz j = 0; j < length; j++) { if (input[j] < 32 || input[j] > 127) return -1; text[j] = (char)input[j]; }
    usz i = 0; uint integer = 0; bool had_integer = false;
    if (text[i] >= '0' && text[i] <= '9') {
        had_integer = true;
        while (i < length && text[i] >= '0' && text[i] <= '9') {
            uint d = (uint)(text[i] - '0'); i++;
            if (integer > (2147483647u - d) / 10u) return -1;
            integer = integer * 10u + d;
        }
        if (i == length) {
            if (capacity < 12 || output == null) return -2;
            put_i32(output, 0, 256); put_i32(output, 4, (int)integer); put_i32(output, 8, 0); return 12;
        }
    }
    uint fraction_digits = 0; usz fraction_count = 0; usz leading_zeros = 0; bool has_dot = false;
    if (i < length && text[i] == '.') {
        has_dot = true; i++;
        while (i < length && text[i] == '0') { leading_zeros++; i++; }
        if (leading_zeros > 6) return -1;
        while (i < length && text[i] >= '0' && text[i] <= '9') {
            if (fraction_count == 6) return -1;
            fraction_digits = fraction_digits * 10u + (uint)(text[i] - '0'); fraction_count++; i++;
        }
        if (leading_zeros + fraction_count > 6) return -1;
    }
    float value = 0.0f;
    if (fraction_count != 0) {
        value = (float)fraction_digits;
        while (value >= 1.0f) value /= 10.0f;
        while (leading_zeros > 0) { value /= 10.0f; leading_zeros--; }
    }
    value += (float)integer;
    bool has_exp = false;
    if (i < length && (text[i] == 'e' || text[i] == 'E')) {
        has_exp = true; i++; int sign = 1;
        if (i < length && (text[i] == '+' || text[i] == '-')) { if (text[i] == '-') sign = -1; i++; }
        if (i == length || text[i] < '0' || text[i] > '9') return -1;
        int exponent = 0;
        while (i < length && text[i] >= '0' && text[i] <= '9') { exponent = exponent * 10 + (text[i] - '0'); i++; if (exponent > 6) return -1; }
        exponent *= sign;
        while (exponent > 0) { value *= 10.0f; exponent--; }
        while (exponent < 0) { value /= 10.0f; exponent++; }
    }
    if (i != length || (!has_dot && !has_exp) || (!had_integer && !has_dot)) return -1;
    if (capacity < 12 || output == null) return -2;
    put_i32(output, 0, 2001); put_i32(output, 4, (int)integer); put_i32(output, 8, @bitcast(int, value));
    return 12;
}
