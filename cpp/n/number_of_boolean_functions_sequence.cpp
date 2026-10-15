#include <cstdint>

extern "C" std::int64_t number_of_boolean_functions_sequence(std::int64_t index) {
    if (index < 0 || index > 5) return -1;
    std::int64_t value = 2;
    for (std::int64_t i = 0; i < index; ++i) value *= value;
    return value;
}
