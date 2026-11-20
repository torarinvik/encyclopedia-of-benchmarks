#include <stddef.h>
#include <stdint.h>

#define MAX_DECK_SIZE 10000
#define MAX_PARSEABLE_LENGTH 2

int64_t perfect_shuffle_order(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH || length != 1) return -1;
    const int64_t deck_word = input[0];
    if (deck_word < 2 || deck_word > MAX_DECK_SIZE || (deck_word & 1) != 0) return -1;
    const size_t deck_size = (size_t)deck_word;
    const size_t half = deck_size / 2;

    int64_t first[MAX_DECK_SIZE];
    int64_t second[MAX_DECK_SIZE];
    int64_t *current = first;
    int64_t *next = second;
    for (size_t i = 0; i < deck_size; ++i) current[i] = (int64_t)i;

    int64_t count = 0;
    for (;;) {
        for (size_t i = 0; i < half; ++i) {
            next[2 * i] = current[i];
            next[2 * i + 1] = current[half + i];
        }
        ++count;
        size_t i = 0;
        while (i < deck_size && next[i] == (int64_t)i) ++i;
        if (i == deck_size) return count;
        int64_t *temporary = current;
        current = next;
        next = temporary;
    }
}
