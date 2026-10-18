#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <limits>

namespace {
bool integer_in_range(double value, int minimum, int maximum) noexcept {
    return std::isfinite(value) && value >= static_cast<double>(minimum) &&
        value <= static_cast<double>(maximum) && value == std::trunc(value);
}

double random_unit() noexcept {
    return static_cast<double>(std::rand()) / static_cast<double>(RAND_MAX);
}

std::size_t random_index(std::size_t upper_inclusive) noexcept {
    return static_cast<std::size_t>(std::rand()) % (upper_inclusive + 1);
}

double city_distance(const std::int64_t cities[2][2], int left, int right) noexcept {
    const double dx = static_cast<double>(cities[left][0] - cities[right][0]);
    const double dy = static_cast<double>(cities[left][1] - cities[right][1]);
    return std::sqrt(dx * dx + dy * dy);
}

void copy_chromosome(int destination[3], const int source[3]) noexcept {
    for (std::size_t i = 0; i < 3; ++i) destination[i] = source[i];
}

void repair_crossed_chromosome(int chromosome[3], const int cities_list[1],
                               std::size_t segment_start, std::size_t segment_end) noexcept {
    bool has_duplicate = false;
    for (std::size_t i = 0; i < 3; ++i)
        for (std::size_t j = 0; j < i; ++j)
            if (chromosome[i] == chromosome[j]) has_duplicate = true;
    if (!has_duplicate) return;
    for (std::size_t segment_index = 0; segment_index <= segment_end - segment_start; ++segment_index) {
        std::size_t target_index = 0;
        const std::size_t current_index = segment_start + segment_index;
        for (std::size_t chromosome_index = 1; chromosome_index < 2; ++chromosome_index) {
            if (chromosome_index == current_index) continue;
            if (chromosome[chromosome_index] == chromosome[current_index]) {
                target_index = chromosome_index;
                break;
            }
        }
        if (target_index != 0) {
            int available[1] = {cities_list[0]};
            std::size_t available_count = 1;
            for (std::size_t i = 0; i < 3; ++i)
                if (available_count > 0 && chromosome[i] == available[0]) available_count = 0;
            if (available_count > 0) chromosome[target_index] = available[random_index(available_count - 1)];
        }
    }
}

void population_fitness(const int population[8][3], std::size_t population_size,
                       const std::int64_t cities[2][2], double fitness[8],
                       int best_path[3], double &best_distance) noexcept {
    for (std::size_t person = 0; person < population_size; ++person) {
        double total_distance = 0.0;
        for (std::size_t i = 0; i < 2; ++i)
            total_distance += city_distance(cities, population[person][i], population[person][i + 1]);
        fitness[person] = 1.0 / total_distance;
        if (total_distance < best_distance) {
            copy_chromosome(best_path, population[person]);
            best_distance = total_distance;
        }
    }
}
}

extern "C" std::int64_t travelling_salesman_python_genetic(
    const double *input, std::size_t input_length, double *output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length != 8) return -1;
    for (std::size_t i = 0; i < input_length; ++i) if (!std::isfinite(input[i])) return -1;
    if (!integer_in_range(input[0], 2, 8) || static_cast<int>(input[0]) % 2 != 0 ||
        !integer_in_range(input[1], 0, 12)) return -1;
    if (input[2] < 0.0 || input[2] > 1.0 || input[3] < 0.0 || input[3] > 1.0) return -1;
    for (std::size_t i = 4; i < 8; ++i) {
        if (!integer_in_range(input[i], -16, 16)) return -1;
    }
    const std::int64_t cities[2][2] = {{static_cast<std::int64_t>(input[4]), static_cast<std::int64_t>(input[5])},
                                       {static_cast<std::int64_t>(input[6]), static_cast<std::int64_t>(input[7])}};
    if (cities[0][0] == cities[1][0] && cities[0][1] == cities[1][1]) return -1;
    const std::size_t population_size = static_cast<std::size_t>(input[0]);
    const std::size_t iterations = static_cast<std::size_t>(input[1]);

    const int cities_list[1] = {1};
    int population[8][3];
    for (std::size_t person = 0; person < population_size; ++person) {
        population[person][0] = 0;
        const std::size_t sampled_index = random_index(0); // random.sample([1], 1).
        population[person][1] = cities_list[sampled_index];
        population[person][2] = 0;
    }

    double fitness[8] = {};
    int best_path[3] = {0, 0, 0};
    double best_distance = std::numeric_limits<double>::infinity();
    population_fitness(population, population_size, cities, fitness, best_path, best_distance);
    for (std::size_t generation = 0; generation < iterations; ++generation) {
        double total_probability = 0.0;
        for (std::size_t i = 0; i < population_size; ++i) total_probability += fitness[i];
        double probabilities[8] = {};
        for (std::size_t i = 0; i < population_size; ++i) probabilities[i] = fitness[i] / total_probability;

        int selected[8][3];
        for (std::size_t person = 0; person < population_size; ++person)
            copy_chromosome(selected[person], population[person]);
        for (std::size_t person = 0; person < population_size; ++person) {
            double cumulative = 0.0;
            const double draw = random_unit();
            for (std::size_t candidate = 0; candidate < population_size; ++candidate) {
                cumulative += probabilities[candidate];
                if (draw <= cumulative) {
                    copy_chromosome(selected[person], population[candidate]);
                    break;
                }
            }
        }
        for (std::size_t person = 0; person < population_size; ++person)
            copy_chromosome(population[person], selected[person]);

        const std::size_t half = population_size / 2;
        for (std::size_t person = 0; person < half; ++person) {
            int child_a[3], child_b[3];
            copy_chromosome(child_a, population[person]);
            copy_chromosome(child_b, population[person + half]);
            if (random_unit() <= input[2]) {
                std::size_t first = random_index(2);
                std::size_t second = random_index(2);
                if (first > second) { const auto temporary = first; first = second; second = temporary; }
                for (std::size_t i = first; i <= second; ++i) {
                    const int temporary = child_a[i]; child_a[i] = child_b[i]; child_b[i] = temporary;
                }
                repair_crossed_chromosome(child_a, cities_list, first, second);
                repair_crossed_chromosome(child_b, cities_list, first, second);
            }
            copy_chromosome(population[person], child_a);
            copy_chromosome(population[person + half], child_b);
        }
        for (std::size_t person = 0; person < population_size; ++person) {
            int chromosome[3];
            copy_chromosome(chromosome, population[person]);
            if (random_unit() <= input[3]) {
                const std::size_t first = random_index(0) + 1;
                const std::size_t second = random_index(0) + 1;
                const int temporary = chromosome[first]; chromosome[first] = chromosome[second]; chromosome[second] = temporary;
            }
            copy_chromosome(population[person], chromosome);
        }
        population_fitness(population, population_size, cities, fitness, best_path, best_distance);
    }

    const double staged[5] = {3.0, static_cast<double>(best_path[0]), static_cast<double>(best_path[1]),
                              static_cast<double>(best_path[2]), best_distance};
    if (output == nullptr || output_capacity < 5) return -2;
    for (std::size_t i = 0; i < 5; ++i) output[i] = staged[i];
    return 5;
}
