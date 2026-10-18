module travelling_salesman_python_genetic;

extern fn double sqrt(double value);
extern fn double trunc(double value);
extern fn int rand();

fn bool finite_value(double value) { return value == value && value < 1e300 && value > -1e300; }

fn bool integer_in_range(double value, int minimum, int maximum) {
    return finite_value(value) && value >= (double)minimum && value <= (double)maximum && value == trunc(value);
}

fn double random_unit() { return (double)rand() / 2147483647.0; }
fn usz random_index(usz upper_inclusive) { return (usz)rand() % (upper_inclusive + 1); }

fn double city_distance(double* cities, long left, long right) {
    double dx = cities[left * 2] - cities[right * 2];
    double dy = cities[left * 2 + 1] - cities[right * 2 + 1];
    return sqrt(dx * dx + dy * dy);
}

fn void copy_chromosome(long* destination, long* source) {
    for (usz i = 0; i < 3; i++) destination[i] = source[i];
}

fn void repair_crossed_chromosome(long* chromosome, long* cities_list, usz segment_start, usz segment_end) {
    bool has_duplicate = false;
    for (usz i = 0; i < 3; i++)
        for (usz j = 0; j < i; j++) if (chromosome[i] == chromosome[j]) has_duplicate = true;
    if (!has_duplicate) return;
    for (usz segment_index = 0; segment_index <= segment_end - segment_start; segment_index++) {
        usz current_index = segment_start + segment_index;
        usz target_index = 0;
        for (usz chromosome_index = 1; chromosome_index < 2; chromosome_index++) {
            if (chromosome_index == current_index) continue;
            if (chromosome[chromosome_index] == chromosome[current_index]) {
                target_index = chromosome_index;
                break;
            }
        }
        if (target_index != 0) {
            long available = cities_list[0];
            bool available_exists = true;
            for (usz i = 0; i < 3; i++) if (chromosome[i] == available) available_exists = false;
            if (available_exists) {
                (void)random_index(0); // random.sample(available, 1) with one remaining city.
                chromosome[target_index] = available;
            }
        }
    }
}

fn void population_fitness(long* population, usz population_size, double* cities,
                           double* fitness, long* best_path, double* best_distance) {
    for (usz person = 0; person < population_size; person++) {
        double total_distance = 0.0;
        for (usz i = 0; i < 2; i++)
            total_distance += city_distance(cities, population[person * 3 + i], population[person * 3 + i + 1]);
        fitness[person] = 1.0 / total_distance;
        if (total_distance < best_distance[0]) {
            for (usz i = 0; i < 3; i++) best_path[i] = population[person * 3 + i];
            best_distance[0] = total_distance;
        }
    }
}

fn long travelling_salesman_python_genetic(double* input, usz input_length,
                                           double* output, usz output_capacity)
    @export("travelling_salesman_python_genetic") {
    if (input == null || input_length != 8) return -1L;
    for (usz i = 0; i < input_length; i++) if (!finite_value(input[i])) return -1L;
    if (!integer_in_range(input[0], 2, 8) || (long)input[0] % 2 != 0 ||
        !integer_in_range(input[1], 0, 12)) return -1L;
    if (input[2] < 0.0 || input[2] > 1.0 || input[3] < 0.0 || input[3] > 1.0) return -1L;
    for (usz i = 4; i < 8; i++) if (!integer_in_range(input[i], -16, 16)) return -1L;
    if (input[4] == input[6] && input[5] == input[7]) return -1L;
    usz population_size = (usz)(long)input[0];
    usz iterations = (usz)(long)input[1];
    double[4] cities = {input[4], input[5], input[6], input[7]};
    long[1] cities_list = {1};
    long[24] population = zeroed;
    for (usz person = 0; person < population_size; person++) {
        population[person * 3] = 0;
        usz sampled_index = random_index(0); // random.sample([1], 1).
        population[person * 3 + 1] = cities_list[sampled_index];
        population[person * 3 + 2] = 0;
    }

    double[8] fitness = zeroed;
    long[3] best_path = {0, 0, 0};
    double best_distance = 1.0e300;
    population_fitness(&population[0], population_size, &cities[0], &fitness[0], &best_path[0], &best_distance);
    for (usz generation = 0; generation < iterations; generation++) {
        double total_probability = 0.0;
        for (usz i = 0; i < population_size; i++) total_probability += fitness[i];
        double[8] probabilities = zeroed;
        for (usz i = 0; i < population_size; i++) probabilities[i] = fitness[i] / total_probability;

        long[24] selected = zeroed;
        for (usz person = 0; person < population_size; person++)
            copy_chromosome(&selected[person * 3], &population[person * 3]);
        for (usz person = 0; person < population_size; person++) {
            double cumulative = 0.0;
            double draw = random_unit();
            for (usz candidate = 0; candidate < population_size; candidate++) {
                cumulative += probabilities[candidate];
                if (draw <= cumulative) {
                    copy_chromosome(&selected[person * 3], &population[candidate * 3]);
                    break;
                }
            }
        }
        for (usz person = 0; person < population_size; person++)
            copy_chromosome(&population[person * 3], &selected[person * 3]);

        usz half = population_size / 2;
        for (usz person = 0; person < half; person++) {
            long[3] child_a = zeroed;
            long[3] child_b = zeroed;
            copy_chromosome(&child_a[0], &population[person * 3]);
            copy_chromosome(&child_b[0], &population[(person + half) * 3]);
            if (random_unit() <= input[2]) {
                usz first = random_index(2);
                usz second = random_index(2);
                if (first > second) { usz temporary = first; first = second; second = temporary; }
                for (usz i = first; i <= second; i++) {
                    long temporary = child_a[i]; child_a[i] = child_b[i]; child_b[i] = temporary;
                }
                repair_crossed_chromosome(&child_a[0], &cities_list[0], first, second);
                repair_crossed_chromosome(&child_b[0], &cities_list[0], first, second);
            }
            copy_chromosome(&population[person * 3], &child_a[0]);
            copy_chromosome(&population[(person + half) * 3], &child_b[0]);
        }

        for (usz person = 0; person < population_size; person++) {
            long[3] chromosome = zeroed;
            copy_chromosome(&chromosome[0], &population[person * 3]);
            if (random_unit() <= input[3]) {
                usz first = random_index(0) + 1;
                usz second = random_index(0) + 1;
                long temporary = chromosome[first]; chromosome[first] = chromosome[second]; chromosome[second] = temporary;
            }
            copy_chromosome(&population[person * 3], &chromosome[0]);
        }
        population_fitness(&population[0], population_size, &cities[0], &fitness[0], &best_path[0], &best_distance);
    }

    double[5] staged = {3.0, (double)best_path[0], (double)best_path[1], (double)best_path[2], best_distance};
    if (output == null || output_capacity < 5) return -2L;
    for (usz i = 0; i < 5; i++) output[i] = staged[i];
    return 5L;
}
