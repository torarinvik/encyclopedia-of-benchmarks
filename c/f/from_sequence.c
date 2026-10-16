#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_NODES 128
#define MAX_OUTPUT 3589

static size_t append_i64(uint8_t *buffer, size_t position, int64_t value) {
    uint8_t reversed[20];
    size_t length = 0;
    uint64_t magnitude;
    if (value < 0) magnitude = (uint64_t)(-(value + 1)) + 1;
    else magnitude = (uint64_t)value;
    do {
        reversed[length++] = (uint8_t)('0' + magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    buffer[position++] = '<';
    if (value < 0) buffer[position++] = '-';
    while (length > 0) buffer[position++] = reversed[--length];
    buffer[position++] = '>';
    memcpy(buffer + position, " ---> ", 6);
    return position + 6;
}

int64_t from_sequence(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_NODES + 1) return -1;
    int64_t count = input[0];
    if (count < 1 || count > MAX_NODES || length != (size_t)count + 1) return -1;
    uint8_t buffer[MAX_OUTPUT];
    size_t position = 0;
    for (int64_t i = 0; i < count; ++i) position = append_i64(buffer, position, input[i + 1]);
    memcpy(buffer + position, "<END>", 5);
    position += 5;
    if (output == NULL || capacity < position) return -2;
    memcpy(output, buffer, position);
    return (int64_t)position;
}
