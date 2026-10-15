/* Count ASCII vowels and consonants, packing the two counts into one i64. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 100000
#define COUNT_BASE INT64_C(4294967296)

int64_t count_vowels_consonants(const int64_t *values, size_t length)
{
    if (length > MAX_TEXT_LENGTH || (length != 0 && values == NULL)) return -1;
    int64_t vowels = 0, consonants = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t code = values[index];
        if (code < 0 || code > 127) return -1;
        if ((code >= 'A' && code <= 'Z') || (code >= 'a' && code <= 'z')) {
            const int64_t letter = code | 32;
            if (letter == 'a' || letter == 'e' || letter == 'i' || letter == 'o' || letter == 'u')
                ++vowels;
            else ++consonants;
        }
    }
    return vowels * COUNT_BASE + consonants;
}
