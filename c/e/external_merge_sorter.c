/* Bottom-up merge passes over two bounded buffers, modeling sequential stores. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 4096

static void merge_pass(const int64_t *source, int64_t *destination,
                       size_t length, size_t width)
{
    for (size_t start = 0; start < length; start += width * 2) {
        size_t middle = start + width;
        if (middle > length) middle = length;
        size_t end = middle + width;
        if (end > length) end = length;
        size_t left = start, right = middle, out = start;
        while (left < middle && right < end)
            destination[out++] = source[left] < source[right] ? source[left++] : source[right++];
        while (left < middle) destination[out++] = source[left++];
        while (right < end) destination[out++] = source[right++];
    }
}

int64_t external_merge_sorter(const int64_t *values, size_t length,
                              uint8_t *output, size_t output_capacity)
{
    if (length > MAX_VALUES || (length != 0 && values == NULL)) return -1;
    const size_t output_bytes = length * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;

    int64_t primary[MAX_VALUES], temporary[MAX_VALUES];
    for (size_t index = 0; index < length; ++index) primary[index] = values[index];
    int64_t *source = primary, *destination = temporary;
    for (size_t width = 1; width < length;) {
        merge_pass(source, destination, length, width);
        int64_t *swap = source;
        source = destination;
        destination = swap;
        if (width > length / 2) break;
        width *= 2;
    }

    for (size_t index = 0; index < length; ++index) {
        const uint64_t bits = (uint64_t)source[index];
        for (size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)output_bytes;
}
