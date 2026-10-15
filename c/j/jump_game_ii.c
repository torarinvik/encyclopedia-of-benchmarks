/* Breadth-first search over forward-reachable indices. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024

int64_t jump_game_ii(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > (int64_t)length) return -1;
    if (length == 1) return 0;

    size_t queue[MAX_LENGTH];
    size_t distance[MAX_LENGTH] = {0};
    bool visited[MAX_LENGTH] = {false};
    size_t head = 0, tail = 1;
    queue[0] = 0;
    visited[0] = true;
    while (head < tail) {
        const size_t cell = queue[head++];
        const size_t farthest = cell + (size_t)values[cell];
        if (farthest >= length - 1) return (int64_t)distance[cell] + 1;
        for (size_t next = cell + 1; next <= farthest; ++next) {
            if (!visited[next]) {
                visited[next] = true;
                distance[next] = distance[cell] + 1;
                queue[tail++] = next;
            }
        }
    }
    return -1;
}
