/* Group cubes by their sorted decimal digits and return the first cube in the target group. */
#include <stdint.h>

#define TABLE_SIZE 16384
#define MAX_BASE 8384
#define SIGNATURE_LENGTH_FACTOR INT64_C(4503599627370496)

static int64_t digit_signature(int64_t cube)
{
    int counts[10] = {0};
    int length = 0;
    if (cube == 0) {
        counts[0] = 1;
        length = 1;
    } else {
        while (cube > 0) {
            ++counts[cube % 10];
            ++length;
            cube /= 10;
        }
    }
    int64_t sorted_digits = 0;
    for (int digit = 0; digit < 10; ++digit)
        for (int occurrence = 0; occurrence < counts[digit]; ++occurrence)
            sorted_digits = sorted_digits * 16 + digit;
    return length * SIGNATURE_LENGTH_FACTOR + sorted_digits;
}

static int signature_slot(int64_t key)
{
    const int64_t size = TABLE_SIZE;
    const int64_t hash = (key % size + (key / size % size) * 31 +
                          (key / (size * size) % size) * 17 +
                          (key / (size * size * size) % size) * 7) % size;
    return (int)hash;
}

int64_t problem62(int64_t target_count)
{
    if (target_count < 1 || target_count > 5) return -1;
    int64_t keys[TABLE_SIZE] = {0};
    int64_t first_cubes[TABLE_SIZE] = {0};
    int counts[TABLE_SIZE] = {0};

    for (int64_t base = 0; base <= MAX_BASE; ++base) {
        const int64_t cube = base * base * base;
        const int64_t key = digit_signature(cube);
        int slot = signature_slot(key);
        while (keys[slot] != 0 && keys[slot] != key)
            slot = (slot + 1) % TABLE_SIZE;
        if (keys[slot] == 0) {
            keys[slot] = key;
            first_cubes[slot] = cube;
        }
        ++counts[slot];
        if (counts[slot] == target_count) return first_cubes[slot];
    }
    return -1;
}
