#include <stddef.h>
#include <stdint.h>

enum { MAX_INDEX = 64, MAX_PARSEABLE_LENGTH = 2 };

int64_t klarner_rado_affine_closure_sequence(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1U || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t requested = input[0];
    if (length != 1U || requested < 1 || requested > MAX_INDEX) return -1;

    int64_t terms[MAX_INDEX] = {0};
    terms[0] = 1;
    size_t count = 1U;
    size_t twice = 0U, thrice_plus_two = 0U, sixfold_plus_three = 0U;
    while (count < (size_t)requested) {
        const int64_t by_two = 2 * terms[twice];
        const int64_t by_three = 3 * terms[thrice_plus_two] + 2;
        const int64_t by_six = 6 * terms[sixfold_plus_three] + 3;
        int64_t next = by_two;
        if (by_three < next) next = by_three;
        if (by_six < next) next = by_six;
        terms[count++] = next;
        if (by_two == next) ++twice;
        if (by_three == next) ++thrice_plus_two;
        if (by_six == next) ++sixfold_plus_three;
    }
    return terms[(size_t)requested - 1U];
}
