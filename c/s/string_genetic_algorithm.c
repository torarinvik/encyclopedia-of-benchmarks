#include <stddef.h>
#include <stdint.h>

enum { POPULATION_SIZE = 200, SELECTED_SIZE = 50, ELITE_SIZE = 66 };

static uint32_t next_random(uint32_t *state)
{
    *state = (uint32_t)(((uint64_t)*state * UINT64_C(48271)) % UINT64_C(2147483647));
    return *state;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t string_genetic_algorithm(const int64_t *values, size_t length,
                                 uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 6 || length > 44) return -2;
    const int64_t target_length_value = values[0];
    const int64_t gene_count_value = values[1];
    const int64_t seed_value = values[2];
    const int64_t max_generations_value = values[3];
    if (target_length_value < 1 || target_length_value > 8 ||
        gene_count_value < 1 || gene_count_value > 32 ||
        seed_value < 1 || seed_value >= INT64_C(2147483647) ||
        max_generations_value < 1 || max_generations_value > 1000) return -2;
    const size_t target_length = (size_t)target_length_value;
    const size_t gene_count = (size_t)gene_count_value;
    const size_t max_generations = (size_t)max_generations_value;
    if (length != 4 + target_length + gene_count) return -2;
    if (gene_count == 1) {
        const int64_t gene = values[4 + target_length];
        if (gene < 32 || gene > 126 || output == NULL || output_capacity < 16) return -2;
        for (size_t index = 0; index < target_length; ++index)
            if (values[4 + index] != gene) return -2;
        write_i64_le(output, 0, 1);
        write_i64_le(output, 8, POPULATION_SIZE);
        return 16;
    }

    uint8_t genes[32];
    uint64_t target_word = 0;
    uint64_t target_low = 0, target_high = 0;
    for (size_t index = 0; index < target_length; ++index) {
        const int64_t value = values[4 + index];
        if (value < 32 || value > 126) return -2;
        target_word |= (uint64_t)value << (8 * index);
        const uint64_t bit = UINT64_C(1) << ((uint64_t)value & 63);
        if (value < 64) target_low |= bit;
        else target_high |= bit;
    }
    uint64_t gene_low = 0, gene_high = 0;
    for (size_t index = 0; index < gene_count; ++index) {
        const int64_t value = values[4 + target_length + index];
        if (value < 32 || value > 126) return -2;
        genes[index] = (uint8_t)value;
        const uint64_t bit = UINT64_C(1) << ((uint64_t)value & 63);
        if (value < 64) gene_low |= bit;
        else gene_high |= bit;
    }
    if ((target_low & ~gene_low) != 0 || (target_high & ~gene_high) != 0 || output == NULL)
        return -2;

    uint32_t random_state = (uint32_t)seed_value;
    uint64_t population[POPULATION_SIZE];
    uint64_t next_population[POPULATION_SIZE];
    uint8_t mismatches[POPULATION_SIZE];
    size_t order[POPULATION_SIZE];
    for (size_t individual = 0; individual < POPULATION_SIZE; ++individual) {
        uint64_t word = 0;
        for (size_t position = 0; position < target_length; ++position) {
            const uint8_t gene = genes[next_random(&random_state) % gene_count];
            word = (word >> 8) | ((uint64_t)gene << 56);
        }
        const uint64_t candidate = word >> ((8 - target_length) * 8);
        if (candidate == target_word) {
            if (output_capacity < 16) return -2;
            write_i64_le(output, 0, 1);
            write_i64_le(output, 8, POPULATION_SIZE);
            return 16;
        }
        population[individual] = candidate;
    }

    int64_t total_population = 0;
    for (size_t generation = 1; generation < max_generations; ++generation) {
        total_population += POPULATION_SIZE;
        for (size_t individual = 0; individual < POPULATION_SIZE; ++individual) {
            // ASCII XOR leaves the high bit clear. Adding 127 flags each unequal byte.
            const uint64_t difference = population[individual] ^ target_word;
            const uint64_t unequal = ((difference + UINT64_C(0x7f7f7f7f7f7f7f7f)) >> 7)
                                     & UINT64_C(0x0101010101010101);
            const size_t mismatch_count = (unequal * UINT64_C(0x0101010101010101)) >> 56;
            mismatches[individual] = (uint8_t)mismatch_count;
            if (mismatch_count == 0) {
                if (output_capacity < 16) return -2;
                write_i64_le(output, 0, (int64_t)generation);
                write_i64_le(output, 8, total_population);
                return 16;
            }
        }

        // Count mismatch buckets, then scatter in population order to preserve ties.
        size_t offsets[9] = {0};
        for (size_t individual = 0; individual < POPULATION_SIZE; ++individual)
            ++offsets[mismatches[individual]];
        size_t offset = 0;
        for (size_t rank = 0; rank < 9; ++rank) {
            const size_t count = offsets[rank];
            offsets[rank] = offset;
            offset += count;
        }
        for (size_t individual = 0; individual < POPULATION_SIZE; ++individual)
            order[offsets[mismatches[individual]]++] = individual;

        size_t next_count = 0;
        for (; next_count < ELITE_SIZE; ++next_count)
            next_population[next_count] = population[order[next_count]];
        for (size_t parent_rank = 0; parent_rank < SELECTED_SIZE && next_count < POPULATION_SIZE; ++parent_rank) {
            const uint64_t first = population[order[parent_rank]];
            const size_t child_count = (size_t)((target_length - mismatches[order[parent_rank]]) * 100 / target_length) + 1;
            const size_t bounded_child_count = child_count < 10 ? child_count : 10;
            for (size_t child_round = 0; child_round < bounded_child_count && next_count < POPULATION_SIZE; ++child_round) {
                const uint64_t second = population[order[next_random(&random_state) % 51]];
                const size_t cut = next_random(&random_state) % target_length;
                // The low bytes come from one parent and the high bytes from the other.
                const uint64_t low_mask = (UINT64_C(1) << (8 * cut)) - 1;
                const uint64_t exchanged = (first ^ second) & low_mask;
                uint64_t children[2] = {second ^ exchanged, first ^ exchanged};
                for (size_t child_index = 0; child_index < 2; ++child_index) {
                    if (next_random(&random_state) % 5 < 2) {
                        const size_t position = next_random(&random_state) % target_length;
                        const unsigned shift = (unsigned)(8 * position);
                        const uint64_t replacement = genes[next_random(&random_state) % gene_count];
                        children[child_index] = (children[child_index] & ~(UINT64_C(0xFF) << shift)) |
                                                (replacement << shift);
                    }
                    if (next_count < POPULATION_SIZE)
                        next_population[next_count++] = children[child_index];
                }
            }
        }
        for (size_t index = 0; index < POPULATION_SIZE; ++index)
            population[index] = next_population[index];
    }
    // The last generation needs equality only because it has no offspring.
    if (max_generations != 1) {
        for (size_t individual = 0; individual < POPULATION_SIZE; ++individual) {
            if (population[individual] == target_word) {
                if (output_capacity < 16) return -2;
                write_i64_le(output, 0, (int64_t)max_generations);
                write_i64_le(output, 8, total_population + POPULATION_SIZE);
                return 16;
            }
        }
    }
    return -1;
}
