#include <cstdint>

extern "C" std::int64_t recamans_sequence(std::int64_t index) {
    if (index < 0 || index > 32) return -1;
    bool seen[529] = {};
    seen[0] = true;
    std::int64_t previous = 0;
    for (std::int64_t step = 1; step <= index; ++step) {
        std::int64_t candidate = previous - step;
        if (candidate < 0 || seen[candidate]) candidate = previous + step;
        seen[candidate] = true;
        previous = candidate;
    }
    return previous;
}
