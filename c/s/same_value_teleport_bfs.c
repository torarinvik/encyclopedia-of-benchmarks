#include <stddef.h>
#include <stdint.h>

int64_t same_value_teleport_bfs(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 65 || input[0] < 1 || input[0] > 64 ||
        length != (size_t)input[0] + 1) return -2;
    const int n = (int)input[0];
    for (int i = 0; i < n; ++i)
        if (input[i + 1] < -64 || input[i + 1] > 64) return -2;
    if (n == 1) return 0;

    int32_t first[129], next[64], queue[64], distance[64];
    for (int i = 0; i < 129; ++i) first[i] = -1;
    for (int i = 0; i < n; ++i) {
        int slot = (int)(input[i + 1] + 64);
        next[i] = first[slot];
        first[slot] = i;
        distance[i] = -1;
    }

    int front = 0, back = 1;
    queue[0] = 0;
    distance[0] = 0;
    while (front < back) {
        int index = queue[front++];
        if (index == n - 1) return distance[index];
        if (index > 0 && distance[index - 1] < 0) {
            distance[index - 1] = distance[index] + 1;
            queue[back++] = index - 1;
        }
        if (index + 1 < n && distance[index + 1] < 0) {
            distance[index + 1] = distance[index] + 1;
            queue[back++] = index + 1;
        }
        int slot = (int)(input[index + 1] + 64);
        int member = first[slot];
        if (member >= 0) {
            first[slot] = -1;
            while (member >= 0) {
                if (distance[member] < 0) {
                    distance[member] = distance[index] + 1;
                    queue[back++] = member;
                }
                member = next[member];
            }
        }
    }
    return distance[n - 1];
}
