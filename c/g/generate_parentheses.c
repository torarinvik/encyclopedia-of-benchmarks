#include <stddef.h>
#include <stdint.h>

static void generate(int pairs, int opened, int closed, uint8_t *buffer,
                     uint8_t *output, size_t *cursor)
{
    const int position = opened + closed;
    if (position == 2 * pairs) {
        for (int index = 0; index < position; ++index) output[(*cursor)++] = buffer[index];
        return;
    }
    if (opened < pairs) {
        buffer[position] = '(';
        generate(pairs, opened + 1, closed, buffer, output, cursor);
    }
    if (closed < opened) {
        buffer[position] = ')';
        generate(pairs, opened, closed + 1, buffer, output, cursor);
    }
}

int64_t generate_parentheses(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    static const size_t required_bytes[7] = {0, 2, 8, 30, 112, 420, 1584};
    if (input == NULL || length != 1 || input[0] < 1 || input[0] > 6) return -1;
    const int pairs = (int)input[0];
    const size_t required = required_bytes[pairs];
    if (capacity < required || output == NULL) return -2;
    uint8_t buffer[12];
    size_t cursor = 0;
    generate(pairs, 0, 0, buffer, output, &cursor);
    return (int64_t)cursor;
}
