#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
struct Scale { std::uint64_t value; const char *unit; };
constexpr const char *ones[] = {"zero","one","two","three","four","five","six","seven","eight","nine"};
constexpr const char *teens[] = {"ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen"};
constexpr const char *tens[] = {"","","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety"};
constexpr Scale short_scales[] = {{1000000000000000ULL,"quadrillion"},{1000000000000ULL,"trillion"},{1000000000ULL,"billion"},{1000000ULL,"million"},{1000ULL,"thousand"},{100ULL,"hundred"}};
constexpr Scale long_scales[] = {{1000000000000000ULL,"billiard"},{1000000000ULL,"milliard"},{1000000ULL,"million"},{1000ULL,"thousand"},{100ULL,"hundred"}};
constexpr Scale indian_scales[] = {{100000000000000ULL,"crore crore"},{1000000000000ULL,"lakh crore"},{10000000ULL,"crore"},{100000ULL,"lakh"},{1000ULL,"thousand"},{100ULL,"hundred"}};
void append_raw(char *out, std::size_t &len, const char *text) { while (*text) out[len++] = *text++; }
void append_word(char *out, std::size_t &len, const char *text) { if (len) out[len++] = ' '; append_raw(out, len, text); }
void append_small(std::uint64_t n, char *out, std::size_t &len) {
    if (n < 10) { append_word(out, len, ones[n]); return; }
    if (n < 20) { append_word(out, len, teens[n - 10]); return; }
    append_word(out, len, tens[n / 10]);
    if (n % 10) { out[len++] = '-'; append_raw(out, len, ones[n % 10]); }
}
void append_number(std::uint64_t n, int system, char *out, std::size_t &len, int depth) {
    if (depth > 8) return;
    const Scale *scales = system == 0 ? short_scales : system == 1 ? long_scales : indian_scales;
    const std::size_t count = system == 1 ? 5 : 6;
    const auto initial_len = len;
    for (std::size_t i = 0; i < count; ++i) {
        const auto group = n / scales[i].value;
        n %= scales[i].value;
        if (!group) continue;
        if (group >= 100) append_number(group, system, out, len, depth + 1);
        else append_small(group, out, len);
        append_word(out, len, scales[i].unit);
    }
    if (n || len == initial_len) append_small(n, out, len);
}
}

extern "C" std::int64_t convert_number_to_words(const std::int64_t *input, std::size_t length,
                                                 std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 2 || input[1] < 0 || input[1] > 2) return -1;
    const int system = static_cast<int>(input[1]);
    const std::int64_t limit = system == 0 ? 999999999999999999LL : 9000000000000000000LL;
    const auto number = input[0];
    if (number < -limit || number > limit) return -1;
    const auto magnitude = static_cast<std::uint64_t>(number < 0 ? -number : number);
    std::array<char, 512> words{};
    std::size_t word_count = 0;
    if (number < 0) append_word(words.data(), word_count, "negative");
    append_number(magnitude, system, words.data(), word_count, 0);
    if (capacity < word_count || output == nullptr) return -2;
    std::memcpy(output, words.data(), word_count);
    return static_cast<std::int64_t>(word_count);
}
