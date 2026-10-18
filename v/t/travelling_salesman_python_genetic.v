module travelling_salesman_python_genetic

import math
import rand

const max_population = 8
const output_length = 5

fn route_distance(x0 f64, y0 f64, x1 f64, y1 f64, first_city int, second_city int) f64 {
	if first_city == second_city { return 0.0 }
	delta_x, delta_y := x0 - x1, y0 - y1
	return math.sqrt(delta_x * delta_x + delta_y * delta_y)
}

fn calculate_fitness(chromosomes [max_population][3]int, population int, x0 f64, y0 f64,
	x1 f64, y1 f64, mut fitness [max_population]f64, mut best_path [3]int,
	mut best_distance f64) {
	for chromosome_index in 0 .. population {
		mut total_distance := 0.0
		for edge in 0 .. 2 {
			total_distance += route_distance(x0, y0, x1, y1,
				chromosomes[chromosome_index][edge], chromosomes[chromosome_index][edge + 1])
		}
		fitness[chromosome_index] = 1.0 / total_distance
		if total_distance < best_distance {
			best_path = chromosomes[chromosome_index]
			best_distance = total_distance
		}
	}
}

fn repair_child(mut child [3]int, segment_start int, segment_end int) {
	mut unique_count := 1
	if child[1] != child[0] { unique_count++ }
	if child[2] != child[0] && child[2] != child[1] { unique_count++ }
	if unique_count == 3 { return }
	for segment_index in 0 .. (segment_end - segment_start + 1) {
		mut target_index := 0
		for chromosome_index in 1 .. 2 {
			if chromosome_index == segment_start + segment_index { continue }
			if child[chromosome_index] == child[segment_start + segment_index] {
				target_index = chromosome_index
				break
			}
		}
		if target_index != 0 {
			mut available_city := 1
			for city in child {
				if city == available_city { available_city = -1 }
			}
			if available_city != -1 {
				available_index := rand.int_in_range(0, 1) or { 0 }
				_ = available_index
				child[target_index] = available_city
			}
		}
	}
}

@[export: 'travelling_salesman_python_genetic']
pub fn travelling_salesman_python_genetic(input &f64, input_length usize, mut output &f64,
	output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length != 8 { return -1 }
		for index in 0 .. 8 {
			if !input[index].is_finite() { return -1 }
		}
		population_value, iterations_value := input[0], input[1]
		crossover_probability, mutation_probability := input[2], input[3]
		if population_value < 2.0 || population_value > 8.0 || population_value != math.floor(population_value) { return -1 }
		population := int(population_value)
		if population % 2 != 0 { return -1 }
		if iterations_value < 0.0 || iterations_value > 12.0 || iterations_value != math.floor(iterations_value) { return -1 }
		if crossover_probability < 0.0 || crossover_probability > 1.0 ||
			mutation_probability < 0.0 || mutation_probability > 1.0 { return -1 }
		for index in 4 .. 8 {
			coordinate := input[index]
			if coordinate < -16.0 || coordinate > 16.0 || coordinate != math.floor(coordinate) { return -1 }
		}
		if input[4] == input[6] && input[5] == input[7] { return -1 }
		iterations := int(iterations_value)
		x0, y0, x1, y1 := input[4], input[5], input[6], input[7]

		// init(): sample the sole non-origin city once per individual.
		cities_list := [1]int{1}
		mut chromosomes := [max_population][3]int{}
		for individual in 0 .. population {
			sampled_index := rand.int_in_range(0, 1) or { 0 }
			chromosomes[individual] = [0, cities_list[sampled_index], 0]
		}

		mut fitness := [max_population]f64{}
		mut best_path := [3]int{}
		mut best_distance := 1.0e300
		calculate_fitness(chromosomes, population, x0, y0, x1, y1, mut fitness, mut best_path, mut best_distance)

		for _ in 0 .. iterations {
			mut total_probability := 0.0
			for index in 0 .. population { total_probability += fitness[index] }
			mut probabilities := [max_population]f64{}
			for index in 0 .. population { probabilities[index] = fitness[index] / total_probability }

			// chose_rws(): copy the population, then replace each selected chromosome.
			mut selected := chromosomes
			for individual in 0 .. population {
				mut cumulative := 0.0
				roll := rand.f64()
				for candidate in 0 .. population {
					cumulative += probabilities[candidate]
					if roll <= cumulative {
						selected[individual] = chromosomes[candidate]
						break
					}
				}
			}
			chromosomes = selected

			for first in 0 .. population / 2 {
				mut child_a := chromosomes[first]
				mut child_b := chromosomes[first + population / 2]
				if rand.f64() <= crossover_probability {
					segment_a := rand.int_in_range(0, 3) or { 0 }
					segment_b := rand.int_in_range(0, 3) or { 0 }
					segment_start, segment_end := segment_a, segment_b
					if segment_start > segment_end { segment_start, segment_end = segment_end, segment_start }
					for segment_index in segment_start .. (segment_end + 1) {
						temporary := child_a[segment_index]
						child_a[segment_index] = child_b[segment_index]
						child_b[segment_index] = temporary
					}
					repair_child(mut child_a, segment_start, segment_end)
					repair_child(mut child_b, segment_start, segment_end)
				}
				chromosomes[first] = child_a
				chromosomes[first + population / 2] = child_b
			}

			for individual in 0 .. population {
				mut chromosome := chromosomes[individual]
				if rand.f64() <= mutation_probability {
					location_a := rand.int_in_range(1, 2) or { 1 }
					location_b := rand.int_in_range(1, 2) or { 1 }
					temporary := chromosome[location_a]
					chromosome[location_a] = chromosome[location_b]
					chromosome[location_b] = temporary
				}
				chromosomes[individual] = chromosome
			}
			calculate_fitness(chromosomes, population, x0, y0, x1, y1, mut fitness, mut best_path, mut best_distance)
		}

		mut staged := [output_length]f64{}
		staged[0], staged[1], staged[2], staged[3] = 3.0, f64(best_path[0]), f64(best_path[1]), f64(best_path[2])
		staged[4] = best_distance
		if output == nil || output_capacity < output_length { return -2 }
		for index in 0 .. output_length { output[index] = staged[index] }
		return i64(output_length)
	}
}
