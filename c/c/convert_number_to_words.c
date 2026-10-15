#include <stddef.h>
#include <stdint.h>
#include <string.h>

typedef struct { uint64_t value; const char *unit; } scale_t;
static const char *ones[] = {"zero","one","two","three","four","five","six","seven","eight","nine"};
static const char *teens[] = {"ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen"};
static const char *tens[] = {"","","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety"};
static const scale_t short_scales[] = {{1000000000000000ULL,"quadrillion"},{1000000000000ULL,"trillion"},{1000000000ULL,"billion"},{1000000ULL,"million"},{1000ULL,"thousand"},{100ULL,"hundred"}};
static const scale_t long_scales[] = {{1000000000000000ULL,"billiard"},{1000000000ULL,"milliard"},{1000000ULL,"million"},{1000ULL,"thousand"},{100ULL,"hundred"}};
static const scale_t indian_scales[] = {{100000000000000ULL,"crore crore"},{1000000000000ULL,"lakh crore"},{10000000ULL,"crore"},{100000ULL,"lakh"},{1000ULL,"thousand"},{100ULL,"hundred"}};

static void append_raw(char *out, size_t *len, const char *text) { while (*text) out[(*len)++] = *text++; }
static void append_word(char *out, size_t *len, const char *text) { if (*len) out[(*len)++] = ' '; append_raw(out, len, text); }
static void append_small(uint64_t n, char *out, size_t *len) {
    if (n < 10) { append_word(out, len, ones[n]); return; }
    if (n < 20) { append_word(out, len, teens[n - 10]); return; }
    append_word(out, len, tens[n / 10]);
    if (n % 10) { out[(*len)++] = '-'; append_raw(out, len, ones[n % 10]); }
}
static void append_number(uint64_t n, int system, char *out, size_t *len, int depth) {
    if (depth > 8) return;
    const scale_t *scales = system == 0 ? short_scales : system == 1 ? long_scales : indian_scales;
    size_t count = system == 1 ? 5 : 6;
    size_t initial_len = *len;
    for (size_t i = 0; i < count; ++i) {
        uint64_t group = n / scales[i].value;
        n %= scales[i].value;
        if (!group) continue;
        if (group >= 100) append_number(group, system, out, len, depth + 1);
        else append_small(group, out, len);
        append_word(out, len, scales[i].unit);
    }
    if (n || *len == initial_len) append_small(n, out, len);
}

int64_t convert_number_to_words(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 2 || input[1] < 0 || input[1] > 2) return -1;
    int system = (int)input[1];
    int64_t number = input[0];
    uint64_t limit = system == 0 ? 999999999999999999ULL : 9000000000000000000ULL;
    if (number < -(int64_t)limit || number > (int64_t)limit) return -1;
    uint64_t magnitude = number < 0 ? (uint64_t)(-number) : (uint64_t)number;
    char words[512];
    size_t word_count = 0;
    if (number < 0) append_word(words, &word_count, "negative");
    append_number(magnitude, system, words, &word_count, 0);
    if (capacity < word_count || output == NULL) return -2;
    memcpy(output, words, word_count);
    return (int64_t)word_count;
}
