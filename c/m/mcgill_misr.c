#include <stddef.h>
#include <stdint.h>

#define MIN_EXPERIMENTS INT64_C(1)
#define MAX_EXPERIMENTS INT64_C(1000)
#define MAX_OUTPUT_BYTES 123
#define MASK_48 UINT64_C(0xFFFFFFFFFFFF)
#define MASK_24 UINT64_C(0xFFFFFF)

static uint32_t next_lrand48(uint64_t *state) {
    const uint64_t low = *state & MASK_24;
    const uint64_t high = *state >> 24;
    const uint64_t high_product = (high * UINT64_C(0xECE66D)) & MASK_24;
    *state = (low * UINT64_C(0x5DEECE66D) + (high_product << 24) + UINT64_C(0xB)) & MASK_48;
    return (uint32_t)(*state >> 17);
}

static int different_experiment(uint64_t *random_state, uint8_t free_state[10]) {
    uint8_t faulty_state[10];
    for (size_t cell = 0; cell < 10; ++cell) faulty_state[cell] = free_state[cell];

    for (int vector = 0; vector < 10; ++vector) {
        const uint8_t saved_free = free_state[0];
        const uint8_t saved_faulty = faulty_state[0];
        uint32_t random_word = next_lrand48(random_state);
        for (size_t cell = 0; cell < 9; ++cell) {
            free_state[cell] = (uint8_t)((free_state[cell + 1] + random_word) & 1U);
            const uint32_t random_probability = next_lrand48(random_state);
            if (random_probability % 1000U < 250U) random_word ^= 1U;
            faulty_state[cell] = (uint8_t)((faulty_state[cell + 1] + random_word) & 1U);
            random_word >>= 1;
        }
        random_word = next_lrand48(random_state);
        free_state[9] = (uint8_t)((saved_free + random_word) & 1U);
        const uint32_t random_probability = next_lrand48(random_state);
        if (random_probability % 10000U < 2500U) random_word ^= 1U;
        faulty_state[9] = (uint8_t)((saved_faulty + random_word) & 1U);
    }

    for (size_t cell = 0; cell < 10; ++cell)
        if (free_state[cell] != faulty_state[cell]) return 1;
    return 0;
}

static void append_text(uint8_t *buffer, size_t *used, const char *text) {
    while (*text != '\0') buffer[(*used)++] = (uint8_t)*text++;
}

static void append_unsigned(uint8_t *buffer, size_t *used, uint64_t value) {
    uint8_t reverse[24];
    size_t count = 0;
    do {
        reverse[count++] = (uint8_t)('0' + value % 10U);
        value /= 10U;
    } while (value != 0);
    while (count > 0) buffer[(*used)++] = reverse[--count];
}

static void append_probability(uint8_t *buffer, size_t *used,
                               uint64_t same_count, uint64_t experiments) {
    uint64_t mantissa = 0;
    int exponent = 0;
    if (same_count != 0) {
        uint64_t scale = 1;
        while (same_count * scale < experiments) {
            scale *= 10;
            --exponent;
        }
        const uint64_t numerator = same_count * scale * UINT64_C(100000000);
        mantissa = numerator / experiments;
        const uint64_t remainder = numerator % experiments;
        if (2 * remainder > experiments ||
            (2 * remainder == experiments && (mantissa & 1U) != 0))
            ++mantissa;
        if (mantissa == UINT64_C(1000000000)) {
            mantissa = UINT64_C(100000000);
            ++exponent;
        }
    }
    const uint64_t whole = mantissa / UINT64_C(100000000);
    uint64_t fraction = mantissa % UINT64_C(100000000);
    buffer[(*used)++] = (uint8_t)('0' + whole);
    buffer[(*used)++] = '.';
    uint64_t place = UINT64_C(10000000);
    for (int digit = 0; digit < 8; ++digit) {
        buffer[(*used)++] = (uint8_t)('0' + fraction / place);
        fraction %= place;
        place /= 10;
    }
    buffer[(*used)++] = 'e';
    const unsigned absolute_exponent = (unsigned)(exponent < 0 ? -exponent : exponent);
    buffer[(*used)++] = exponent < 0 ? '-' : '+';
    buffer[(*used)++] = (uint8_t)('0' + absolute_exponent / 10U);
    buffer[(*used)++] = (uint8_t)('0' + absolute_exponent % 10U);
}

int64_t mcgill_misr(int64_t experiments, uint8_t *output, size_t output_capacity) {
    if (experiments < MIN_EXPERIMENTS || experiments > MAX_EXPERIMENTS) return -1;
    if (output == NULL) return -2;

    uint64_t random_state = UINT64_C(1);
    uint8_t free_state[10] = {0, 1, 1, 1, 1, 1, 1, 1, 1, 1};
    uint64_t different_count = 0;
    for (int64_t experiment = 0; experiment < experiments; ++experiment)
        different_count += (uint64_t)different_experiment(&random_state, free_state);

    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t used = 0;
    append_text(staged, &used,
        "reg_len #_vect prob #_tms struct seed1 seed2 seed3 Prob same output\n ");
    append_text(staged, &used, "10 10 2.500e-01 ");
    append_unsigned(staged, &used, (uint64_t)experiments);
    append_text(staged, &used, " 1000000000 1 0 0 ");
    append_probability(staged, &used, (uint64_t)experiments - different_count,
                       (uint64_t)experiments);
    staged[used++] = '\n';

    if (output_capacity < used) return -2;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return (int64_t)used;
}
