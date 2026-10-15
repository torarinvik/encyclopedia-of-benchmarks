#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 100000
#define MAX_VALUE 100000
#define REQUIRED_WORKSPACE (4u * (MAX_VALUE + 1u))

static int32_t read_state(const uint8_t *workspace, size_t value)
{
    const size_t position = 4 * value;
    const uint32_t encoded = (uint32_t)workspace[position] |
        ((uint32_t)workspace[position + 1] << 8) |
        ((uint32_t)workspace[position + 2] << 16) |
        ((uint32_t)workspace[position + 3] << 24);
    return (int32_t)encoded;
}

static void write_state(uint8_t *workspace, size_t value, int32_t state)
{
    const uint32_t encoded = (uint32_t)state;
    const size_t position = 4 * value;
    workspace[position] = (uint8_t)encoded;
    workspace[position + 1] = (uint8_t)(encoded >> 8);
    workspace[position + 2] = (uint8_t)(encoded >> 16);
    workspace[position + 3] = (uint8_t)(encoded >> 24);
}

static int64_t streak_from(uint8_t *workspace, size_t value)
{
    const int32_t state = read_state(workspace, value);
    if (state > 1) return (int64_t)state - 1;
    int64_t length = 1;
    const uint64_t square = (uint64_t)value * (uint64_t)value;
    if (square <= MAX_VALUE && read_state(workspace, (size_t)square) != 0)
        length += streak_from(workspace, (size_t)square);
    write_state(workspace, value, (int32_t)(length + 1));
    return length;
}

int64_t longest_square_streak(const int64_t *values, size_t length,
                              uint8_t *workspace, size_t workspace_capacity)
{
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH + 1u ||
        values[0] < 2 || values[0] > MAX_INPUT_LENGTH ||
        length != (size_t)values[0] + 1u) return -1;
    const size_t count = (size_t)values[0];
    for (size_t index = 0; index < count; ++index)
        if (values[index + 1] < 2 || values[index + 1] > MAX_VALUE) return -1;
    if (workspace == NULL || workspace_capacity < REQUIRED_WORKSPACE) return -2;

    for (size_t byte = 0; byte < REQUIRED_WORKSPACE; ++byte) workspace[byte] = 0;
    for (size_t index = 0; index < count; ++index)
        write_state(workspace, (size_t)values[index + 1], 1);
    int64_t longest = 1;
    for (size_t index = 0; index < count; ++index) {
        const int64_t length_from_value = streak_from(workspace, (size_t)values[index + 1]);
        if (length_from_value > longest) longest = length_from_value;
    }
    return longest >= 2 ? longest : -1;
}
