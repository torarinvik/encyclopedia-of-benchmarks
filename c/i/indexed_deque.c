#include <stddef.h>
#include <stdint.h>

int64_t indexed_deque(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 513 || input[0] < 1 || input[0] > 256) return -1;
    int q = (int)input[0];
    if (length != 1 + 2*(size_t)q) return -1;
    int64_t items[256], answers[256];
    int head = 0, size = 0, count = 0;
    for (int i = 0; i < q; ++i) {
        int64_t op = input[1+2*i], arg = input[2+2*i];
        if (op == 0 || op == 1) {
            if (arg < -1000000 || arg > 1000000 || size == 256) return -1;
            if (op == 0) { head = (head + 255) % 256; items[head] = arg; }
            else items[(head + size) % 256] = arg;
            ++size;
        } else if (op == 2 || op == 3) {
            if (arg != 0 || size == 0) return -1;
            if (op == 2) head = (head + 1) % 256;
            --size;
        } else if (op == 4) {
            if (arg < 0 || arg >= size) return -1;
            answers[count++] = items[(head + (int)arg) % 256];
        } else return -1;
    }
    if (count == 0) return -1;
    if (!output || capacity < 8*(size_t)count) return -2;
    for (int i = 0; i < count; ++i) {
        uint64_t bits = (uint64_t)answers[i];
        for (int byte = 0; byte < 8; ++byte) output[8*i+byte] = (uint8_t)(bits >> (8*byte));
    }
    return 8*count;
}
