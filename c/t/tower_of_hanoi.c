#include <stddef.h>
#include <stdint.h>

static size_t emit_hanoi(size_t disks, uint8_t source, uint8_t destination, uint8_t auxiliary,
                         uint8_t *output, size_t position)
{
    if (disks == 0) return position;
    position = emit_hanoi(disks - 1, source, auxiliary, destination, output, position);
    output[position] = source;
    output[position + 1] = destination;
    return emit_hanoi(disks - 1, auxiliary, destination, source, output, position + 2);
}

int64_t tower_of_hanoi(const int64_t *values, size_t length,
                       uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 4 || values[0] < 0 || values[0] > 12) return -1;
    for (size_t index = 1; index < 4; ++index)
        if (values[index] < 0 || values[index] > 2) return -1;
    if (values[1] == values[2] || values[1] == values[3] || values[2] == values[3]) return -1;
    const size_t disks = (size_t)values[0];
    const size_t move_count = ((size_t)1 << disks) - 1;
    const size_t required = move_count * 2;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    emit_hanoi(disks, (uint8_t)values[1], (uint8_t)values[2], (uint8_t)values[3], output, 0);
    return (int64_t)move_count;
}
