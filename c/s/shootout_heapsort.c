/* Port the generated-double heapsort from the Shootout benchmark. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_LENGTH = 8192, MAX_OUTPUT_BYTES = 9 };
enum { IM = 139968, IA = 3877, IC = 29573 };

static void source_heapsort(int n, double *values)
{
    int i, j;
    int ir = n;
    int l = (n >> 1) + 1;
    double rra;

    for (;;) {
        if (l > 1) {
            rra = values[--l];
        } else {
            rra = values[ir];
            values[ir] = values[1];
            if (--ir == 1) {
                values[1] = rra;
                return;
            }
        }
        i = l;
        j = l << 1;
        while (j <= ir) {
            if (j < ir && values[j] < values[j + 1]) ++j;
            if (rra < values[j]) {
                values[i] = values[j];
                i = j;
                j += i;
            } else {
                j = ir + 1;
            }
        }
        values[i] = rra;
    }
}

static void write_fixed_six(double value, uint8_t *output)
{
    const uint32_t millionths = (uint32_t)(value * 1000000.0 + 0.5);
    const uint32_t whole = millionths / 1000000u;
    uint32_t fraction = millionths % 1000000u;
    output[0] = (uint8_t)('0' + whole);
    output[1] = (uint8_t)'.';
    uint32_t divisor = 100000u;
    for (size_t index = 2; index < 8; ++index) {
        output[index] = (uint8_t)('0' + (fraction / divisor) % 10u);
        divisor /= 10u;
    }
    output[8] = (uint8_t)'\n';
}

int64_t shootout_heapsort(int64_t length, uint8_t *output, size_t output_capacity)
{
    if (length < 2 || length > MAX_LENGTH) return -1;
    if (output == NULL || output_capacity < MAX_OUTPUT_BYTES) return -2;

    const int n = (int)length;
    double values[MAX_LENGTH + 1];
    int64_t state = 42;
    for (int index = 1; index <= n; ++index) {
        state = (state * IA + IC) % IM;
        values[index] = 1.0 * (double)state / (double)IM;
    }
    source_heapsort(n, values);
    write_fixed_six(values[n], output);
    return MAX_OUTPUT_BYTES;
}
