#include <cstdint>

extern "C" std::int64_t cubes_sequence(std::int64_t index) {
    if (index < 0 || index > 2097151) return -1;
    return index * index * index;
}
