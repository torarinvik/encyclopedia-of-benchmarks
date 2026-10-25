/*
 * Copyright (c) 2012-2013 Argonne National Laboratory
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

module doe_xsbench_unionized_macro_xs

const invalid_result = -1.0e300
const max_nuclides = 4
const min_gridpoints = 2
const max_gridpoints = 5
const max_union_points = 20
const max_length = 232
const record_size = 6

fn decode(raw i64) f64 {
	return f64(raw) / 1_000_000.0
}

fn binary_search(input &i64, grid_start int, nuclide int, gridpoints int, quarry i64) int {
	unsafe {
		mut minimum := 0
		mut maximum := gridpoints - 1
		first := input[grid_start + (nuclide * gridpoints) * record_size]
		last := input[grid_start + (nuclide * gridpoints + gridpoints - 1) * record_size]
		if first > quarry { return 0 }
		if last < quarry { return gridpoints - 2 }
		for maximum >= minimum {
			middle := minimum + (maximum - minimum) / 2
			energy := input[grid_start + (nuclide * gridpoints + middle) * record_size]
			if energy < quarry { minimum = middle + 1 }
			else if energy > quarry { maximum = middle - 1 }
			else { return middle }
		}
		return maximum
	}
}

fn grid_search(input &i64, union_start int, count int, quarry i64) int {
	unsafe {
		mut lower := 0
		mut upper := count - 1
		mut span := upper - lower
		for span > 1 {
			middle := lower + span / 2
			if input[union_start + middle] > quarry { upper = middle }
			else { lower = middle }
			span = upper - lower
		}
		return lower
	}
}

@[export: 'doe_xsbench_unionized_macro_xs']
pub fn doe_xsbench_unionized_macro_xs(input &i64, length usize) f64 {
	unsafe {
		if input == nil || length < 22 || length > max_length { return invalid_result }
		nuclides_raw := input[0]
		gridpoints_raw := input[1]
		material_nuclides_raw := input[2]
		query_raw := input[3]
		if nuclides_raw < 1 || nuclides_raw > max_nuclides ||
			gridpoints_raw < min_gridpoints || gridpoints_raw > max_gridpoints ||
			material_nuclides_raw < 1 || material_nuclides_raw > nuclides_raw ||
			query_raw < 0 || query_raw > 1_000_000 { return invalid_result }
		nuclides := int(nuclides_raw)
		gridpoints := int(gridpoints_raw)
		material_nuclides := int(material_nuclides_raw)
		union_points := nuclides * gridpoints
		composition_start := 4
		union_start := composition_start + 2 * material_nuclides
		pointer_start := union_start + union_points
		grid_start := pointer_start + union_points * nuclides
		if int(length) != grid_start + union_points * record_size { return invalid_result }

		mut composition_ids := [4]int{}
		mut concentrations := [4]f64{}
		mut used := [4]bool{}
		for item in 0 .. material_nuclides {
			id_raw := input[composition_start + 2 * item]
			concentration_raw := input[composition_start + 2 * item + 1]
			if id_raw < 0 || id_raw >= nuclides_raw || concentration_raw < 0 || concentration_raw > 1_000_000 {
				return invalid_result
			}
			id := int(id_raw)
			if used[id] { return invalid_result }
			used[id] = true
			composition_ids[item] = id
			concentrations[item] = decode(concentration_raw)
		}

		mut union_grid := [20]i64{}
		for index in 0 .. union_points {
			energy := input[union_start + index]
			if energy < 0 || energy > 1_000_000 || (index > 0 && energy <= union_grid[index - 1]) {
				return invalid_result
			}
			union_grid[index] = energy
		}

		mut nuclide_energies := [20]i64{}
		for nuclide in 0 .. nuclides {
			for point in 0 .. gridpoints {
				record := grid_start + (nuclide * gridpoints + point) * record_size
				energy := input[record]
				energy_slot := nuclide * max_gridpoints + point
				if energy < 0 || energy > 1_000_000 ||
					(point > 0 && energy <= nuclide_energies[nuclide * max_gridpoints + point - 1]) {
					return invalid_result
				}
				nuclide_energies[energy_slot] = energy
				for channel in 1 .. record_size {
					if input[record + channel] < 0 || input[record + channel] > 1_000_000 { return invalid_result }
				}
			}
		}

		for union_index in 0 .. union_points {
			mut matches := 0
			for nuclide in 0 .. nuclides {
				for point in 0 .. gridpoints {
					if nuclide_energies[nuclide * max_gridpoints + point] == union_grid[union_index] { matches++ }
				}
			}
			if matches != 1 { return invalid_result }
			for nuclide in 0 .. nuclides {
				pointer := input[pointer_start + union_index * nuclides + nuclide]
			if pointer != i64(binary_search(input, grid_start, nuclide, gridpoints, union_grid[union_index])) {
					return invalid_result
				}
			}
		}

		query_index := grid_search(input, union_start, union_points, query_raw)
		mut macro := [5]f64{}
		query := decode(query_raw)
		for item in 0 .. material_nuclides {
			nuclide := composition_ids[item]
			pointer := int(input[pointer_start + query_index * nuclides + nuclide])
			low_index := if pointer == gridpoints - 1 { pointer - 1 } else { pointer }
			low_record := grid_start + (nuclide * gridpoints + low_index) * record_size
			high_record := low_record + record_size
			low_energy := decode(input[low_record])
			high_energy := decode(input[high_record])
			factor := (high_energy - query) / (high_energy - low_energy)
			for channel in 0 .. 5 {
				low_xs := decode(input[low_record + channel + 1])
				high_xs := decode(input[high_record + channel + 1])
				microscopic := high_xs - factor * (high_xs - low_xs)
				macro[channel] += microscopic * concentrations[item]
			}
		}
		return macro[0] + 2.0 * macro[1] + 3.0 * macro[2] + 5.0 * macro[3] + 7.0 * macro[4]
	}
}
