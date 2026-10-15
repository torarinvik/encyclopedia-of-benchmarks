#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 64

static int64_t rotated_digit(int64_t value)
{
    switch (value) {
        case '0': return '0';
        case '1': return '1';
        case '6': return '9';
        case '8': return '8';
        case '9': return '6';
        default: return -1;
    }
}

int64_t strobogrammatic_number(const int64_t *bytes, size_t length)
{
    if ((bytes == NULL && length != 0) || length > MAX_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (bytes[index] < 0 || bytes[index] > 127) return -1;
    }
    for (size_t left = 0, right = length; left < right;) {
        --right;
        if (rotated_digit(bytes[left]) != bytes[right]) return 0;
        ++left;
    }
    return 1;
}
