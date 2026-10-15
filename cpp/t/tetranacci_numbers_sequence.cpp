#include <cstdint>

extern "C" std::int64_t tetranacci_numbers_sequence(std::int64_t index) {
    if (index < 0 || index > 68) return -1;
    std::int64_t a = 1, b = 1, c = 1, d = 1;
    if (index <= 3) return 1;
    for (std::int64_t i = 4; i <= index; ++i) {
        const std::int64_t next = a + b + c + d;
        a = b;
        b = c;
        c = d;
        d = next;
    }
    return d;
}
