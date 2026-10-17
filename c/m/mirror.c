#include <stddef.h>
#include <stdint.h>

#define MIRROR_MAX_LENGTH 256
#define MIRROR_MAX_INPUT_LENGTH (MIRROR_MAX_LENGTH + 1)

static char *miroir(char *s) {
    size_t n = 0;
    while (s[n] != '\0') ++n;
    if (n == 0) return s;
    size_t i = 0, k = n - 1;
    while (i <= k) {
        char aux = s[i];
        s[i] = s[k];
        s[k] = aux;
        ++i;
        if (k == 0) break;
        --k;
    }
    return s;
}

int64_t mirror(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MIRROR_MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MIRROR_MAX_LENGTH) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 1 || input[i + 1] > 127) return -1;
    }
    if (output == NULL || capacity < n + 1) return -2;
    char buffer[MIRROR_MAX_INPUT_LENGTH];
    for (size_t i = 0; i < n; ++i) buffer[i] = (char)input[i + 1];
    buffer[n] = '\0';
    char *mirrored = miroir(buffer);
    for (size_t i = 0; i < n; ++i) output[i] = (uint8_t)mirrored[i];
    output[n] = 0;
    return (int64_t)n;
}
