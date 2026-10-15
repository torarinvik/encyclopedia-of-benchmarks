/* Count task assignments with one distinct eligible task per person. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PEOPLE 10
#define MAX_TASKS 10
#define MAX_STATES (1u << MAX_PEOPLE)

int64_t assignment_using_bitmask(const int64_t *input, size_t length)
{
    if (length < 2) return -1;
    const int64_t people = input[0];
    const int64_t tasks = input[1];
    if (people < 0 || people > MAX_PEOPLE || tasks < 0 || tasks > MAX_TASKS
        || length != (size_t)(2 + people)) return -1;

    const uint64_t valid_tasks = UINT64_C(1) << (unsigned)tasks;
    for (size_t person = 0; person < (size_t)people; ++person)
        if (input[2 + person] < 0 || (uint64_t)input[2 + person] >= valid_tasks) return -1;

    const size_t states = (size_t)1 << (unsigned)people;
    int64_t ways[MAX_STATES] = {0};
    int64_t next[MAX_STATES] = {0};
    ways[0] = 1;
    for (int64_t task = 0; task < tasks; ++task) {
        for (size_t mask = 0; mask < states; ++mask) next[mask] = 0;
        for (size_t mask = 0; mask < states; ++mask) {
            const int64_t count = ways[mask];
            if (count == 0) continue;
            next[mask] += count;
            for (size_t person = 0; person < (size_t)people; ++person) {
                const size_t bit = (size_t)1 << person;
                if ((mask & bit) == 0 && (input[2 + person] & (INT64_C(1) << (unsigned)task)) != 0)
                    next[mask | bit] += count;
            }
        }
        for (size_t mask = 0; mask < states; ++mask) ways[mask] = next[mask];
    }
    return ways[states - 1];
}
