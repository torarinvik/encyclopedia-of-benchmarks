/* Return whether every room is reachable from room zero. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ROOMS 1000
#define MAX_INPUT_LENGTH 100001

int64_t keys_and_rooms(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 2 || values[0] > MAX_ROOMS) return -1;
    const size_t room_count = (size_t)values[0];
    size_t starts[MAX_ROOMS];
    size_t degrees[MAX_ROOMS];
    size_t cursor = 1;

    for (size_t room = 0; room < room_count; ++room) {
        if (cursor >= length) return -1;
        const int64_t count_value = values[cursor++];
        if (count_value < 0 || count_value > (int64_t)room_count) return -1;
        const size_t degree = (size_t)count_value;
        if (degree > length - cursor) return -1;
        starts[room] = cursor;
        degrees[room] = degree;
        for (size_t edge = 0; edge < degree; ++edge) {
            if (values[cursor + edge] < 0 || values[cursor + edge] >= (int64_t)room_count) return -1;
        }
        cursor += degree;
    }
    if (cursor != length) return -1;

    uint8_t visited[MAX_ROOMS] = {0};
    size_t stack[MAX_ROOMS];
    size_t stack_size = 1;
    size_t reached = 0;
    stack[0] = 0;
    visited[0] = 1;
    while (stack_size > 0) {
        const size_t room = stack[--stack_size];
        ++reached;
        for (size_t edge = 0; edge < degrees[room]; ++edge) {
            const size_t key = (size_t)values[starts[room] + edge];
            if (!visited[key]) {
                visited[key] = 1;
                stack[stack_size++] = key;
            }
        }
    }
    return reached == room_count ? 1 : 0;
}
