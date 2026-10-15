#include <stddef.h>
#include <stdint.h>

static int is_vowel(int64_t value) {
    return value == 'a' || value == 'e' || value == 'i' || value == 'o' || value == 'u'
        || value == 'A' || value == 'E' || value == 'I' || value == 'O' || value == 'U';
}

int64_t halves_are_alike(const int64_t *letters, size_t length) {
    if (length > 256 || length % 2 != 0 || (length != 0 && letters == NULL)) return -1;
    size_t half = length / 2;
    int64_t first = 0;
    int64_t second = 0;
    for (size_t index = 0; index < length; ++index) {
        int64_t value = letters[index];
        if (!((value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z'))) return -1;
        if (is_vowel(value)) {
            if (index < half) ++first;
            else ++second;
        }
    }
    return first == second ? 1 : 0;
}
