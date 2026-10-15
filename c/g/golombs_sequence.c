#include <stdint.h>

int64_t golombs_sequence(int64_t index) {
    if (index < 0 || index > 64) return -1;
    if (index == 0) return 1;
    if (index <= 2) return 2;
    int64_t queue[65] = {2};
    int64_t head = 0;
    int64_t tail = 1;
    int64_t generated = 3;
    for (int64_t value = 3; generated <= index; ++value) {
        int64_t repetitions = queue[head++];
        for (int64_t j = 0; j < repetitions && generated <= index; ++j) {
            queue[tail++] = value;
            if (generated == index) return value;
            ++generated;
        }
    }
    return -1;
}
