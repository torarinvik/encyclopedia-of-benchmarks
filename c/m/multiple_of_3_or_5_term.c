#include <stdint.h>

int64_t multiple_of_3_or_5_term(int64_t n) {
    if (n < 0 || n > INT64_C(1000000000)) return -1;
    return n % 3 == 0 || n % 5 == 0 ? n : 0;
}
