#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 64, SCRATCH = 128, CODE_BYTES = 10 };

static int replace_all(char *text, size_t *length, const char *old, size_t old_len,
                       const char *replacement, size_t replacement_len) {
    char next[SCRATCH];
    size_t out = 0;
    for (size_t i = 0; i < *length;) {
        size_t j = 0;
        while (j < old_len && i + j < *length && text[i + j] == old[j]) ++j;
        if (j == old_len) {
            if (out + replacement_len >= SCRATCH) return 0;
            for (j = 0; j < replacement_len; ++j) next[out++] = replacement[j];
            i += old_len;
        } else {
            if (out + 1 >= SCRATCH) return 0;
            next[out++] = text[i++];
        }
    }
    for (size_t i = 0; i < out; ++i) text[i] = next[i];
    *length = out;
    return 1;
}

static void replace_prefix(char *text, size_t *length, const char *old,
                           size_t old_len, const char *replacement, size_t replacement_len) {
    if (*length < old_len) return;
    for (size_t i = 0; i < old_len; ++i) if (text[i] != old[i]) return;
    size_t tail = *length - old_len;
    for (size_t i = tail; i > 0; --i) text[replacement_len + i - 1] = text[old_len + i - 1];
    for (size_t i = 0; i < replacement_len; ++i) text[i] = replacement[i];
    *length = replacement_len + tail;
}

static void replace_suffix(char *text, size_t *length, const char *old,
                           size_t old_len, const char *replacement, size_t replacement_len) {
    if (*length < old_len) return;
    size_t start = *length - old_len;
    for (size_t i = 0; i < old_len; ++i) if (text[start + i] != old[i]) return;
    for (size_t i = 0; i < replacement_len; ++i) text[start + i] = replacement[i];
    *length = start + replacement_len;
}

static void replace_char(char *text, size_t length, char old, char replacement) {
    for (size_t i = 0; i < length; ++i) if (text[i] == old) text[i] = replacement;
}

static void squeeze(char *text, size_t *length, char letter, char marker) {
    size_t out = 0;
    for (size_t i = 0; i < *length; ++i) {
        if (text[i] == letter && out > 0 && text[out - 1] == marker) continue;
        text[out++] = text[i] == letter ? marker : text[i];
    }
    *length = out;
}

static void encode(const int64_t *input, char result[CODE_BYTES]) {
    char text[SCRATCH];
    size_t n = (size_t)input[0];
    for (size_t i = 0; i < n; ++i) {
        int64_t c = input[i + 1];
        text[i] = (char)(c >= 'A' && c <= 'Z' ? c + ('a' - 'A') : c);
    }
    if (n == 0) {
        for (size_t i = 0; i < CODE_BYTES; ++i) result[i] = '1';
        return;
    }
    if (text[n - 1] == 'e') --n;
    replace_prefix(text, &n, "cough", 5, "cou2f", 5);
    replace_prefix(text, &n, "rough", 5, "rou2f", 5);
    replace_prefix(text, &n, "tough", 5, "tou2f", 5);
    replace_prefix(text, &n, "enough", 6, "enou2f", 6);
    replace_prefix(text, &n, "trough", 6, "trou2f", 6);
    replace_prefix(text, &n, "gn", 2, "2n", 2);
    replace_suffix(text, &n, "mb", 2, "m2", 2);
    (void)replace_all(text, &n, "cq", 2, "2q", 2);
    (void)replace_all(text, &n, "ci", 2, "si", 2);
    (void)replace_all(text, &n, "ce", 2, "se", 2);
    (void)replace_all(text, &n, "cy", 2, "sy", 2);
    (void)replace_all(text, &n, "tch", 3, "2ch", 3);
    replace_char(text, n, 'c', 'k');
    replace_char(text, n, 'q', 'k');
    replace_char(text, n, 'x', 'k');
    replace_char(text, n, 'v', 'f');
    (void)replace_all(text, &n, "dg", 2, "2g", 2);
    (void)replace_all(text, &n, "tio", 3, "sio", 3);
    (void)replace_all(text, &n, "tia", 3, "sia", 3);
    replace_char(text, n, 'd', 't');
    (void)replace_all(text, &n, "ph", 2, "fh", 2);
    replace_char(text, n, 'b', 'p');
    (void)replace_all(text, &n, "sh", 2, "s2", 2);
    replace_char(text, n, 'z', 's');
    if (n && (text[0]=='a'||text[0]=='e'||text[0]=='i'||text[0]=='o'||text[0]=='u')) text[0] = 'A';
    for (size_t i = 0; i < n; ++i) if (text[i]=='a'||text[i]=='e'||text[i]=='i'||text[i]=='o'||text[i]=='u') text[i]='3';
    replace_char(text, n, 'j', 'y');
    replace_prefix(text, &n, "y3", 2, "Y3", 2);
    replace_prefix(text, &n, "y", 1, "A", 1);
    replace_char(text, n, 'y', '3');
    (void)replace_all(text, &n, "3gh3", 4, "3kh3", 4);
    (void)replace_all(text, &n, "gh", 2, "22", 2);
    replace_char(text, n, 'g', 'k');
    squeeze(text, &n, 's', 'S'); squeeze(text, &n, 't', 'T');
    squeeze(text, &n, 'p', 'P'); squeeze(text, &n, 'k', 'K');
    squeeze(text, &n, 'f', 'F'); squeeze(text, &n, 'm', 'M'); squeeze(text, &n, 'n', 'N');
    (void)replace_all(text, &n, "w3", 2, "W3", 2);
    (void)replace_all(text, &n, "wh3", 3, "Wh3", 3);
    replace_suffix(text, &n, "w", 1, "3", 1); replace_char(text, n, 'w', '2');
    replace_prefix(text, &n, "h", 1, "A", 1); replace_char(text, n, 'h', '2');
    (void)replace_all(text, &n, "r3", 2, "R3", 2);
    replace_suffix(text, &n, "r", 1, "3", 1); replace_char(text, n, 'r', '2');
    (void)replace_all(text, &n, "l3", 2, "L3", 2);
    replace_suffix(text, &n, "l", 1, "3", 1); replace_char(text, n, 'l', '2');
    size_t out = 0;
    for (size_t i = 0; i < n; ++i) if (text[i] != '2') text[out++] = text[i];
    n = out;
    replace_suffix(text, &n, "3", 1, "A", 1); replace_char(text, n, '3', 0);
    out = 0;
    for (size_t i = 0; i < n; ++i) if (text[i] != 0) text[out++] = text[i];
    n = out;
    for (size_t i = 0; i < CODE_BYTES; ++i) result[i] = i < n ? text[i] : '1';
}

int64_t caverphone_2_encoder(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_TEXT + 1) return -1;
    int64_t count = input[0];
    if (count < 0 || count > MAX_TEXT || length != (size_t)count + 1) return -1;
    for (size_t i = 0; i < (size_t)count; ++i) {
        int64_t c = input[i + 1];
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))) return -1;
    }
    if (output == NULL || output_capacity < CODE_BYTES) return -2;
    char result[CODE_BYTES];
    encode(input, result);
    for (size_t i = 0; i < CODE_BYTES; ++i) output[i] = (uint8_t)result[i];
    return CODE_BYTES;
}
