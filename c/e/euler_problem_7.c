#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define SIEVE_LIMIT 1000000u
#define MAX_ORDINAL 10001
#define MAX_VALID_INPUT_LENGTH 1u
#define MAX_PARSEABLE_INPUT_LENGTH 2u

int64_t euler_problem_7(const int64_t *input, size_t length)
{
    if (input == NULL || length < MAX_VALID_INPUT_LENGTH || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (length != MAX_VALID_INPUT_LENGTH || input[0] < 1 || input[0] > MAX_ORDINAL) return -1;

    uint8_t *composite = (uint8_t *)calloc(SIEVE_LIMIT, sizeof(uint8_t));
    if (composite == NULL) return -1;
    int64_t count = 0;
    for (size_t candidate = 2; candidate < SIEVE_LIMIT; ++candidate) {
        if (composite[candidate] == 0) {
            ++count;
            if (count == input[0]) {
                free(composite);
                return (int64_t)candidate;
            }
            for (size_t multiple = candidate * 2; multiple < SIEVE_LIMIT; multiple += candidate)
                composite[multiple] = 1;
        }
    }
    free(composite);
    return -1;
}
