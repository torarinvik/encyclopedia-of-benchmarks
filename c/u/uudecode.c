#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_BYTES 4096
#define MAX_OUTPUT_BYTES 2949

static const uint8_t HEADER[] = "begin 755 uustart.file \n";

static int scan_input(const int64_t *input, size_t length, size_t *decoded_length)
{
    if (input == NULL || length > MAX_INPUT_BYTES) return 0;
    for (size_t i = 0; i < length; ++i)
        if (input[i] < 0 || input[i] > 255) return 0;
    if (length < sizeof(HEADER) - 1 + 5) return 0;
    for (size_t i = 0; i < sizeof(HEADER) - 1; ++i)
        if (input[i] != HEADER[i]) return 0;

    size_t offset = sizeof(HEADER) - 1;
    size_t total = 0;
    for (;;) {
        if (offset >= length) return 0;
        const int count_symbol = (int)input[offset++];
        if (count_symbol == 32) {
            if (offset + 4 != length || input[offset] != 10 ||
                input[offset + 1] != 'e' || input[offset + 2] != 'n' ||
                input[offset + 3] != 'd') return 0;
            *decoded_length = total;
            return total <= MAX_OUTPUT_BYTES;
        }
        const int count = count_symbol - 32;
        if (count < 1 || count > 45) return 0;
        const size_t encoded_length = 4u * (((size_t)count + 2u) / 3u);
        if (offset + encoded_length >= length || input[offset + encoded_length] != 10)
            return 0;
        for (size_t i = 0; i < encoded_length; ++i)
            if (input[offset + i] < 32 || input[offset + i] > 95) return 0;
        total += (size_t)count;
        if (total > MAX_OUTPUT_BYTES) return 0;
        offset += encoded_length + 1;
    }
}

int64_t uudecode(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    size_t decoded_length = 0;
    if (!scan_input(input, length, &decoded_length)) return -1;
    if (output == NULL || capacity < decoded_length) return -2;

    size_t offset = sizeof(HEADER) - 1;
    size_t written = 0;
    for (;;) {
        const size_t count = (size_t)(input[offset++] - 32);
        if (count == 0) break;
        const size_t encoded_length = 4u * ((count + 2u) / 3u);
        size_t emitted = 0;
        for (size_t group = 0; group < encoded_length; group += 4) {
            const unsigned a = (unsigned)(input[offset++] - 32);
            const unsigned b = (unsigned)(input[offset++] - 32);
            const unsigned c = (unsigned)(input[offset++] - 32);
            const unsigned d = (unsigned)(input[offset++] - 32);
            output[written++] = (uint8_t)((a << 2) | (b >> 4));
            ++emitted;
            if (emitted < count) {
                output[written++] = (uint8_t)((b << 4) | (c >> 2));
                ++emitted;
            }
            if (emitted < count) {
                output[written++] = (uint8_t)((c << 6) | d);
                ++emitted;
            }
        }
        offset++;
    }
    return (int64_t)written;
}
