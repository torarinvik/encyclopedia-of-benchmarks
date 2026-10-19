#include <stddef.h>
#include <stdint.h>

#define MAX_CALL_COUNT INT64_C(1000000)
#define MODULUS INT64_C(139968)
#define FRACTION_SCALE INT64_C(1000000000)
#define MAX_OUTPUT_BYTES 13

int64_t shootout_random(int64_t call_count, uint8_t *output, size_t output_capacity)
{
    if (call_count < 1 || call_count > MAX_CALL_COUNT) return -1;

    int64_t state = 42;
    for (int64_t call = 0; call < call_count; ++call)
        state = (state * 3877 + 29573) % MODULUS;

    const int64_t scaled = (100 * state * FRACTION_SCALE + MODULUS / 2) / MODULUS;
    int64_t whole = scaled / FRACTION_SCALE;
    int64_t fraction = scaled % FRACTION_SCALE;
    uint8_t staged[MAX_OUTPUT_BYTES];
    uint8_t reversed_digits[3];
    size_t digit_count = 0;
    do {
        reversed_digits[digit_count++] = (uint8_t)('0' + whole % 10);
        whole /= 10;
    } while (whole != 0);

    size_t used = 0;
    while (digit_count > 0) staged[used++] = reversed_digits[--digit_count];
    staged[used++] = (uint8_t)'.';
    for (int64_t place = INT64_C(100000000); place > 0; place /= 10) {
        staged[used++] = (uint8_t)('0' + fraction / place);
        fraction %= place;
    }
    staged[used++] = (uint8_t)'\n';

    if (output == NULL || output_capacity < used) return -2;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return (int64_t)used;
}
