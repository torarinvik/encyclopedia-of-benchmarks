#include <cstddef>
#include <cstdint>

static bool halves_is_vowel(int64_t value) {
    return value == 'a' || value == 'e' || value == 'i' || value == 'o' || value == 'u'
        || value == 'A' || value == 'E' || value == 'I' || value == 'O' || value == 'U';
}

extern "C" int64_t halves_are_alike(const int64_t *letters, size_t length) {
    if (length > 256 || length % 2 != 0 || (length != 0 && letters == nullptr)) return -1;
    const size_t half = length / 2;
    int64_t first = 0;
    int64_t second = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = letters[index];
        if (!((value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z'))) return -1;
        if (halves_is_vowel(value)) {
            if (index < half) ++first;
            else ++second;
        }
    }
    return first == second ? 1 : 0;
}
