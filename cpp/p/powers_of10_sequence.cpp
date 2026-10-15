#include <cstdint>

extern "C" std::int64_t powers_of10_sequence(std::int64_t index) {
    if (index < 0 || index > 18) return -1;
    std::int64_t value = 1;
    for (std::int64_t i = 0; i < index; ++i) value *= 10;
    return value;
}
