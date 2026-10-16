#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 1024
#define BLOCKS 512
#define BLOCK_SIZE 5

int64_t unrolled_linked_list_benchmark(const int64_t *values, size_t length)
{
    if (length > MAX_ITEMS) return -1;
    int64_t chunks[BLOCKS][BLOCK_SIZE] = {{0}};
    size_t counts[BLOCKS] = {0}, blocks = 0;
    int64_t next[BLOCKS];
    for (size_t i = 0; i < BLOCKS; ++i) next[i] = -1;
    for (size_t i = 0; i < length; ++i) {
        const int64_t value = values[i];
        if (value < -1000000 || value > 1000000) return -1;
        if (blocks == 0) { blocks = 1; counts[0] = 1; chunks[0][0] = value; continue; }
        size_t tail = blocks - 1;
        if (counts[tail] < 4) chunks[tail][counts[tail]++] = value;
        else {
            size_t keep = counts[tail] / 2 + 1;
            size_t moved = counts[tail] - keep;
            for (size_t j = 0; j < moved; ++j) chunks[blocks][j] = chunks[tail][keep + j];
            counts[tail] = keep;
            chunks[blocks][moved] = value;
            counts[blocks] = moved + 1;
            next[tail] = (int64_t)blocks;
            ++blocks;
        }
    }
    int64_t checksum = 0;
    size_t index = 0, block = 0;
    while (block < BLOCKS) {
        for (size_t slot = 0; slot < counts[block]; ++slot, ++index)
            checksum += (int64_t)(index + 1) * (chunks[block][slot] + 1000000);
        if (next[block] < 0) break;
        block = (size_t)next[block];
    }
    return checksum;
}
