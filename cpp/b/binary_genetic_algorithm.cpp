/* Seeded binary genetic minimization with the pinned MATLAB operator order. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_variables = 32;
constexpr std::size_t max_population = 16;

std::uint64_t next_word(std::uint64_t &state) noexcept
{
    state += UINT64_C(0x9E3779B97F4A7C15);
    std::uint64_t value = state;
    value = (value ^ (value >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
    value = (value ^ (value >> 27)) * UINT64_C(0x94D049BB133111EB);
    return value ^ (value >> 31);
}

std::uint64_t bounded(std::uint64_t &state, std::uint64_t bound) noexcept
{
    const std::uint64_t threshold = (std::uint64_t{0} - bound) % bound;
    for (;;) {
        const std::uint64_t value = next_word(state);
        if (value >= threshold) return value % bound;
    }
}

double unit_random(std::uint64_t &state) noexcept
{
    return static_cast<double>(next_word(state) >> 11) / 9007199254740992.0;
}

int cost_of(std::uint64_t candidate, std::size_t n_var) noexcept
{
    int cost = 0;
    for (std::size_t gene = 0; gene < n_var; ++gene)
        cost += static_cast<int>((candidate >> gene) & UINT64_C(1));
    return cost;
}

std::size_t select_parent(const double probabilities[max_population], std::size_t n_pop,
                          double total, std::uint64_t &state) noexcept
{
    const double target = unit_random(state) * total;
    double cumulative = 0.0;
    for (std::size_t index = 0; index < n_pop; ++index) {
        cumulative += probabilities[index];
        if (target <= cumulative) return index;
    }
    return n_pop - 1;
}

void crossover(std::uint64_t first, std::uint64_t second, std::size_t n_var,
               std::uint64_t &state, std::uint64_t &child1, std::uint64_t &child2) noexcept
{
    const std::uint64_t kind = bounded(state, 3);
    child1 = 0;
    child2 = 0;
    if (kind == 0) {
        const std::size_t cut = static_cast<std::size_t>(bounded(state, n_var - 1)) + 1;
        for (std::size_t gene = 0; gene < n_var; ++gene) {
            const std::uint64_t bit = UINT64_C(1) << gene;
            if (gene < cut) {
                child1 |= first & bit;
                child2 |= second & bit;
            } else {
                child1 |= second & bit;
                child2 |= first & bit;
            }
        }
    } else if (kind == 1) {
        std::size_t low = static_cast<std::size_t>(bounded(state, n_var)) + 1;
        std::size_t high = static_cast<std::size_t>(bounded(state, n_var - 1)) + 1;
        if (high >= low) ++high;
        if (high < low) {
            const std::size_t temporary = low;
            low = high;
            high = temporary;
        }
        for (std::size_t gene = 0; gene < n_var; ++gene) {
            const std::uint64_t bit = UINT64_C(1) << gene;
            const bool exchange = gene >= low && gene < high;
            child1 |= (exchange ? second : first) & bit;
            child2 |= (exchange ? first : second) & bit;
        }
    } else {
        for (std::size_t gene = 0; gene < n_var; ++gene) {
            const std::uint64_t bit = UINT64_C(1) << gene;
            if (bounded(state, 2) == 1) {
                child1 |= first & bit;
                child2 |= second & bit;
            } else {
                child1 |= second & bit;
                child2 |= first & bit;
            }
        }
    }
}
} // namespace

extern "C" std::int64_t binary_genetic_algorithm(const std::int64_t *values,
                                                  std::size_t length) noexcept
{
    if (values == nullptr || length < 4 || length > 5) return -1;
    const std::int64_t seed_value = values[0];
    const std::int64_t n_var_value = values[1];
    const std::int64_t n_pop_value = values[2];
    const std::int64_t max_it_value = values[3];
    if (length != 4 || seed_value < 0 || n_var_value < 2 || n_var_value > 32 ||
        n_pop_value < 2 || n_pop_value > 16 || n_pop_value % 2 != 0 ||
        max_it_value < 1 || max_it_value > 32) return -1;
    const std::size_t n_var = static_cast<std::size_t>(n_var_value);
    const std::size_t n_pop = static_cast<std::size_t>(n_pop_value);
    const std::size_t max_it = static_cast<std::size_t>(max_it_value);
    std::uint64_t state = static_cast<std::uint64_t>(seed_value);
    std::uint64_t population[max_population]{};
    int best_cost = static_cast<int>(n_var) + 1;

    for (std::size_t member = 0; member < n_pop; ++member) {
        std::uint64_t candidate = 0;
        for (std::size_t gene = 0; gene < n_var; ++gene)
            candidate |= bounded(state, 2) << gene;
        population[member] = candidate;
        const int cost = cost_of(candidate, n_var);
        if (cost < best_cost) best_cost = cost;
    }

    for (std::size_t iteration = 0; iteration < max_it; ++iteration) {
        int costs[max_population]{};
        int total_cost = 0;
        for (std::size_t member = 0; member < n_pop; ++member) {
            costs[member] = cost_of(population[member], n_var);
            total_cost += costs[member];
        }
        const double average = static_cast<double>(total_cost) / static_cast<double>(n_pop);
        double probabilities[max_population]{};
        double probability_total = 0.0;
        for (std::size_t member = 0; member < n_pop; ++member) {
            const double scaled = average != 0.0 ? static_cast<double>(costs[member]) / average
                                                 : static_cast<double>(costs[member]);
            probabilities[member] = std::exp(-scaled);
            probability_total += probabilities[member];
        }

        const std::size_t pairs = n_pop / 2;
        std::uint64_t first_children[max_population / 2]{};
        std::uint64_t second_children[max_population / 2]{};
        for (std::size_t pair = 0; pair < pairs; ++pair) {
            const std::size_t first_index = select_parent(probabilities, n_pop, probability_total, state);
            const std::size_t second_index = select_parent(probabilities, n_pop, probability_total, state);
            crossover(population[first_index], population[second_index], n_var, state,
                      first_children[pair], second_children[pair]);
        }

        std::uint64_t offspring[max_population]{};
        for (std::size_t pair = 0; pair < pairs; ++pair) {
            offspring[pair] = first_children[pair];
            offspring[pairs + pair] = second_children[pair];
        }
        for (std::size_t member = 0; member < n_pop; ++member) {
            for (std::size_t gene = 0; gene < n_var; ++gene)
                if (unit_random(state) < 0.02) offspring[member] ^= UINT64_C(1) << gene;
            const int cost = cost_of(offspring[member], n_var);
            if (cost < best_cost) best_cost = cost;
        }

        std::uint64_t merged[max_population * 2];
        std::size_t merged_count = 0;
        for (std::size_t member = 0; member < n_pop; ++member) merged[merged_count++] = population[member];
        for (std::size_t member = 0; member < n_pop; ++member) merged[merged_count++] = offspring[member];
        for (std::size_t index = 1; index < merged_count; ++index) {
            const std::uint64_t selected = merged[index];
            const int selected_cost = cost_of(selected, n_var);
            std::size_t insertion = index;
            while (insertion > 0 && cost_of(merged[insertion - 1], n_var) > selected_cost) {
                merged[insertion] = merged[insertion - 1];
                --insertion;
            }
            merged[insertion] = selected;
        }
        for (std::size_t member = 0; member < n_pop; ++member) population[member] = merged[member];
    }
    return static_cast<std::int64_t>(best_cost);
}
