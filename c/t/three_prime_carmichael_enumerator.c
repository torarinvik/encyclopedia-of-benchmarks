#include <stddef.h>
#include <stdint.h>

#define MAX_LIMIT 61
#define MAX_PARSEABLE_LENGTH 2
#define MAX_TRIPLES 69

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    if (value % 2 == 0) return value == 2;
    for (int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static int64_t mod_nonnegative(int64_t value, int64_t modulus) {
    int64_t result = value % modulus;
    return result < 0 ? result + modulus : result;
}

static void put_u32_le(uint8_t *output, size_t offset, uint32_t value) {
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t three_prime_carmichael_enumerator(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH || length != 1) return -1;
    const int64_t limit = input[0];
    if (limit < 2 || limit > MAX_LIMIT) return -1;

    uint32_t triples[MAX_TRIPLES][3];
    size_t count = 0;
    for (int64_t p1 = 2; p1 <= limit; ++p1) {
        if (!is_prime(p1)) continue;
        for (int64_t h3 = 2; h3 < p1; ++h3) {
            const int64_t g = h3 + p1;
            for (int64_t d = 1; d < g; ++d) {
                if ((g * (p1 - 1)) % d != 0) continue;
                if (mod_nonnegative(-p1 * p1, h3) != d % h3) continue;
                const int64_t p2 = 1 + (p1 - 1) * g / d;
                if (p2 <= p1 || !is_prime(p2)) continue;
                const int64_t p3 = 1 + (p1 * p2) / h3;
                if (p3 <= p2 || !is_prime(p3)) continue;
                if ((p2 * p3) % (p1 - 1) != 1) continue;
                if (count >= MAX_TRIPLES) return -1;
                triples[count][0] = (uint32_t)p1;
                triples[count][1] = (uint32_t)p2;
                triples[count][2] = (uint32_t)p3;
                ++count;
            }
        }
    }

    const size_t required = 4 + 12 * count;
    if (output == NULL || capacity < required) return -2;
    put_u32_le(output, 0, (uint32_t)count);
    for (size_t i = 0; i < count; ++i) {
        for (size_t field = 0; field < 3; ++field)
            put_u32_le(output, 4 + 12 * i + 4 * field, triples[i][field]);
    }
    return (int64_t)required;
}
