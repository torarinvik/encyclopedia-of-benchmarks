#include <cstdint>

extern "C" std::int64_t van_ecks_sequence(std::int64_t position) {
    if (position < 1 || position > 16) return -1;
    std::int64_t last_seen[17] = {};
    std::int64_t previous = 0;
    for (std::int64_t current = 2; current <= position; ++current) {
        const std::int64_t next = last_seen[previous] == 0 ? 0 : current - last_seen[previous];
        last_seen[previous] = current;
        previous = next;
    }
    return previous;
}
