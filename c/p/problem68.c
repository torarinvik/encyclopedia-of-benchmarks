#include <stdint.h>

static int next_permutation(int64_t *indices, int length)
{
    int pivot = length - 2;
    while (pivot >= 0 && indices[pivot] >= indices[pivot + 1]) --pivot;
    if (pivot < 0) return 0;
    int successor = length - 1;
    while (indices[successor] <= indices[pivot]) --successor;
    int64_t temporary = indices[pivot];
    indices[pivot] = indices[successor];
    indices[successor] = temporary;
    for (int left = pivot + 1, right = length - 1; left < right; ++left, --right) {
        temporary = indices[left];
        indices[left] = indices[right];
        indices[right] = temporary;
    }
    return 1;
}

int64_t problem68(int64_t gon_side)
{
    if (gon_side < 3 || gon_side > 5) return -1;
    int n = (int)gon_side;
    int length = 2 * n;
    int64_t values[10];
    int cursor = 0;
    for (int value = n + 1; value >= 1; --value) values[cursor++] = value;
    for (int value = n + 2; value <= 2 * n; ++value) values[cursor++] = value;
    int64_t indices[10];
    for (int i = 0; i < length; ++i) indices[i] = i;

    do {
        int64_t total = values[indices[0]] + values[indices[1]] + values[indices[2]];
        int magic = 1;
        int64_t minimum_outer = values[indices[0]];
        for (int line = 1; line < n; ++line) {
            int outer = line == n - 1 ? 2 * n - 1 : 2 * line + 1;
            int inner_left = 2 * line;
            int inner_right = line == n - 1 ? 1 : 2 * line + 2;
            if (values[indices[outer]] + values[indices[inner_left]] + values[indices[inner_right]] != total) magic = 0;
            if (values[indices[outer]] < minimum_outer) minimum_outer = values[indices[outer]];
        }
        if (magic && values[indices[0]] == minimum_outer) {
            int64_t result = 0;
            for (int line = 0; line < n; ++line) {
                int outer = line == 0 ? 0 : (line == n - 1 ? 2 * n - 1 : 2 * line + 1);
                int inner_left = line == 0 ? 1 : 2 * line;
                int inner_right = line == n - 1 ? 1 : (line == 0 ? 2 : 2 * line + 2);
                int64_t triple[3] = {values[indices[outer]], values[indices[inner_left]], values[indices[inner_right]]};
                for (int part = 0; part < 3; ++part) result = result * (triple[part] >= 10 ? 100 : 10) + triple[part];
            }
            return result;
        }
    } while (next_permutation(indices, length));
    return -1;
}
