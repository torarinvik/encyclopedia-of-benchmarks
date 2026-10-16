#include <cstddef>
#include <cstdint>

extern "C" int64_t board_path(const int64_t *input, size_t length) {
    if (!input || length != 2 || input[0] < 0 || input[1] < 0 || input[0] > 30 || input[1] > 30 || input[0] > input[1]) return -1;
    int64_t ways[31] = {};
    ways[input[1]] = 1;
    for (int i = static_cast<int>(input[1]) - 1; i >= static_cast<int>(input[0]); --i)
        for (int die = 1; die <= 6 && i + die <= input[1]; ++die) ways[i] += ways[i + die];
    return ways[input[0]];
}
