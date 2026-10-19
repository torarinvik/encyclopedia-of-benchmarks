#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t min_experiments = 1;
constexpr std::int64_t max_experiments = 1'000;
constexpr std::size_t max_output_bytes = 123;
constexpr std::uint64_t mask_48 = 0xFFFFFFFFFFFFULL;
constexpr std::uint64_t mask_24 = 0xFFFFFFULL;

std::uint32_t next_lrand48(std::uint64_t &state) {
    const std::uint64_t low = state & mask_24;
    const std::uint64_t high = state >> 24;
    const std::uint64_t high_product = (high * 0xECE66DULL) & mask_24;
    state = (low * 0x5DEECE66DULL + (high_product << 24) + 0xBULL) & mask_48;
    return static_cast<std::uint32_t>(state >> 17);
}

bool different_experiment(std::uint64_t &random_state, std::uint8_t free_state[10]) {
    std::uint8_t faulty_state[10];
    for (std::size_t cell = 0; cell < 10; ++cell) faulty_state[cell] = free_state[cell];

    for (int vector = 0; vector < 10; ++vector) {
        const std::uint8_t saved_free = free_state[0];
        const std::uint8_t saved_faulty = faulty_state[0];
        std::uint32_t random_word = next_lrand48(random_state);
        for (std::size_t cell = 0; cell < 9; ++cell) {
            free_state[cell] = static_cast<std::uint8_t>((free_state[cell + 1] + random_word) & 1U);
            const std::uint32_t random_probability = next_lrand48(random_state);
            if (random_probability % 1000U < 250U) random_word ^= 1U;
            faulty_state[cell] = static_cast<std::uint8_t>((faulty_state[cell + 1] + random_word) & 1U);
            random_word >>= 1;
        }
        random_word = next_lrand48(random_state);
        free_state[9] = static_cast<std::uint8_t>((saved_free + random_word) & 1U);
        const std::uint32_t random_probability = next_lrand48(random_state);
        if (random_probability % 10'000U < 2'500U) random_word ^= 1U;
        faulty_state[9] = static_cast<std::uint8_t>((saved_faulty + random_word) & 1U);
    }

    for (std::size_t cell = 0; cell < 10; ++cell)
        if (free_state[cell] != faulty_state[cell]) return true;
    return false;
}

void append_text(std::uint8_t *buffer, std::size_t &used, const char *text) {
    while (*text != '\0') buffer[used++] = static_cast<std::uint8_t>(*text++);
}

void append_unsigned(std::uint8_t *buffer, std::size_t &used, std::uint64_t value) {
    std::uint8_t reverse[24];
    std::size_t count = 0;
    do {
        reverse[count++] = static_cast<std::uint8_t>('0' + value % 10U);
        value /= 10U;
    } while (value != 0);
    while (count > 0) buffer[used++] = reverse[--count];
}

void append_probability(std::uint8_t *buffer, std::size_t &used,
                        std::uint64_t same_count, std::uint64_t experiments) {
    std::uint64_t mantissa = 0;
    int exponent = 0;
    if (same_count != 0) {
        std::uint64_t scale = 1;
        while (same_count * scale < experiments) {
            scale *= 10;
            --exponent;
        }
        const std::uint64_t numerator = same_count * scale * 100'000'000ULL;
        mantissa = numerator / experiments;
        const std::uint64_t remainder = numerator % experiments;
        if (2 * remainder > experiments ||
            (2 * remainder == experiments && (mantissa & 1U) != 0)) ++mantissa;
        if (mantissa == 1'000'000'000ULL) {
            mantissa = 100'000'000ULL;
            ++exponent;
        }
    }
    const std::uint64_t whole = mantissa / 100'000'000ULL;
    std::uint64_t fraction = mantissa % 100'000'000ULL;
    buffer[used++] = static_cast<std::uint8_t>('0' + whole);
    buffer[used++] = '.';
    std::uint64_t place = 10'000'000ULL;
    for (int digit = 0; digit < 8; ++digit) {
        buffer[used++] = static_cast<std::uint8_t>('0' + fraction / place);
        fraction %= place;
        place /= 10;
    }
    buffer[used++] = 'e';
    const unsigned absolute_exponent = static_cast<unsigned>(exponent < 0 ? -exponent : exponent);
    buffer[used++] = exponent < 0 ? '-' : '+';
    buffer[used++] = static_cast<std::uint8_t>('0' + absolute_exponent / 10U);
    buffer[used++] = static_cast<std::uint8_t>('0' + absolute_exponent % 10U);
}
} // namespace

extern "C" std::int64_t mcgill_misr(std::int64_t experiments, std::uint8_t *output,
                                     std::size_t output_capacity) noexcept {
    if (experiments < min_experiments || experiments > max_experiments) return -1;
    if (output == nullptr) return -2;

    std::uint64_t random_state = 1;
    std::uint8_t free_state[10] = {0, 1, 1, 1, 1, 1, 1, 1, 1, 1};
    std::uint64_t different_count = 0;
    for (std::int64_t experiment = 0; experiment < experiments; ++experiment)
        different_count += static_cast<std::uint64_t>(different_experiment(random_state, free_state));

    std::uint8_t staged[max_output_bytes];
    std::size_t used = 0;
    append_text(staged, used,
        "reg_len #_vect prob #_tms struct seed1 seed2 seed3 Prob same output\n ");
    append_text(staged, used, "10 10 2.500e-01 ");
    append_unsigned(staged, used, static_cast<std::uint64_t>(experiments));
    append_text(staged, used, " 1000000000 1 0 0 ");
    append_probability(staged, used, static_cast<std::uint64_t>(experiments) - different_count,
                       static_cast<std::uint64_t>(experiments));
    staged[used++] = '\n';

    if (output_capacity < used) return -2;
    for (std::size_t index = 0; index < used; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(used);
}
