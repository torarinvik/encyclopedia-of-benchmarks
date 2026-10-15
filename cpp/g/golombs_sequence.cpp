#include <cstdint>

extern "C" std::int64_t golombs_sequence(std::int64_t index) {
    if (index < 0 || index > 64) return -1;
    if (index == 0) return 1;
    if (index <= 2) return 2;
    std::int64_t queue[65] = {2};
    std::int64_t head = 0;
    std::int64_t tail = 1;
    std::int64_t generated = 3;
    for (std::int64_t value = 3; generated <= index; ++value) {
        const std::int64_t repetitions = queue[head++];
        for (std::int64_t j = 0; j < repetitions && generated <= index; ++j) {
            queue[tail++] = value;
            if (generated == index) return value;
            ++generated;
        }
    }
    return -1;
}
