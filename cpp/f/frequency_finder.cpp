#include <cstddef>
#include <cstdint>

extern "C" std::int64_t frequency_finder(const std::int64_t *input, std::size_t length) noexcept
{
    constexpr std::size_t max_input_length = 1024;
    constexpr char etaoin[] = "ETAOINSHRDLCUMWFGYPBVKJXQZ";
    if (input == nullptr) return length == 0 ? 0 : -1;
    if (length > max_input_length) return -1;
    std::int64_t counts[26] = {};
    for (std::size_t i = 0; i < length; ++i) {
        auto b = input[i]; if (b < 0 || b > 127) return -1;
        if (b >= 'a' && b <= 'z') b -= 32;
        if (b >= 'A' && b <= 'Z') ++counts[b - 'A'];
    }
    int order[26]; for (int i = 0; i < 26; ++i) order[i] = i;
    for (int i = 1; i < 26; ++i) {
        const int key = order[i]; int j = i, kr = 0;
        while (etaoin[kr] != 'A' + key) ++kr;
        while (j > 0) {
            const int p = order[j - 1]; int pr = 0; while (etaoin[pr] != 'A' + p) ++pr;
            if (counts[p] > counts[key] || (counts[p] == counts[key] && pr > kr)) break;
            order[j] = p; --j;
        }
        order[j] = key;
    }
    std::int64_t score = 0;
    for (int i = 0; i < 6; ++i) {
        for (int j = 0; j < 6; ++j) if ('A' + order[i] == etaoin[j]) { ++score; break; }
        for (int j = 20; j < 26; ++j) if ('A' + order[20 + i] == etaoin[j]) { ++score; break; }
    }
    return score;
}
