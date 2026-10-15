// Count repeated decimal digit-sum steps until one digit remains.
#include <cstdint>

extern "C" std::int64_t additive_persistence(std::int64_t input)
{
    if (input < 0) return -1;
    std::int64_t steps = 0;
    while (input >= 10) {
        std::int64_t sum = 0;
        auto remaining = input;
        while (remaining > 0) {
            sum += remaining % 10;
            remaining /= 10;
        }
        input = sum;
        ++steps;
    }
    return steps;
}
