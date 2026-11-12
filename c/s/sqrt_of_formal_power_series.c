#include <stddef.h>
#include <stdint.h>

#define FPS_MODULUS INT64_C(998244353)
#define FPS_MAX_N ((size_t)64)
#define FPS_MAX_INPUT ((size_t)66)

static int64_t fps_mod_pow(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % FPS_MODULUS;
        base = base * base % FPS_MODULUS;
        exponent /= 2;
    }
    return result;
}

static int64_t fps_mod_sqrt(int64_t value)
{
    if (value == 0) return 0;
    if (fps_mod_pow(value, (FPS_MODULUS - 1) / 2) != 1) return -1;
    int64_t odd_part = FPS_MODULUS - 1;
    size_t twos = 0;
    while (odd_part % 2 == 0) { odd_part /= 2; ++twos; }
    int64_t non_residue = 2;
    while (fps_mod_pow(non_residue, (FPS_MODULUS - 1) / 2) != FPS_MODULUS - 1)
        ++non_residue;
    int64_t c = fps_mod_pow(non_residue, odd_part);
    int64_t root = fps_mod_pow(value, (odd_part + 1) / 2);
    int64_t remainder = fps_mod_pow(value, odd_part);
    size_t order = twos;
    while (remainder != 1) {
        size_t index = 1;
        int64_t probe = remainder * remainder % FPS_MODULUS;
        while (index < order && probe != 1) {
            probe = probe * probe % FPS_MODULUS;
            ++index;
        }
        if (index >= order || probe != 1) return -1;
        int64_t exponent = INT64_C(1) << (order - index - 1);
        int64_t factor = fps_mod_pow(c, exponent);
        root = root * factor % FPS_MODULUS;
        int64_t factor_squared = factor * factor % FPS_MODULUS;
        remainder = remainder * factor_squared % FPS_MODULUS;
        c = factor_squared;
        order = index;
    }
    return root < FPS_MODULUS - root ? root : FPS_MODULUS - root;
}

static void fps_store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t sqrt_of_formal_power_series(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > FPS_MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (int64_t)FPS_MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= FPS_MODULUS) return -1;
    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;

    int64_t result[FPS_MAX_N] = {0};
    size_t valuation = 0;
    while (valuation < n && input[valuation + 1] == 0) ++valuation;
    if (valuation == n) {
        for (size_t i = 0; i < n; ++i) fps_store_le(output, 8 * i, 0);
        return (int64_t)bytes;
    }
    if (valuation % 2 != 0) {
        fps_store_le(output, 0, -1);
        return 8;
    }
    const size_t shift = valuation / 2;
    const int64_t leading_root = fps_mod_sqrt(input[valuation + 1]);
    if (leading_root < 0) {
        fps_store_le(output, 0, -1);
        return 8;
    }
    const int64_t inverse_twice_root = fps_mod_pow((2 * leading_root) % FPS_MODULUS, FPS_MODULUS - 2);
    const size_t width = n - valuation;
    result[shift] = leading_root;
    for (size_t degree = 1; degree < width; ++degree) {
        int64_t cross_terms = 0;
        for (size_t i = 1; i < degree; ++i)
            cross_terms = (cross_terms + result[shift + i] * result[shift + degree - i]) % FPS_MODULUS;
        int64_t delta = (input[valuation + degree + 1] - cross_terms) % FPS_MODULUS;
        if (delta < 0) delta += FPS_MODULUS;
        result[shift + degree] = delta * inverse_twice_root % FPS_MODULUS;
    }
    for (size_t i = 0; i < n; ++i) fps_store_le(output, 8 * i, result[i]);
    return (int64_t)bytes;
}
