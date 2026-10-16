/* Evaluate the six pinned full-wave rectifier helper formulas. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define OUTPUT_BYTES 48

static void store_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t full_wave_rectifier(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 5) return -1;
    const int64_t rf_i = values[0], rs_i = values[1], rl_i = values[2];
    const int64_t vm_i = values[3], im_i = values[4];
    if (rf_i < 0 || rf_i > 1000000 || rs_i < 0 || rs_i > 1000000 ||
        rl_i < 1 || rl_i > 1000000 || vm_i < -1000000 || vm_i > 1000000 ||
        im_i < -1000000 || im_i > 1000000) return -1;
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;

    const double rf = (double)rf_i, rs = (double)rs_i, rl = (double)rl_i;
    const double vm = (double)vm_i, im = (double)im_i;
    store_f64_le(output, 0, vm / (rf + rs + rl));
    store_f64_le(output, 8, 2.0 * im * 0.318);
    store_f64_le(output, 16, 2.0 * 0.318 * vm);
    store_f64_le(output, 24, vm / rl);
    store_f64_le(output, 32, im * 0.707);
    store_f64_le(output, 40, vm * 0.707);
    return OUTPUT_BYTES;
}
