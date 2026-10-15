// Keyed Morse trigraph fractionation.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxText = 256, MaxKey = 64, MaxMorse = 1300, MaxResult = 800;
constexpr std::uint8_t MorseCode[26] = {1,8,10,4,0,2,6,0,0,7,5,4,3,2,7,6,13,2,0,1,1,1,3,9,11,12};
constexpr std::uint8_t MorseLength[26] = {2,4,4,3,1,4,3,4,2,4,3,4,2,2,3,4,4,3,3,1,3,4,3,4,4,4};

void makeKeyedAlphabet(const std::int64_t *input, std::size_t start, std::size_t length, std::uint8_t keyed[26]) {
    bool seen[26]{}; std::size_t count = 0;
    for (std::size_t i = 0; i < length; ++i) {
        auto value = input[start + i]; if (value >= 'a' && value <= 'z') value -= 32;
        const auto letter = static_cast<std::size_t>(value - 'A');
        if (!seen[letter]) { seen[letter] = true; keyed[count++] = static_cast<std::uint8_t>(value); }
    }
    for (std::size_t i = 0; i < 26; ++i) if (!seen[i]) keyed[count++] = static_cast<std::uint8_t>('A' + i);
}
int morseLetter(const std::uint8_t *morse, std::size_t length) {
    std::uint8_t code = 0;
    for (std::size_t i = 0; i < length; ++i) code = static_cast<std::uint8_t>(code * 2 + (morse[i] == '-'));
    for (std::size_t letter = 0; letter < 26; ++letter)
        if (MorseLength[letter] == length && MorseCode[letter] == code) return static_cast<int>(letter);
    return -1;
}
}

extern "C" std::int64_t fractionated_morse_cipher(const std::int64_t *input, std::size_t length,
                                                    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3 || length > 323) return -1;
    const auto mode = input[0], text_value = input[1], key_value = input[2];
    if ((mode != 0 && mode != 1) || text_value < 0 || text_value > 256 || key_value < 0 || key_value > 64) return -1;
    const auto text_length = static_cast<std::size_t>(text_value), key_length = static_cast<std::size_t>(key_value);
    if (length != 3 + text_length + key_length) return -1;
    const auto key_start = 3 + text_length;
    for (std::size_t i = 0; i < key_length; ++i) {
        const auto value = input[key_start + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
    }
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto value = input[3 + i];
        if (mode == 0) { if (value != ' ' && !((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1; }
        else if (value < 'A' || value > 'Z') return -1;
    }
    std::uint8_t keyed[26]; makeKeyedAlphabet(input, key_start, key_length, keyed);
    std::uint8_t result[MaxResult]{}; std::size_t result_length = 0;
    if (mode == 0) {
        std::uint8_t morse[MaxMorse]{}; std::size_t morse_size = 0;
        for (std::size_t i = 0; i < text_length; ++i) {
            if (i != 0) morse[morse_size++] = 'x';
            auto value = input[3 + i]; if (value == ' ') continue; if (value >= 'a' && value <= 'z') value -= 32;
            const auto letter = static_cast<std::size_t>(value - 'A');
            for (std::size_t bit = 0; bit < MorseLength[letter]; ++bit)
                morse[morse_size++] = (MorseCode[letter] & (1u << (MorseLength[letter] - bit - 1))) ? '-' : '.';
        }
        const auto padding = 3 - morse_size % 3;
        for (std::size_t i = 0; i < padding; ++i) morse[morse_size++] = 'x';
        for (std::size_t i = 0; i < morse_size; i += 3) {
            const std::uint8_t symbols[3] = {morse[i], morse[i + 1], morse[i + 2]};
            std::size_t trigram = 0;
            for (auto symbol : symbols) trigram = trigram * 3 + (symbol == '.' ? 0 : symbol == '-' ? 1 : 2);
            if (trigram < 26) result[result_length++] = keyed[trigram];
        }
    } else {
        std::uint8_t morse[MaxMorse]{}; std::size_t morse_size = 0;
        for (std::size_t i = 0; i < text_length; ++i) {
            std::size_t trigram = 0; while (trigram < 26 && keyed[trigram] != input[3 + i]) ++trigram;
            if (trigram == 26) return -1;
            const std::uint8_t symbols[3] = {static_cast<std::uint8_t>(trigram / 9), static_cast<std::uint8_t>((trigram / 3) % 3), static_cast<std::uint8_t>(trigram % 3)};
            constexpr std::uint8_t alphabet[3] = {'.', '-', 'x'};
            for (auto symbol : symbols) morse[morse_size++] = alphabet[symbol];
        }
        std::size_t segment_start = 0;
        for (std::size_t i = 0; i <= morse_size; ++i) {
            if (i != morse_size && morse[i] != 'x') continue;
            const auto segment_length = i - segment_start;
            if (segment_length == 0) result[result_length++] = ' ';
            else { const int letter = morseLetter(morse + segment_start, segment_length); if (letter < 0) return -1; result[result_length++] = static_cast<std::uint8_t>('A' + letter); }
            segment_start = i + 1;
        }
        std::size_t first = 0; while (first < result_length && result[first] == ' ') ++first;
        while (result_length > first && result[result_length - 1] == ' ') --result_length;
        if (first != 0) { for (std::size_t i = first; i < result_length; ++i) result[i - first] = result[i]; result_length -= first; }
    }
    if (output_capacity < result_length || (result_length != 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < result_length; ++i) output[i] = result[i];
    return static_cast<std::int64_t>(result_length);
}
