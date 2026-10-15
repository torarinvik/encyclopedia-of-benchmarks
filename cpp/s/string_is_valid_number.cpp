#include <cstddef>
#include <cstdint>

extern "C" std::int64_t string_is_valid_number(const std::int64_t *bytes,
                                                 std::size_t length) noexcept
{
    if (length > 256 || (length != 0 && bytes == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        if (bytes[i] < 0 || bytes[i] > 127) return -1;
    }

    std::int64_t state = 0; // INITIAL
    for (std::size_t i = 0; i < length; ++i) {
        const std::int64_t ch = bytes[i];
        if (ch >= '0' && ch <= '9') {
            if (state == 0 || state == 1) state = 2;
            else if (state == 3) state = 4;
            else if (state == 5 || state == 6) state = 7;
            else if (state != 2 && state != 4 && state != 7) return 0;
        } else if (ch == '+' || ch == '-') {
            if (state == 0) state = 1;
            else if (state == 5) state = 6;
            else return 0;
        } else if (ch == '.') {
            if (state == 0 || state == 1) state = 3;
            else if (state == 2) state = 4;
            else return 0;
        } else if (ch == 'e' || ch == 'E') {
            if (state == 2 || state == 4) state = 5;
            else return 0;
        } else {
            return 0;
        }
    }
    return state == 2 || state == 4 || state == 7 ? 1 : 0;
}
