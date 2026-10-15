#include <stdint.h>

int64_t cubes_sequence(int64_t index) {
    if (index < 0 || index > 2097151) return -1;
    return index * index * index;
}
