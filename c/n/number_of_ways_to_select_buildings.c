/* Count alternating 0-1-0 and 1-0-1 subsequences with two linear scans. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

static int64_t count_for_target(const int64_t *values, size_t length, int64_t target)
{
    int64_t first_count = 0, middle_count = 0, ways = 0;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] == target) {
            ways += middle_count;
            ++first_count;
        } else {
            middle_count += first_count;
        }
    }
    return ways;
}

int64_t number_of_ways_to_select_buildings(const int64_t *values, size_t length)
{
    if (length == 0) return 0;
    if (values == NULL || length > MAX_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] != 48 && values[index] != 49) return -1;
    return count_for_target(values, length, 48) + count_for_target(values, length, 49);
}
