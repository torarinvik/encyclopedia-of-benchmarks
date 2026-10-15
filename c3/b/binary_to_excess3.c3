module binary_to_excess3;

const MAX_TEXT_LENGTH = 128;
const MAX_MAGNITUDE = 4611686018427387904;

fn bool is_ascii_space(long value) {
    return value == 32 || (value >= 9 && value <= 13);
}

fn bool is_binary_digit(long value) {
    return value == '0' || value == '1';
}

fn long binary_to_excess3(long* values, usz length, char* output, usz output_capacity)
    @export("binary_to_excess3")
{
    if (values == null || length == 0 || length > MAX_TEXT_LENGTH) return -1;
    usz start = 0, end = length;
    while (start < end && is_ascii_space(values[start])) start++;
    while (end > start && is_ascii_space(values[end - 1])) end--;
    if (start == end) return -1;

    bool negative = false;
    if (values[start] == '+' || values[start] == '-') {
        negative = values[start] == '-';
        start++;
        if (start == end) return -1;
    }
    bool prefixed = end - start >= 2 && values[start] == '0' &&
                    (values[start + 1] == 'b' || values[start + 1] == 'B');
    if (prefixed) start += 2;
    if (start == end) return -1;

    usz digit_start = start;
    bool allow_prefix_underscore = prefixed;
    bool have_digit = false, last_was_digit = false;
    long magnitude = 0;
    for (usz index = start; index < end; index++) {
        long value = values[index];
        if (is_binary_digit(value)) {
            long digit = value - '0';
            if (magnitude > (MAX_MAGNITUDE - digit) / 2) return -1;
            magnitude = magnitude * 2 + digit;
            have_digit = true;
            last_was_digit = true;
            allow_prefix_underscore = false;
        } else if (value == '_') {
            if (last_was_digit && index + 1 < end && is_binary_digit(values[index + 1])) {
                last_was_digit = false;
            } else if (allow_prefix_underscore && !have_digit && index == digit_start &&
                       index + 1 < end && is_binary_digit(values[index + 1])) {
                allow_prefix_underscore = false;
            } else {
                return -1;
            }
        } else {
            return -1;
        }
    }
    if (!have_digit || !last_was_digit) return -1;

    long result = negative ? -magnitude : magnitude;
    result += 3;
    bool result_is_negative = result < 0;
    long remaining = result_is_negative ? -result : result;
    u8[64] reversed;
    usz digit_count = 0;
    do {
        reversed[digit_count++] = (u8)('0' + remaining % 2);
        remaining /= 2;
    } while (remaining > 0);

    usz sign_length = result_is_negative ? 1 : 0;
    usz output_length = sign_length + digit_count;
    if (output_length < 4) output_length = 4;
    if (output == null || output_capacity < output_length) return -2;
    usz position = 0;
    if (result_is_negative) output[position++] = '-';
    usz digit_width = output_length - sign_length;
    for (usz pad = digit_count; pad < digit_width; pad++) output[position++] = '0';
    while (digit_count > 0) {
        digit_count--;
        output[position++] = reversed[digit_count];
    }
    return (long)output_length;
}
