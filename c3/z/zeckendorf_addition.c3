module zeckendorf_addition;

import "core:c";

const usz MAX_BITS = 64;
const usz MAX_PARSEABLE = 131;
const usz MAX_OUTPUT = 66;

fn bool canonical(long* bits, usz length) {
    if (length == 1 && bits[0] == 0) return true;
    if (length == 0 || bits[0] != 1) return false;
    for (usz i = 0; i < length; i++) {
        if (bits[i] != 0 && bits[i] != 1) return false;
        if (i + 1 < length && bits[i] == 1 && bits[i + 1] == 1) return false;
    }
    return true;
}

fn void stage_one(u8* d, usz n) {
    for (usz i = 0; i + 3 < n; i++) {
        if (d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 0) {
            d[i] = 1; d[i + 1] = 0; d[i + 2] = 0; d[i + 3] += 1;
        } else if (d[i] == 0 && d[i + 1] == 3 && d[i + 2] == 0) {
            d[i] = 1; d[i + 1] = 1; d[i + 2] = 0; d[i + 3] += 1;
        } else if (d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 1) {
            d[i] = 1; d[i + 1] = 1; d[i + 2] = 0;
        } else if (d[i] == 0 && d[i + 1] == 1 && d[i + 2] == 2) {
            d[i] = 1; d[i + 1] = 0; d[i + 2] = 1;
        }
    }
    if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 3 && d[n - 1] == 0) {
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 1;
    } else if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 0) {
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1;
    } else if (n >= 4 && d[n - 4] == 0 && d[n - 3] == 1 && d[n - 2] == 2 && d[n - 1] == 0) {
        d[n - 4] = 1; d[n - 3] = 0; d[n - 2] = 1; d[n - 1] = 0;
    } else if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 1) {
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 0;
    }
    if (n >= 2 && d[n - 2] == 0 && d[n - 1] == 3) {
        d[n - 2] = 1; d[n - 1] = 1;
    } else if (n >= 2 && d[n - 2] == 0 && d[n - 1] == 2) {
        d[n - 2] = 1; d[n - 1] = 0;
    } else if (n >= 3 && d[n - 3] == 0 && d[n - 2] == 1 && d[n - 1] == 2) {
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1;
    }
}

fn long zeckendorf_addition(long* input, usz length, u8* output, usz output_capacity)
    @export("zeckendorf_addition") {
    if (input == null || length < 4 || length > MAX_PARSEABLE) return -1;
    long first_n = input[0];
    if (first_n < 1 || first_n > (long)MAX_BITS) return -1;
    usz second_n_index = (usz)first_n + 1;
    if (second_n_index >= length) return -1;
    long second_n = input[second_n_index];
    if (second_n < 1 || second_n > (long)MAX_BITS) return -1;
    if (length != second_n_index + (usz)second_n + 1) return -1;
    long* first = input + 1;
    long* second = input + second_n_index + 1;
    if (!canonical(first, (usz)first_n) || !canonical(second, (usz)second_n)) return -1;

    usz width = (usz)(first_n > second_n ? first_n : second_n);
    usz first_offset = width - (usz)first_n;
    usz second_offset = width - (usz)second_n;
    u8[MAX_OUTPUT] digits = zeroed;
    usz digit_count = width + 1;
    for (usz i = 0; i < width; i++) {
        u8 a = i < first_offset ? 0 : (u8)first[i - first_offset];
        u8 b = i < second_offset ? 0 : (u8)second[i - second_offset];
        digits[i + 1] = a + b;
    }
    stage_one(&digits[0], digit_count);
    for (usz i = digit_count; i > 0; i--) digits[i] = digits[i - 1];
    digits[0] = 0;
    digit_count++;
    for (usz i = digit_count - 2; i > 0; i--) {
        usz start = i - 1;
        if (digits[start] == 0 && digits[start + 1] == 1 && digits[start + 2] == 1) {
            digits[start] = 1; digits[start + 1] = 0; digits[start + 2] = 0;
        }
    }
    for (usz i = 0; i + 2 < digit_count; i++) {
        if (digits[i] == 0 && digits[i + 1] == 1 && digits[i + 2] == 1) {
            digits[i] = 1; digits[i + 1] = 0; digits[i + 2] = 0;
        }
    }
    usz first_output = 0;
    while (first_output + 1 < digit_count && digits[first_output] == 0) first_output++;
    usz required = digit_count - first_output;
    if (output == null || output_capacity < required) return -2;
    for (usz i = 0; i < required; i++) output[i] = (u8)'0' + digits[first_output + i];
    return (long)required;
}
