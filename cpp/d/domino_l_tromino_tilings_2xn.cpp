#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_width = 32;
constexpr std::size_t max_parseable_length = 2;

std::int64_t count_tilings(std::int64_t width) noexcept {
    std::int64_t state0 = 1, state1 = 0, state2 = 0, state3 = 0;
    for (std::int64_t column = 0; column < width; ++column) {
        const auto next0 = state0 + state3;
        const auto next1 = state0 + state2;
        const auto next2 = state0 + state1;
        const auto next3 = state0 + state1 + state2;
        state0 = next0; state1 = next1; state2 = next2; state3 = next3;
    }
    return state0;
}
}

extern "C" std::int64_t domino_l_tromino_tilings_2xn(const std::int64_t* input,
                                                       std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 1 || input[0] < 0 || input[0] > max_width) return -1;
    return count_tilings(input[0]);
}
