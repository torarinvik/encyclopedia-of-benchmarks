#include <stddef.h>
#include <stdint.h>

static int popcount_byte(unsigned value) {
    int count = 0;
    for (int bit = 0; bit < 8; ++bit) count += (int)((value >> bit) & 1u);
    return count;
}

static unsigned decode(int class_count, int offset) {
    for (unsigned candidate = 0; candidate < 256; ++candidate) {
        if (popcount_byte(candidate) == class_count) {
            if (offset == 0) return candidate;
            --offset;
        }
    }
    return 0;
}

int64_t rrr_class_offset_rank_select(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 35 || input[0] < 1 || input[0] > 63 || input[1] < 0 || input[2] < 0 || input[2] > 16) return -1;
    int n = (int)input[0], q = (int)input[2];
    uint64_t bits = (uint64_t)input[1];
    if ((bits >> n) != 0 || length != (size_t)(3+2*q)) return -1;
    for (int i = 0; i < q; ++i) {
        int64_t op = input[3+2*i], index = input[4+2*i];
        if ((op == 0 && (index < 1 || index > n)) ||
            (op == 1 && (index < 1 || index > 64)) || (op != 0 && op != 1)) return -1;
    }
    if (output == NULL || capacity < (size_t)(8*q)) return -2;
    int classes[8], offsets[8], prefix[9] = {0};
    int blocks = (n+7)/8;
    for (int block = 0; block < blocks; ++block) {
        unsigned byte = (unsigned)((bits >> (8*block)) & 255u);
        classes[block] = popcount_byte(byte);
        offsets[block] = 0;
        for (unsigned candidate = 0; candidate < byte; ++candidate)
            if (popcount_byte(candidate) == classes[block]) ++offsets[block];
        prefix[block+1] = prefix[block] + classes[block];
    }
    for (int i = 0; i < q; ++i) {
        int op = (int)input[3+2*i], index = (int)input[4+2*i], answer = -1;
        if (op == 0) {
            int block = (index-1)/8, count = index - 8*block;
            unsigned byte = decode(classes[block], offsets[block]);
            answer = prefix[block];
            for (int bit = 0; bit < count; ++bit) answer += (int)((byte >> bit) & 1u);
        } else {
            int block = 0;
            while (block < blocks && prefix[block+1] < index) ++block;
            if (block < blocks) {
                int remaining = index-prefix[block];
                unsigned byte = decode(classes[block], offsets[block]);
                for (int bit = 0; bit < 8 && 8*block+bit < n; ++bit) {
                    if ((byte >> bit) & 1u) {
                        --remaining;
                        if (remaining == 0) { answer = 8*block+bit+1; break; }
                    }
                }
            }
        }
        uint64_t encoded = (uint64_t)(int64_t)answer;
        for (int j = 0; j < 8; ++j) output[8*i+j] = (uint8_t)(encoded >> (8*j));
    }
    return 8*q;
}
