#include <stddef.h>
#include <stdint.h>

enum { MAX_POINTS = 32, MAX_WORDS = 34, MAX_OUTPUT = 320 };

static int64_t adapt_bias(int64_t delta, int64_t points, int first_time) {
    delta /= first_time ? 700 : 2;
    delta += delta / points;
    int64_t k = 0;
    while (delta > ((36 - 1) * 26) / 2) {
        delta /= 35;
        k += 36;
    }
    return k + (36 * delta) / (delta + 38);
}

static uint8_t digit_byte(int64_t digit) {
    return (uint8_t)(digit < 26 ? 'a' + digit : '0' + digit - 26);
}

static int encode_payload(const int64_t *points, size_t count,
                          uint8_t staged[MAX_OUTPUT], size_t *written) {
    size_t basic_count = 0;
    for (size_t i = 0; i < count; ++i) {
        if (points[i] < 0 || points[i] > 0x10ffff ||
            (points[i] >= 0xd800 && points[i] <= 0xdfff)) return 0;
        if (points[i] < 0x80) staged[basic_count++] = (uint8_t)points[i];
    }
    size_t out = basic_count;
    if (basic_count != 0) staged[out++] = (uint8_t)'-';

    int64_t n = 128, delta = 0, bias = 72;
    size_t handled = basic_count;
    while (handled < count) {
        int64_t minimum = 0x110000;
        for (size_t i = 0; i < count; ++i)
            if (points[i] >= n && points[i] < minimum) minimum = points[i];
        delta += (minimum - n) * (int64_t)(handled + 1);
        n = minimum;
        for (size_t i = 0; i < count; ++i) {
            if (points[i] < n) ++delta;
            if (points[i] == n) {
                int64_t q = delta;
                for (int64_t k = 36;; k += 36) {
                    int64_t threshold = k <= bias ? 1 : (k >= bias + 26 ? 26 : k - bias);
                    if (q < threshold) {
                        staged[out++] = digit_byte(q);
                        break;
                    }
                    staged[out++] = digit_byte(threshold + (q - threshold) % (36 - threshold));
                    q = (q - threshold) / (36 - threshold);
                }
                bias = adapt_bias(delta, (int64_t)handled + 1, handled == basic_count);
                delta = 0;
                ++handled;
            }
        }
        ++delta;
        ++n;
    }
    *written = out;
    return 1;
}

int64_t punycode_codepoint_sequence_encode(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_WORDS) return -1;
    int64_t count_word = input[0];
    if (count_word < 0 || count_word > MAX_POINTS || length != (size_t)count_word + 1) return -1;
    uint8_t staged[MAX_OUTPUT];
    size_t written = 0;
    if (!encode_payload(input + 1, (size_t)count_word, staged, &written) || written > MAX_OUTPUT) return -1;
    if (written != 0 && (output == NULL || capacity < written)) return -2;
    for (size_t i = 0; i < written; ++i) output[i] = staged[i];
    return (int64_t)written;
}
