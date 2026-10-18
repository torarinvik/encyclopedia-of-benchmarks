package travelling_salesman_python_genetic

import "core:c"
import "core:math"
import "core:math/rand"

MAX_POPULATION :: 8
OUTPUT_LENGTH :: 5

route_distance :: proc(x0, y0, x1, y1: f64, first_city, second_city: int) -> f64 {
	if first_city == second_city do return 0.0
	if first_city == 0 do return math.sqrt_f64((x0-x1)*(x0-x1) + (y0-y1)*(y0-y1))
	return math.sqrt_f64((x1-x0)*(x1-x0) + (y1-y0)*(y1-y0))
}

calculate_fitness :: proc(chromosomes: ^[MAX_POPULATION][3]int, population: int,
	x0, y0, x1, y1: f64, fitness: ^[MAX_POPULATION]f64,
	best_path: ^[3]int, best_distance: ^f64) {
	for chromosome_index := 0; chromosome_index < population; chromosome_index += 1 {
		total_distance := 0.0
		for edge := 0; edge < 2; edge += 1 {
			total_distance += route_distance(x0, y0, x1, y1,
				chromosomes^[chromosome_index][edge], chromosomes^[chromosome_index][edge+1])
		}
		fitness^[chromosome_index] = 1.0 / total_distance
		if total_distance < best_distance^ {
			best_path^ = chromosomes^[chromosome_index]
			best_distance^ = total_distance
		}
	}
}

repair_crossed_child :: proc(child: ^[3]int, segment_start, segment_end: int, cities_list: [1]int) {
	unique_count := 1
	if child^[1] != child^[0] do unique_count += 1
	if child^[2] != child^[0] && child^[2] != child^[1] do unique_count += 1
	if unique_count == 3 do return
	for segment_index := 0; segment_index <= segment_end-segment_start; segment_index += 1 {
		target_index := 0
		for chromosome_index := 1; chromosome_index < 2; chromosome_index += 1 {
			if chromosome_index == segment_start+segment_index do continue
			if child^[chromosome_index] == child^[segment_start+segment_index] {
				target_index = chromosome_index
				break
			}
		}
		if target_index != 0 {
			city_available := cities_list[0]
			for chromosome_index := 0; chromosome_index < 3; chromosome_index += 1 {
				if child^[chromosome_index] == city_available do city_available = -1
			}
			if city_available != -1 {
				_ = rand.int_max(1)
				child^[target_index] = city_available
			}
		}
	}
}

@(export)
travelling_salesman_python_genetic :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != 8 do return -1
	for index := 0; index < 8; index += 1 {
		value := input[index]
		if math.is_nan(value) || math.is_inf(value) do return -1
	}
	population_value, iterations_value := input[0], input[1]
	crossover_probability, mutation_probability := input[2], input[3]
	if population_value < 2.0 || population_value > 8.0 || population_value != math.floor_f64(population_value) do return -1
	population := int(population_value)
	if population % 2 != 0 do return -1
	if iterations_value < 0.0 || iterations_value > 12.0 || iterations_value != math.floor_f64(iterations_value) do return -1
	if crossover_probability < 0.0 || crossover_probability > 1.0 ||
		mutation_probability < 0.0 || mutation_probability > 1.0 do return -1
	for index := 4; index < 8; index += 1 {
		coordinate := input[index]
		if coordinate < -16.0 || coordinate > 16.0 || coordinate != math.floor_f64(coordinate) do return -1
	}
	if input[4] == input[6] && input[5] == input[7] do return -1
	iterations := int(iterations_value)
	x0, y0, x1, y1 := input[4], input[5], input[6], input[7]

	// init(): sample the sole non-origin city once for each chromosome.
	cities_list: [1]int = {1}
	var chromosomes: [MAX_POPULATION][3]int
	for individual := 0; individual < population; individual += 1 {
		sampled_index := rand.int_max(1)
		chromosomes[individual] = {0, cities_list[sampled_index], 0}
	}

	var fitness: [MAX_POPULATION]f64
	best_path: [3]int = {0, 0, 0}
	best_distance := 1.0e300
	calculate_fitness(&chromosomes, population, x0, y0, x1, y1, &fitness, &best_path, &best_distance)

	for _ in 0 .. iterations {
		total_probability := 0.0
		for index := 0; index < population; index += 1 { total_probability += fitness[index] }
		var probabilities: [MAX_POPULATION]f64
		for index := 0; index < population; index += 1 { probabilities[index] = fitness[index] / total_probability }

		// chose_rws(): deep-copy then replace each chromosome at the first cumulative hit.
		selected := chromosomes
		for individual := 0; individual < population; individual += 1 {
			cumulative := 0.0
			roll := rand.float64_range(0.0, 1.0)
			for candidate := 0; candidate < population; candidate += 1 {
				cumulative += probabilities[candidate]
				if roll <= cumulative {
					selected[individual] = chromosomes[candidate]
					break
				}
			}
		}
		chromosomes = selected

		for first := 0; first < population/2; first += 1 {
			child_a := chromosomes[first]
			child_b := chromosomes[first+population/2]
			if rand.float64_range(0.0, 1.0) <= crossover_probability {
				segment_a := rand.int_range(0, 3)
				segment_b := rand.int_range(0, 3)
				segment_start, segment_end := min(segment_a, segment_b), max(segment_a, segment_b)
				for segment_index := segment_start; segment_index <= segment_end; segment_index += 1 {
					child_a[segment_index], child_b[segment_index] = child_b[segment_index], child_a[segment_index]
				}
				repair_crossed_child(&child_a, segment_start, segment_end, cities_list)
				repair_crossed_child(&child_b, segment_start, segment_end, cities_list)
			}
			chromosomes[first] = child_a
			chromosomes[first+population/2] = child_b
		}

		for individual := 0; individual < population; individual += 1 {
			chromosome := chromosomes[individual]
			if rand.float64_range(0.0, 1.0) <= mutation_probability {
				location_a := rand.int_range(1, 2)
				location_b := rand.int_range(1, 2)
				chromosome[location_a], chromosome[location_b] = chromosome[location_b], chromosome[location_a]
			}
			chromosomes[individual] = chromosome
		}
		calculate_fitness(&chromosomes, population, x0, y0, x1, y1, &fitness, &best_path, &best_distance)
	}

	staged: [OUTPUT_LENGTH]f64 = {3.0, f64(best_path[0]), f64(best_path[1]), f64(best_path[2]), best_distance}
	if output == nil || output_capacity < c.size_t(OUTPUT_LENGTH) do return -2
	for index := 0; index < OUTPUT_LENGTH; index += 1 { output[index] = staged[index] }
	return i64(OUTPUT_LENGTH)
}
