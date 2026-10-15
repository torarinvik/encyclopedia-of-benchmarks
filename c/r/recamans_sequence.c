#include <stdint.h>

int64_t recamans_sequence(int64_t index) {
    if (index < 0 || index > 32) return -1;
    uint8_t seen[529] = {0};
    seen[0] = 1;
    int64_t previous = 0;
    for (int64_t step = 1; step <= index; ++step) {
        int64_t candidate = previous - step;
        if (candidate < 0 || seen[candidate]) candidate = previous + step;
        seen[candidate] = 1;
        previous = candidate;
    }
    return previous;
}
