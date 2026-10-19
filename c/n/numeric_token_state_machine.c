/* Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
 * Apache-2.0 licensed upstream kernel, bounded variant; modifications made. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 96
#define STATES 8

static void scan_text(const uint8_t *text, size_t length, uint32_t *finals,
                      uint32_t *transitions) {
    size_t pos = 0;
    while (pos < length) {
        unsigned state = 0;
        while (pos < length && state != 1) {
            uint8_t ch = text[pos];
            if (ch == ',') { ++pos; break; }
            int digit = ch >= '0' && ch <= '9';
            switch (state) {
            case 0:
                if (digit) state = 4;
                else if (ch == '+' || ch == '-') state = 2;
                else if (ch == '.') state = 5;
                else { state = 1; transitions[1]++; }
                transitions[0]++; break;
            case 2:
                if (digit) state = 4;
                else if (ch == '.') state = 5;
                else state = 1;
                transitions[2]++; break;
            case 4:
                if (ch == '.') { state = 5; transitions[4]++; }
                else if (!digit) { state = 1; transitions[4]++; }
                break;
            case 5:
                if (ch == 'e' || ch == 'E') { state = 3; transitions[5]++; }
                else if (!digit) { state = 1; transitions[5]++; }
                break;
            case 3:
                if (ch == '+' || ch == '-') state = 6; else state = 1;
                transitions[3]++; break;
            case 6:
                if (digit) state = 7; else state = 1;
                transitions[6]++; break;
            case 7:
                if (!digit) { state = 1; transitions[1]++; }
                break;
            }
            ++pos;
        }
        finals[state]++;
    }
}

static void put_u32_le(uint8_t *out, size_t at, uint32_t value) {
    for (size_t b = 0; b < 4; ++b) out[at + b] = (uint8_t)(value >> (8 * b));
}

int64_t numeric_token_state_machine(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_TEXT + 3) return -1;
    int64_t raw_n = input[0], step = input[1], seed = input[2];
    if (raw_n < 1 || raw_n > MAX_TEXT || length != (size_t)(raw_n + 3) ||
        step < 1 || step > 16 || seed < 1 || seed > 255) return -1;
    size_t n = (size_t)raw_n;
    uint8_t text[MAX_TEXT], original[MAX_TEXT];
    for (size_t i = 0; i < n; ++i) {
        if (input[3 + i] < 32 || input[3 + i] > 126) return -1;
        text[i] = original[i] = (uint8_t)input[3 + i];
    }
    if (text[0] == ',' || text[n - 1] == ',') return -1;
    for (size_t i = 1; i < n; ++i) if (text[i] == ',' && text[i - 1] == ',') return -1;
    for (size_t i = 0; i < n; i += (size_t)step)
        if (text[i] != ',' && ((uint8_t)(text[i] ^ (uint8_t)seed) == ',' || (uint8_t)(text[i] ^ (uint8_t)seed) == 0)) return -1;

    uint32_t finals[STATES] = {0}, transitions[STATES] = {0};
    scan_text(text, n, finals, transitions);
    for (size_t i = 0; i < n; i += (size_t)step)
        if (text[i] != ',') text[i] ^= (uint8_t)seed;
    scan_text(text, n, finals, transitions);
    for (size_t i = 0; i < n; i += (size_t)step)
        if (text[i] != ',') text[i] ^= (uint8_t)seed;

    if (output == NULL || capacity < 64) return -2;
    for (size_t i = 0; i < STATES; ++i) {
        put_u32_le(output, i * 8, finals[i]);
        put_u32_le(output, i * 8 + 4, transitions[i]);
    }
    return 64;
}
