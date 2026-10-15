#include <stdint.h>

#define MAX_INDEX INT64_C(63)

int64_t kolakoski_sequence(int64_t index)
{
    if (index < 0 || index > MAX_INDEX) return -1;
    if (index == 0) return 1;
    if (index <= 2) return 2;

    uint64_t encoded = UINT64_C(6); /* terms 1 and 2 are both 2 */
    uint64_t read_bit = UINT64_C(4); /* current run length comes from term 2 */
    uint64_t write_bit = UINT64_C(8); /* next generated term is at index 3 */
    const uint64_t target = (uint64_t)index;
    uint64_t current_index = UINT64_C(3);
    int64_t next_element = 1;

    while (current_index <= target) {
        const uint64_t run_length = UINT64_C(1) + (encoded / read_bit) % UINT64_C(2);
        for (uint64_t emitted = 0; emitted < run_length; ++emitted) {
            if (next_element == 2) encoded += write_bit;
            if (current_index == target) return next_element;
            ++current_index;
            write_bit *= UINT64_C(2);
        }
        read_bit *= UINT64_C(2);
        next_element = 3 - next_element;
    }
    return -1;
}
