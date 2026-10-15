#include <math.h>
#include <stdint.h>

int64_t newton_square_root(int64_t value)
{
    if (value < 0 || value > INT64_C(4611686018427387903)) return -1;
    if (value == 0) return 0;

    int bit_length = (int)ceil(log2((double)value));
    int64_t root = INT64_C(1) << (bit_length / 2);
    while (!(value >= root * root && value <= root * root + root + root)) {
        root += value / root;
        root /= 2;
    }
    return root;
}
