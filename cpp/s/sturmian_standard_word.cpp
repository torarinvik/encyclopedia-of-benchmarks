#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxSteps = 4;
constexpr std::size_t kMaxWord = 41;

bool read_directives(const std::int64_t* input, std::size_t length,
                     std::array<std::int64_t, kMaxSteps>& directives,
                     std::size_t& steps) {
    if (input == nullptr || length < 1 || length > 6) return false;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxSteps)) return false;
    steps = static_cast<std::size_t>(input[0]);
    if (length != steps + 1) return false;
    for (std::size_t i = 0; i < steps; ++i) {
        const std::int64_t repeat = input[i + 1];
        if (i == 0) {
            if (repeat < 0 || repeat > 2) return false;
        } else if (repeat < 1 || repeat > 2) {
            return false;
        }
        directives[i] = repeat;
    }
    return true;
}
}

extern "C" std::int64_t sturmian_standard_word(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    std::array<std::int64_t, kMaxSteps> directives{};
    std::size_t steps = 0;
    if (!read_directives(input, length, directives, steps)) return -1;

    std::array<std::uint8_t, kMaxWord> first{};
    std::array<std::uint8_t, kMaxWord> second{};
    std::array<std::uint8_t, kMaxWord> third{};
    auto* previous = &first;
    auto* current = &second;
    auto* following = &third;
    std::size_t previous_length = 1;
    std::size_t current_length = 1;
    (*previous)[0] = static_cast<std::uint8_t>('b');
    (*current)[0] = static_cast<std::uint8_t>('a');

    for (std::size_t step = 0; step < steps; ++step) {
        const std::size_t repeat = static_cast<std::size_t>(directives[step]);
        const std::size_t following_length = current_length * repeat + previous_length;
        std::size_t position = 0;
        for (std::size_t copy = 0; copy < repeat; ++copy) {
            for (std::size_t i = 0; i < current_length; ++i)
                (*following)[position++] = (*current)[i];
        }
        for (std::size_t i = 0; i < previous_length; ++i)
            (*following)[position++] = (*previous)[i];
        for (std::size_t i = 0; i < current_length; ++i) (*previous)[i] = (*current)[i];
        for (std::size_t i = 0; i < following_length; ++i) (*current)[i] = (*following)[i];
        previous_length = current_length;
        current_length = following_length;
    }

    if (output == nullptr || capacity < current_length) return -2;
    for (std::size_t i = 0; i < current_length; ++i) output[i] = (*current)[i];
    return static_cast<std::int64_t>(current_length);
}
