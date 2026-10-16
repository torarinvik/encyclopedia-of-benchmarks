#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH INT64_C(1024)
#define MAX_INPUT_LENGTH ((size_t)1024)
static const char ETAOIN[] = "ETAOINSHRDLCUMWFGYPBVKJXQZ";

int64_t frequency_finder(const int64_t *input, size_t length)
{
    if (input == NULL) return length == 0 ? 0 : -1;
    if (length > MAX_INPUT_LENGTH) return -1;
    int64_t counts[26] = {0};
    for (size_t i = 0; i < length; ++i) {
        int64_t b = input[i];
        if (b < 0 || b > 127) return -1;
        if (b >= 'a' && b <= 'z') b -= 32;
        if (b >= 'A' && b <= 'Z') ++counts[b - 'A'];
    }
    int order[26];
    for (int i = 0; i < 26; ++i) order[i] = i;
    for (int i = 1; i < 26; ++i) {
        int key = order[i], j = i;
        int keyrank = 0; while (ETAOIN[keyrank] != 'A' + key) ++keyrank;
        while (j > 0) {
            int prev = order[j - 1], prevrank = 0;
            while (ETAOIN[prevrank] != 'A' + prev) ++prevrank;
            if (counts[prev] > counts[key] || (counts[prev] == counts[key] && prevrank > keyrank)) break;
            order[j] = prev; --j;
        }
        order[j] = key;
    }
    int64_t score = 0;
    for (int i = 0; i < 6; ++i) {
        for (int j = 0; j < 6; ++j) if ('A' + order[i] == ETAOIN[j]) { ++score; break; }
        for (int j = 20; j < 26; ++j) if ('A' + order[20 + i] == ETAOIN[j]) { ++score; break; }
    }
    return score;
}
