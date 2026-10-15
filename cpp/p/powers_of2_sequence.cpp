// Return a term from the bounded powers-of-two sequence.
#include <cstdint>

extern "C" std::int64_t powers_of2_sequence(std::int64_t index) noexcept {
    if (index < 0 || index > 62) return -1;
    std::int64_t value = 1;
    for (std::int64_t step = 0; step < index; ++step) value *= 2;
    return value;
}
