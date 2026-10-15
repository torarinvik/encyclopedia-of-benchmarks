#include <cstdint>

extern "C" std::int64_t digital_root(std::int64_t n)
{
    if (n < 0) return -1;
    while (n >= 10) {
        std::int64_t total = 0;
        while (n > 0) {
            total += n % 10;
            n /= 10;
        }
        n = total;
    }
    return n;
}
