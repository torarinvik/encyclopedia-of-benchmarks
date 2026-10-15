// Count ASCII vowels and consonants, packing the two counts into one i64.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t count_vowels_consonants(const std::int64_t *values,
                                                   std::size_t length) noexcept {
    if (length > 100000 || (length != 0 && values == nullptr)) return -1;
    std::int64_t vowels = 0, consonants = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto code = values[index];
        if (code < 0 || code > 127) return -1;
        if ((code >= 'A' && code <= 'Z') || (code >= 'a' && code <= 'z')) {
            const auto letter = code | 32;
            if (letter == 'a' || letter == 'e' || letter == 'i' || letter == 'o' || letter == 'u')
                ++vowels;
            else ++consonants;
        }
    }
    return vowels * INT64_C(4294967296) + consonants;
}
