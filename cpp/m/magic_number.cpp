// Positive n is magic when its decimal digit root is one.
#include <cstdint>

extern "C" int64_t magic_number(int64_t n)
{
    return n > 0 && n % 9 == 1 ? 1 : 0;
}
