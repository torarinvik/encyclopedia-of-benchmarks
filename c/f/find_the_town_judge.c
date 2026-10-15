/* Find the unique person trusted by everyone else and who trusts nobody. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PEOPLE 1000
#define MAX_TRUST_ROWS 10000
#define MAX_INPUT_LENGTH (2 + 2 * MAX_TRUST_ROWS)

int64_t find_the_town_judge(const int64_t *values, size_t length)
{
    if (length < 2 || length > MAX_INPUT_LENGTH || values == NULL) return -2;
    const int64_t people = values[0];
    const int64_t trust_count = values[1];
    if (people < 1 || people > MAX_PEOPLE || trust_count < 0 || trust_count > MAX_TRUST_ROWS)
        return -2;
    if (length != 2 + 2 * (size_t)trust_count) return -2;

    size_t incoming[MAX_PEOPLE + 1] = {0};
    size_t outgoing[MAX_PEOPLE + 1] = {0};
    for (size_t edge = 0; edge < (size_t)trust_count; ++edge) {
        const int64_t from = values[2 + 2 * edge];
        const int64_t to = values[3 + 2 * edge];
        if (from < 1 || from > people || to < 1 || to > people || from == to) return -2;
        ++outgoing[(size_t)from];
        ++incoming[(size_t)to];
    }

    int64_t judge = -1;
    for (int64_t person = 1; person <= people; ++person) {
        if (incoming[(size_t)person] == (size_t)(people - 1) && outgoing[(size_t)person] == 0) {
            if (judge != -1) return -1;
            judge = person;
        }
    }
    return judge;
}
