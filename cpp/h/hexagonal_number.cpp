// Return the nth hexagonal number for a JS-safe positive index.
#include <cstdint>

extern "C" std::int64_t hexagonal_number(std::int64_t number) noexcept {
    if (number < 1 || number > 67108864) return -1;
    return number * (2 * number - 1);
}
