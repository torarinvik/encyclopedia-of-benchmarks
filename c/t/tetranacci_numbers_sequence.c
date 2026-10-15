#include <stdint.h>

int64_t tetranacci_numbers_sequence(int64_t index) {
    if (index < 0 || index > 68) return -1;
    int64_t a = 1, b = 1, c = 1, d = 1;
    if (index <= 3) return 1;
    for (int64_t i = 4; i <= index; ++i) {
        int64_t next = a + b + c + d;
        a = b;
        b = c;
        c = d;
        d = next;
    }
    return d;
}
