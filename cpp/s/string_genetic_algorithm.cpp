#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t POPULATION_SIZE = 200;
constexpr std::size_t SELECTED_SIZE = 50;
constexpr std::size_t ELITE_SIZE = 66;

std::uint32_t next_random(std::uint32_t &state) noexcept {
    state = static_cast<std::uint32_t>((static_cast<std::uint64_t>(state) * 48271u) % 2147483647u);
    return state;
}

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t string_genetic_algorithm(const std::int64_t *values, std::size_t length,
                                                  std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 6 || length > 44) return -2;
    const auto target_length_value = values[0];
    const auto gene_count_value = values[1];
    const auto seed_value = values[2];
    const auto max_generations_value = values[3];
    if (target_length_value < 1 || target_length_value > 8 || gene_count_value < 1 || gene_count_value > 32 ||
        seed_value < 1 || seed_value >= 2147483647 || max_generations_value < 1 || max_generations_value > 1000)
        return -2;
    const auto target_length = static_cast<std::size_t>(target_length_value);
    const auto gene_count = static_cast<std::size_t>(gene_count_value);
    const auto max_generations = static_cast<std::size_t>(max_generations_value);
    if (length != 4 + target_length + gene_count) return -2;
    std::uint8_t target[8]{};
    std::uint8_t genes[32]{};
    for (std::size_t index = 0; index < target_length; ++index) {
        const auto value = values[4 + index];
        if (value < 32 || value > 126) return -2;
        target[index] = static_cast<std::uint8_t>(value);
    }
    for (std::size_t index = 0; index < gene_count; ++index) {
        const auto value = values[4 + target_length + index];
        if (value < 32 || value > 126) return -2;
        genes[index] = static_cast<std::uint8_t>(value);
    }
    for (std::size_t position = 0; position < target_length; ++position) {
        bool found = false;
        for (std::size_t gene = 0; gene < gene_count; ++gene)
            if (genes[gene] == target[position]) found = true;
        if (!found) return -2;
    }
    if (output == nullptr) return -2;

    auto random_state = static_cast<std::uint32_t>(seed_value);
    std::uint64_t population[POPULATION_SIZE]{};
    std::uint64_t next_population[POPULATION_SIZE]{};
    std::uint8_t scores[POPULATION_SIZE]{};
    std::size_t order[POPULATION_SIZE]{};
    for (std::size_t individual = 0; individual < POPULATION_SIZE; ++individual) {
        std::uint64_t word = 0;
        for (std::size_t position = 0; position < target_length; ++position) {
            const auto gene = genes[next_random(random_state) % gene_count];
            word |= static_cast<std::uint64_t>(gene) << (8 * position);
        }
        population[individual] = word;
    }

    std::int64_t total_population = 0;
    for (std::size_t generation = 1; generation <= max_generations; ++generation) {
        total_population += static_cast<std::int64_t>(POPULATION_SIZE);
        for (std::size_t individual = 0; individual < POPULATION_SIZE; ++individual) {
            std::uint8_t score = 0;
            for (std::size_t position = 0; position < target_length; ++position)
                score += static_cast<std::uint8_t>(((population[individual] >> (8 * position)) & 0xFFu) == target[position]);
            scores[individual] = score;
            order[individual] = individual;
            if (score == target_length_value) {
                if (output_capacity < 16) return -2;
                write_i64_le(output, 0, static_cast<std::int64_t>(generation));
                write_i64_le(output, 8, total_population);
                return 16;
            }
        }
        for (std::size_t index = 1; index < POPULATION_SIZE; ++index) {
            const auto selected = order[index];
            auto insertion = index;
            while (insertion > 0 && scores[order[insertion - 1]] < scores[selected]) {
                order[insertion] = order[insertion - 1];
                --insertion;
            }
            order[insertion] = selected;
        }
        std::size_t next_count = 0;
        for (; next_count < ELITE_SIZE; ++next_count) next_population[next_count] = population[order[next_count]];
        for (std::size_t parent_rank = 0; parent_rank < SELECTED_SIZE && next_count < POPULATION_SIZE; ++parent_rank) {
            const auto first = population[order[parent_rank]];
            const auto child_count = static_cast<std::size_t>(scores[order[parent_rank]]) * 100 / target_length + 1;
            const auto bounded_child_count = child_count < 10 ? child_count : 10;
            for (std::size_t child_round = 0; child_round < bounded_child_count && next_count < POPULATION_SIZE; ++child_round) {
                const auto second = population[order[next_random(random_state) % 51]];
                const auto cut = next_random(random_state) % target_length;
                std::uint64_t children[2] = {0, 0};
                for (std::size_t position = 0; position < target_length; ++position) {
                    const auto shift = 8 * position;
                    const auto first_gene = (first >> shift) & 0xFFu;
                    const auto second_gene = (second >> shift) & 0xFFu;
                    children[0] |= (position < cut ? first_gene : second_gene) << shift;
                    children[1] |= (position < cut ? second_gene : first_gene) << shift;
                }
                for (std::size_t child_index = 0; child_index < 2; ++child_index) {
                    if (next_random(random_state) % 5 < 2) {
                        const auto position = next_random(random_state) % target_length;
                        const auto shift = 8 * position;
                        const auto replacement = genes[next_random(random_state) % gene_count];
                        children[child_index] = (children[child_index] & ~(UINT64_C(0xFF) << shift)) |
                                                (static_cast<std::uint64_t>(replacement) << shift);
                    }
                    if (next_count < POPULATION_SIZE) next_population[next_count++] = children[child_index];
                }
                if (next_count == POPULATION_SIZE) break;
            }
            if (next_count == POPULATION_SIZE) break;
        }
        for (std::size_t index = 0; index < POPULATION_SIZE; ++index) population[index] = next_population[index];
    }
    return -1;
}
