#include <cstdint>

static bool next_permutation_indices(std::int64_t *indices, int length) noexcept
{
    int pivot = length - 2;
    while (pivot >= 0 && indices[pivot] >= indices[pivot + 1]) --pivot;
    if (pivot < 0) return false;
    int successor = length - 1;
    while (indices[successor] <= indices[pivot]) --successor;
    const auto temporary = indices[pivot];
    indices[pivot] = indices[successor];
    indices[successor] = temporary;
    for (int left = pivot + 1, right = length - 1; left < right; ++left, --right) {
        const auto value = indices[left]; indices[left] = indices[right]; indices[right] = value;
    }
    return true;
}

extern "C" std::int64_t problem68(std::int64_t gon_side) noexcept
{
    if (gon_side < 3 || gon_side > 5) return -1;
    const int n = static_cast<int>(gon_side), length = 2 * static_cast<int>(gon_side);
    std::int64_t values[10];
    int cursor = 0;
    for (int value = n + 1; value >= 1; --value) values[cursor++] = value;
    for (int value = n + 2; value <= 2 * n; ++value) values[cursor++] = value;
    std::int64_t indices[10];
    for (int i = 0; i < length; ++i) indices[i] = i;
    do {
        const auto total = values[indices[0]] + values[indices[1]] + values[indices[2]];
        bool magic = true;
        auto minimum_outer = values[indices[0]];
        for (int line = 1; line < n; ++line) {
            const int outer = line == n - 1 ? 2 * n - 1 : 2 * line + 1;
            const int inner_left = 2 * line;
            const int inner_right = line == n - 1 ? 1 : 2 * line + 2;
            if (values[indices[outer]] + values[indices[inner_left]] + values[indices[inner_right]] != total) magic = false;
            if (values[indices[outer]] < minimum_outer) minimum_outer = values[indices[outer]];
        }
        if (magic && values[indices[0]] == minimum_outer) {
            std::int64_t result = 0;
            for (int line = 0; line < n; ++line) {
                const int outer = line == 0 ? 0 : (line == n - 1 ? 2 * n - 1 : 2 * line + 1);
                const int inner_left = line == 0 ? 1 : 2 * line;
                const int inner_right = line == n - 1 ? 1 : (line == 0 ? 2 : 2 * line + 2);
                const std::int64_t triple[3] = {values[indices[outer]], values[indices[inner_left]], values[indices[inner_right]]};
                for (const auto value : triple) result = result * (value >= 10 ? 100 : 10) + value;
            }
            return result;
        }
    } while (next_permutation_indices(indices, length));
    return -1;
}
