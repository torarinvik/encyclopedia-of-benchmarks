#include <stddef.h>
#include <stdint.h>
#define MAX_LENGTH 4096
static int punctuation(int64_t value) {
    return (value >= 33 && value <= 47) || (value >= 58 && value <= 64) ||
           (value >= 91 && value <= 96) || (value >= 123 && value <= 126);
}
static int fold(int64_t value) { return value >= 'A' && value <= 'Z' ? (int)(value + 32) : (int)value; }
int64_t findpalindrome(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) if (input[i] < 32 || input[i] > 126) return -1;
    size_t written = 0, segment = 0; int found = 0;
    for (size_t end = 0; end <= length; ++end) {
        if (end < length && input[end] != 32) continue;
        size_t left = segment, right = end, token_length = 0;
        while (left < right) { if (punctuation(input[left])) ++left; else { ++token_length; ++left; } }
        left = segment; right = end;
        while (left < right) {
            while (left < right && punctuation(input[left])) ++left;
            while (left < right && punctuation(input[right - 1])) --right;
            if (left >= right) break;
            if (fold(input[left]) != fold(input[right - 1])) { token_length = 0; break; }
            ++left; --right;
        }
        if (token_length > 1) {
            if (written + (size_t)found + token_length > output_capacity) return -2;
            if (found) output[written++] = 0;
            for (size_t i = segment; i < end; ++i) if (!punctuation(input[i])) output[written++] = (uint8_t)input[i];
            found = 1;
        }
        segment = end + 1;
    }
    return (int64_t)written;
}
