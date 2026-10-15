#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_PHRASE_LENGTH = 79;

bool valid_phrase(const std::int64_t *phrase, std::size_t length, std::size_t &acronym_length)
{
    if (length > MAX_PHRASE_LENGTH) return false;
    acronym_length = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (phrase[index] < 1 || phrase[index] > 127) return false;
        if (phrase[index] != ' ' && (index == 0 || phrase[index - 1] == ' '))
            ++acronym_length;
    }
    return true;
}
}

extern "C" std::int64_t acronym(const std::int64_t *phrase, std::size_t length,
                                 std::uint8_t *output, std::size_t output_capacity) noexcept
{
    std::size_t required = 0;
    if (!valid_phrase(phrase, length, required)) return -1;
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = phrase[index];
        if (value != ' ' && (index == 0 || phrase[index - 1] == ' '))
            output[written++] = static_cast<std::uint8_t>(
                value >= 'a' && value <= 'z' ? value - ('a' - 'A') : value);
    }
    return static_cast<std::int64_t>(written);
}
