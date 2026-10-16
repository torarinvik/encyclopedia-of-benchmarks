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
    uint8_t target[8];
    uint8_t genes[32];
    for (size_t index = 0; index < target_length; ++index) {
        const int64_t value = values[4 + index];
        if (value < 32 || value > 126) return -2;
        target[index] = (uint8_t)value;
    }
    for (size_t index = 0; index < gene_count; ++index) {
        const int64_t value = values[4 + target_length + index];
        if (value < 32 || value > 126) return -2;
        genes[index] = (uint8_t)value;
    }
    for (size_t position = 0; position < target_length; ++position) {
        int found = 0;
        for (size_t gene = 0; gene < gene_count; ++gene)
            if (genes[gene] == target[position]) found = 1;
        if (!found) return -2;
    }
    if (output == NULL) return -2;

    uint32_t random_state = (uint32_t)seed_value;
    uint64_t population[POPULATION_SIZE];
    uint64_t next_population[POPULATION_SIZE];
    uint8_t scores[POPULATION_SIZE];
    size_t order[POPULATION_SIZE];
    for (size_t individual = 0; individual < POPULATION_SIZE; ++individual) {
        uint64_t word = 0;
        for (size_t position = 0; position < target_length; ++position) {
            const uint8_t gene = genes[next_random(&random_state) % gene_count];
            word |= (uint64_t)gene << (8 * position);
        }
        population[individual] = word;
    }

    int64_t total_population = 0;
    for (size_t generation = 1; generation <= max_generations; ++generation) {
        total_population += POPULATION_SIZE;
        for (size_t individual = 0; individual < POPULATION_SIZE; ++individual) {
            uint8_t score = 0;
            for (size_t position = 0; position < target_length; ++position) {
                score += (uint8_t)(((population[individual] >> (8 * position)) & UINT64_C(0xFF)) == target[position]);
            }
            scores[individual] = score;
            order[individual] = individual;
            if (score == target_length_value) {
                if (output_capacity < 16) return -2;
                write_i64_le(output, 0, (int64_t)generation);
                write_i64_le(output, 8, total_population);
                return 16;
            }
        }

        // Stable descending fitness order, so equal scores preserve population order.
        for (size_t index = 1; index < POPULATION_SIZE; ++index) {
            const size_t selected = order[index];
            size_t insertion = index;
            while (insertion > 0 && scores[order[insertion - 1]] < scores[selected]) {
                order[insertion] = order[insertion - 1];
                --insertion;
            }
            order[insertion] = selected;
        }

        size_t next_count = 0;
        for (; next_count < ELITE_SIZE; ++next_count)
            next_population[next_count] = population[order[next_count]];
        for (size_t parent_rank = 0; parent_rank < SELECTED_SIZE && next_count < POPULATION_SIZE; ++parent_rank) {
            const uint64_t first = population[order[parent_rank]];
            const size_t child_count = (size_t)(scores[order[parent_rank]] * 100 / target_length) + 1;
            const size_t bounded_child_count = child_count < 10 ? child_count : 10;
            for (size_t child_round = 0; child_round < bounded_child_count && next_count < POPULATION_SIZE; ++child_round) {
                const uint64_t second = population[order[next_random(&random_state) % 51]];
                const size_t cut = next_random(&random_state) % target_length;
                uint64_t children[2] = {0, 0};
                for (size_t position = 0; position < target_length; ++position) {
                    const unsigned shift = (unsigned)(8 * position);
                    const uint64_t first_gene = (first >> shift) & UINT64_C(0xFF);
                    const uint64_t second_gene = (second >> shift) & UINT64_C(0xFF);
                    children[0] |= (position < cut ? first_gene : second_gene) << shift;
                    children[1] |= (position < cut ? second_gene : first_gene) << shift;
                }
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
    return -1;
}
