module punycode_codepoint_sequence_encode;

const usz MAX_POINTS = 32;
const usz MAX_WORDS = 34;
const usz MAX_OUTPUT = 320;

fn long adapt_bias(long delta, long point_count, bool first_time) {
    delta /= first_time ? 700 : 2;
    delta += delta / point_count;
    long k = 0;
    while (delta > ((36 - 1) * 26) / 2) {
        delta /= 35;
        k += 36;
    }
    return k + (36 * delta) / (delta + 38);
}

fn char encode_digit(long digit) {
    return (char)(digit < 26 ? 'a' + digit : '0' + digit - 26);
}

fn bool is_scalar(long point) {
    return point >= 0 && point <= 0x10ffff && !(point >= 0xd800 && point <= 0xdfff);
}

fn usz encode_payload(long* points, usz count, char* staged) {
    usz basic_count = 0;
    for (usz i = 0; i < count; i++) {
        if (points[i] < 0x80) {
            staged[basic_count] = (char)points[i];
            basic_count++;
        }
    }
    usz written = basic_count;
    if (basic_count != 0) { staged[written] = '-'; written++; }
    long n = 128;
    long delta = 0;
    long bias = 72;
    usz handled = basic_count;
    while (handled < count) {
        long minimum = 0x110000;
        for (usz i = 0; i < count; i++) if (points[i] >= n && points[i] < minimum) minimum = points[i];
        delta += (minimum - n) * (long)(handled + 1);
        n = minimum;
        for (usz i = 0; i < count; i++) {
            if (points[i] < n) delta++;
            if (points[i] == n) {
                long q = delta;
                for (long k = 36;; k += 36) {
                    long threshold = k <= bias ? 1 : (k >= bias + 26 ? 26 : k - bias);
                    if (q < threshold) { staged[written] = encode_digit(q); written++; break; }
                    staged[written] = encode_digit(threshold + (q - threshold) % (36 - threshold));
                    written++;
                    q = (q - threshold) / (36 - threshold);
                }
                bias = adapt_bias(delta, (long)handled + 1, handled == basic_count);
                delta = 0;
                handled++;
            }
        }
        delta++;
        n++;
    }
    return written;
}

fn long punycode_codepoint_sequence_encode(long* input, usz length, char* output, usz capacity)
    @export("punycode_codepoint_sequence_encode") {
    if (input == null || length < 1 || length > MAX_WORDS) return -1;
    long count_word = input[0];
    if (count_word < 0 || count_word > (long)MAX_POINTS || length != (usz)count_word + 1) return -1;
    usz count = (usz)count_word;
    for (usz i = 0; i < count; i++) if (!is_scalar(input[i + 1])) return -1;
    char[MAX_OUTPUT] staged = {};
    usz written = encode_payload(&input[1], count, &staged[0]);
    if (written > MAX_OUTPUT) return -1;
    if (written != 0 && (output == null || capacity < written)) return -2;
    for (usz i = 0; i < written; i++) output[i] = staged[i];
    return (long)written;
}
