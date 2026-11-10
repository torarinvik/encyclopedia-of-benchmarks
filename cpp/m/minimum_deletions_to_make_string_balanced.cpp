#include <cstddef>
#include <cstdint>

extern "C" std::int64_t minimum_deletions_to_make_string_balanced(const std::int64_t *values, std::size_t length) {
    if (length > 256 || (length != 0 && values == nullptr)) return -1;
    std::int64_t a_state = 0;
    std::int64_t b_state = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = values[index];
        if (value < 0 || value > 1) return -1;
        b_state += value == 0 && b_state < a_state;
        a_state += value;
    }
    return b_state;
}
