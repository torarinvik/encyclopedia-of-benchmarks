#include <stddef.h>
#include <stdint.h>

#define MAX_FACES 8
#define MAX_DICE 8
#define MAX_TARGET 64

int64_t dice_throw(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return -1;
    const int64_t faces_value = values[0];
    const int64_t dice_value = values[1];
    const int64_t target_value = values[2];
    if (faces_value < 1 || faces_value > MAX_FACES || dice_value < 1 || dice_value > MAX_DICE ||
        target_value < 0 || target_value > MAX_TARGET) return -1;
    const size_t faces = (size_t)faces_value;
    const size_t dice = (size_t)dice_value;
    const size_t target = (size_t)target_value;

    int64_t table[MAX_DICE + 1][MAX_TARGET + 1] = {{0}};
    for (size_t total = 1; total <= faces && total <= target; ++total) table[1][total] = 1;
    for (size_t die = 2; die <= dice; ++die) {
        for (size_t total = 1; total <= target; ++total) {
            for (size_t face = 1; face < total && face <= faces; ++face) {
                table[die][total] += table[die - 1][total - face];
            }
        }
    }
    return table[dice][target];
}
