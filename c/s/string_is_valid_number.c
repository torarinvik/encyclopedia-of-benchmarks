#include <stddef.h>
#include <stdint.h>

int64_t string_is_valid_number(const int64_t *bytes, size_t length)
{
    if (length > 256 || (length != 0 && bytes == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (bytes[i] < 0 || bytes[i] > 127) return -1;
    }

    int64_t state = 0; /* INITIAL */
    for (size_t i = 0; i < length; ++i) {
        const int64_t ch = bytes[i];
        if (ch >= '0' && ch <= '9') {
            if (state == 0 || state == 1) state = 2;       /* WHOLE */
            else if (state == 3) state = 4;                /* FRACTION */
            else if (state == 5 || state == 6) state = 7;  /* EXP_NUMBER */
            else if (state != 2 && state != 4 && state != 7) return 0;
        } else if (ch == '+' || ch == '-') {
            if (state == 0) state = 1;       /* SIGNED */
            else if (state == 5) state = 6;  /* EXP_SIGN */
            else return 0;
        } else if (ch == '.') {
            if (state == 0 || state == 1) state = 3; /* FRACTIONAL */
            else if (state == 2) state = 4;          /* FRACTION */
            else return 0;
        } else if (ch == 'e' || ch == 'E') {
            if (state == 2 || state == 4) state = 5; /* EXPONENTIAL */
            else return 0;
        } else {
            return 0;
        }
    }
    return state == 2 || state == 4 || state == 7 ? 1 : 0;
}
