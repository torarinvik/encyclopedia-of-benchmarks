#include <stddef.h>
#include <stdint.h>

int64_t lipogram(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 1026 || input[0] < 0 || input[0] > 1024 || length != (size_t)input[0] + 2) return -1;
    const size_t n = (size_t)input[0];
    const int64_t mask = input[length - 1];
    if (mask < 0 || mask > 67108863) return -1;
    uint32_t seen = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t ch = input[i + 1];
        if (ch >= 'A' && ch <= 'Z') ch += 'a' - 'A';
        if (ch >= 'a' && ch <= 'z') seen |= UINT32_C(1) << (unsigned)(ch - 'a');
        else if (ch != 9 && ch != 10 && ch != 11 && ch != 12 && ch != 13 && ch != 32) return -1;
    }
    const uint32_t alphabet = (UINT32_C(1) << 26) - 1;
    return (int64_t)(alphabet & ~seen) == mask ? 1 : 0;
}
