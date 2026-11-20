#include <stddef.h>
#include <stdint.h>

int64_t egg_drop_max_floors_by_moves(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    const int64_t eggs = input[0], moves = input[1];
    if (eggs < 0 || eggs > 32 || moves < 0 || moves > 32) return -1;
    int64_t covered[33] = {0};
    for (int64_t move = 0; move < moves; ++move)
        for (int64_t egg_count = eggs; egg_count > 0; --egg_count)
            covered[egg_count] += covered[egg_count - 1] + 1;
    return covered[eggs];
}
