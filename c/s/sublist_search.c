#include <stddef.h>
#include <stdint.h>

enum { MAX_LIST_LENGTH = 64, MAX_INPUT_LENGTH = 2 + 2 * MAX_LIST_LENGTH };
static const int64_t MAX_VALUE = INT32_MAX;

int64_t sublist_search(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t main_count_value = values[0];
    const int64_t pattern_count_value = values[1];
    if (main_count_value < 0 || main_count_value > MAX_LIST_LENGTH ||
        pattern_count_value < 0 || pattern_count_value > MAX_LIST_LENGTH) return -1;
    const size_t main_count = (size_t)main_count_value;
    const size_t pattern_count = (size_t)pattern_count_value;
    if (length != 2 + main_count + pattern_count) return -1;
    for (size_t i = 0; i < main_count + pattern_count; ++i)
        if (values[2 + i] < 0 || values[2 + i] > MAX_VALUE) return -1;

    /* The pinned source treats either null list head, including an empty
       pattern, as a non-match. */
    if (main_count == 0 || pattern_count == 0 || pattern_count > main_count) return 0;

    const size_t pattern_offset = 2 + main_count;
    for (size_t start = 0; start + pattern_count <= main_count; ++start) {
        size_t matched = 0;
        while (matched < pattern_count &&
               values[2 + start + matched] == values[pattern_offset + matched]) {
            ++matched;
        }
        if (matched == pattern_count) return 1;
    }
    return 0;
}
