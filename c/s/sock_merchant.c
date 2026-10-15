#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 512
#define COLOR_COUNT 4096

int64_t sock_merchant(const int64_t *colors, size_t length)
{
    if (length > MAX_LENGTH || (length > 0 && colors == NULL)) return -1;
    size_t counts[COLOR_COUNT] = {0};
    for (size_t i = 0; i < length; ++i) {
        if (colors[i] < 0 || colors[i] >= COLOR_COUNT) return -1;
        ++counts[(size_t)colors[i]];
    }
    size_t pairs = 0;
    for (size_t color = 0; color < COLOR_COUNT; ++color) pairs += counts[color] / 2;
    return (int64_t)pairs;
}
