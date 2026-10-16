#include <stddef.h>
#include <stdint.h>

#define MAX_TARGET 8

static size_t required_bytes(size_t remaining, size_t depth)
{
    if (remaining == 0) return depth + 1;
    size_t total = 0;
    const size_t maximum_face = remaining < 6 ? remaining : 6;
    for (size_t face = 1; face <= maximum_face; ++face)
        total += required_bytes(remaining - face, depth + 1);
    return total;
}

static void emit_combinations(size_t remaining, size_t depth, uint8_t *digits,
                              uint8_t *output, size_t *position)
{
    if (remaining == 0) {
        for (size_t index = 0; index < depth; ++index) output[(*position)++] = digits[index];
        output[(*position)++] = (uint8_t)'\n';
        return;
    }
    const size_t maximum_face = remaining < 6 ? remaining : 6;
    for (size_t face = 1; face <= maximum_face; ++face) {
        digits[depth] = (uint8_t)('0' + face);
        emit_combinations(remaining - face, depth + 1, digits, output, position);
    }
}

int64_t dice_thrower(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 1 || values[0] < 0 || values[0] > MAX_TARGET) return -1;
    const size_t target = (size_t)values[0];
    const size_t needed = required_bytes(target, 0);
    if (output_capacity < needed || output == NULL) return -2;
    uint8_t digits[MAX_TARGET];
    size_t position = 0;
    emit_combinations(target, 0, digits, output, &position);
    return (int64_t)position;
}
