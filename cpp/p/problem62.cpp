/* Group cubes by their sorted decimal digits and return the first cube in the target group. */
#include <cstdint>

namespace {
constexpr int TABLE_SIZE = 16384;
constexpr std::int64_t MAX_BASE = 8384;
constexpr std::int64_t SIGNATURE_LENGTH_FACTOR = 4'503'599'627'370'496LL;

std::int64_t digit_signature(std::int64_t cube)
{
    int counts[10] = {};
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
    std::int64_t sorted_digits = 0;
    for (int digit = 0; digit < 10; ++digit)
        for (int occurrence = 0; occurrence < counts[digit]; ++occurrence)
            sorted_digits = sorted_digits * 16 + digit;
    return length * SIGNATURE_LENGTH_FACTOR + sorted_digits;
}

int signature_slot(std::int64_t key)
{
    constexpr std::int64_t size = TABLE_SIZE;
    const auto hash = (key % size + (key / size % size) * 31 +
                       (key / (size * size) % size) * 17 +
                       (key / (size * size * size) % size) * 7) % size;
    return static_cast<int>(hash);
}
}

extern "C" std::int64_t problem62(std::int64_t target_count) noexcept
{
    if (target_count < 1 || target_count > 5) return -1;
    std::int64_t keys[TABLE_SIZE] = {};
    std::int64_t first_cubes[TABLE_SIZE] = {};
    int counts[TABLE_SIZE] = {};

    for (std::int64_t base = 0; base <= MAX_BASE; ++base) {
        const auto cube = base * base * base;
        const auto key = digit_signature(cube);
        auto slot = signature_slot(key);
        while (keys[slot] != 0 && keys[slot] != key) slot = (slot + 1) % TABLE_SIZE;
        if (keys[slot] == 0) {
            keys[slot] = key;
            first_cubes[slot] = cube;
        }
        ++counts[slot];
        if (counts[slot] == target_count) return first_cubes[slot];
    }
    return -1;
}
