#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

static int integer_in_range(double value, int minimum, int maximum) {
    return isfinite(value) && value >= (double)minimum && value <= (double)maximum && value == trunc(value);
}

static double random_unit(void) {
    return (double)rand() / (double)RAND_MAX;
}

static size_t random_index(size_t upper_inclusive) {
    return (size_t)rand() % (upper_inclusive + 1u);
}

static double city_distance(const int64_t cities[2][2], int left, int right) {
    const double dx = (double)(cities[left][0] - cities[right][0]);
    const double dy = (double)(cities[left][1] - cities[right][1]);
    return sqrt(dx * dx + dy * dy);
}

static void copy_chromosome(int destination[3], const int source[3]) {
    for (size_t i = 0; i < 3; ++i) destination[i] = source[i];
}

static void repair_crossed_chromosome(int chromosome[3], const int cities_list[1],
                                      size_t segment_start, size_t segment_end) {
    int has_duplicate = 0;
    for (size_t i = 0; i < 3; ++i) {
        for (size_t j = 0; j < i; ++j) {
            if (chromosome[i] == chromosome[j]) has_duplicate = 1;
        }
    }
    if (!has_duplicate) return;
    for (size_t segment_index = 0; segment_index <= segment_end - segment_start; ++segment_index) {
        size_t target_index = 0;
        const size_t current_index = segment_start + segment_index;
        for (size_t chromosome_index = 1; chromosome_index < 2; ++chromosome_index) {
            if (chromosome_index == current_index) continue;
            if (chromosome[chromosome_index] == chromosome[current_index]) {
                target_index = chromosome_index;
                break;
            }
        }
        if (target_index != 0) {
            int available[1] = {cities_list[0]};
            size_t available_count = 1;
            for (size_t i = 0; i < 3; ++i) {
                if (available_count > 0 && chromosome[i] == available[0]) available_count = 0;
            }
            if (available_count > 0) chromosome[target_index] = available[random_index(available_count - 1u)];
        }
    }
}

static void population_fitness(const int population[8][3], size_t population_size,
                               const int64_t cities[2][2], double fitness[8],
                               int best_path[3], double *best_distance) {
    for (size_t person = 0; person < population_size; ++person) {
        double total_distance = 0.0;
        for (size_t i = 0; i < 2; ++i)
            total_distance += city_distance(cities, population[person][i], population[person][i + 1]);
        fitness[person] = 1.0 / total_distance;
        if (total_distance < *best_distance) {
            copy_chromosome(best_path, population[person]);
            *best_distance = total_distance;
        }
    }
}

int64_t travelling_salesman_python_genetic(const double *input, size_t input_length,
                                           double *output, size_t output_capacity) {
    if (input == NULL || input_length != 8) return -1;
    for (size_t i = 0; i < input_length; ++i) if (!isfinite(input[i])) return -1;
    if (!integer_in_range(input[0], 2, 8) || ((int)input[0] % 2) != 0 ||
        !integer_in_range(input[1], 0, 12)) return -1;
    if (input[2] < 0.0 || input[2] > 1.0 || input[3] < 0.0 || input[3] > 1.0) return -1;
    for (size_t i = 4; i < 8; ++i) {
        if (!integer_in_range(input[i], -16, 16)) return -1;
    }
    const int64_t cities[2][2] = {{(int64_t)input[4], (int64_t)input[5]},
                                  {(int64_t)input[6], (int64_t)input[7]}};
    if (cities[0][0] == cities[1][0] && cities[0][1] == cities[1][1]) return -1;
    const size_t population_size = (size_t)input[0];
    const size_t iterations = (size_t)input[1];

    /* init: random.sample([1], 1) for every individual still consumes RNG state. */
    const int cities_list[1] = {1};
    int population[8][3];
    for (size_t person = 0; person < population_size; ++person) {
        population[person][0] = 0;
        const size_t sampled_index = random_index(0);
        population[person][1] = cities_list[sampled_index];
        population[person][2] = 0;
    }

    double fitness[8] = {0.0};
    int best_path[3] = {0, 0, 0};
    double best_distance = INFINITY;
    population_fitness(population, population_size, cities, fitness, best_path, &best_distance);

    for (size_t generation = 0; generation < iterations; ++generation) {
        double total_probability = 0.0;
        for (size_t i = 0; i < population_size; ++i) total_probability += fitness[i];
        double probabilities[8] = {0.0};
        for (size_t i = 0; i < population_size; ++i) probabilities[i] = fitness[i] / total_probability;

        int selected[8][3];
        for (size_t person = 0; person < population_size; ++person) copy_chromosome(selected[person], population[person]);
        for (size_t person = 0; person < population_size; ++person) {
            double cumulative = 0.0;
            const double draw = random_unit(); /* source random.uniform(0, 1) */
            for (size_t candidate = 0; candidate < population_size; ++candidate) {
                cumulative += probabilities[candidate];
                if (draw <= cumulative) {
                    copy_chromosome(selected[person], population[candidate]);
                    break;
                }
            }
        }
        for (size_t person = 0; person < population_size; ++person) copy_chromosome(population[person], selected[person]);

        const size_t half = population_size / 2u;
        for (size_t person = 0; person < half; ++person) {
            int child_a[3], child_b[3];
            copy_chromosome(child_a, population[person]);
            copy_chromosome(child_b, population[person + half]);
            if (random_unit() <= input[2]) {
                size_t first = random_index(2);
                size_t second = random_index(2);
                if (first > second) { const size_t temporary = first; first = second; second = temporary; }
                for (size_t i = first; i <= second; ++i) {
                    const int temporary = child_a[i]; child_a[i] = child_b[i]; child_b[i] = temporary;
                }
                repair_crossed_chromosome(child_a, cities_list, first, second);
                repair_crossed_chromosome(child_b, cities_list, first, second);
            }
            copy_chromosome(population[person], child_a);
            copy_chromosome(population[person + half], child_b);
        }

        for (size_t person = 0; person < population_size; ++person) {
            int chromosome[3];
            copy_chromosome(chromosome, population[person]);
            if (random_unit() <= input[3]) {
                const size_t first = random_index(0) + 1u;
                const size_t second = random_index(0) + 1u;
                const int temporary = chromosome[first]; chromosome[first] = chromosome[second]; chromosome[second] = temporary;
            }
            copy_chromosome(population[person], chromosome);
        }
        population_fitness(population, population_size, cities, fitness, best_path, &best_distance);
    }

    double staged[5] = {3.0, (double)best_path[0], (double)best_path[1],
                        (double)best_path[2], best_distance};
    if (output == NULL || output_capacity < 5) return -2;
    for (size_t i = 0; i < 5; ++i) output[i] = staged[i];
    return 5;
}
