#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MIN_PROPORTION 1.0e-5
#define MAX_PROPORTION 1.0
#define MAX_PARTITIONS 5000000

static int is_power_of_two(int64_t value)
{
    return value > 0 && (value & (value - 1)) == 0;
}

double problem207(double max_proportion)
{
    if (max_proportion != max_proportion || max_proportion < MIN_PROPORTION ||
        max_proportion > MAX_PROPORTION) return INVALID_RESULT;
    int64_t partitions = 0;
    int64_t perfect_partitions = 0;
    while (partitions < MAX_PARTITIONS) {
        ++partitions;
        int64_t candidate = partitions * (partitions + 1);
        if (is_power_of_two(partitions + 1)) ++perfect_partitions;
        if ((double)perfect_partitions / (double)partitions < max_proportion)
            return (double)candidate;
    }
    return INVALID_RESULT;
}
