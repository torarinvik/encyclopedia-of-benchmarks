#include <cstdint>

namespace {
constexpr std::int64_t MAX_INPUT = 1'000'000;
}

// Preserve the pinned Java rank loop, including counter += 1 each round.
extern "C" std::int64_t lucky_number(std::int64_t number) noexcept
{
    if (number < 1 || number > MAX_INPUT) return -1;
    std::int64_t counter = 2;
    std::int64_t position = number;
    while (counter <= position) {
        if (position % counter == 0) return 0;
        position -= position / counter;
        ++counter;
    }
    return 1;
}
