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

package doe_xsbench_unionized_macro_xs

import "core:c"

INVALID :: -1e300
SCALE_Q :: 1_000_000.0
MAX_NUCLIDES :: 4
MIN_GRIDPOINTS :: 2
MAX_GRIDPOINTS :: 5
MAX_UNION_POINTS :: 20
MAX_LENGTH :: 232
RECORD_SIZE :: 6

decode :: proc(raw: i64) -> f64 {
	return f64(raw) / SCALE_Q
}

binary_search :: proc(input: [^]i64, grid_start, nuclide, gridpoints: int, quarry: i64) -> int {
	minimum := 0
	maximum := gridpoints - 1
	first := input[grid_start + nuclide*gridpoints*RECORD_SIZE]
	last := input[grid_start + (nuclide*gridpoints+gridpoints-1)*RECORD_SIZE]
	if first > quarry do return 0
	if last < quarry do return gridpoints - 2
	for maximum >= minimum {
		middle := minimum + (maximum-minimum)/2
		energy := input[grid_start + (nuclide*gridpoints+middle)*RECORD_SIZE]
		if energy < quarry do minimum = middle + 1
		else if energy > quarry do maximum = middle - 1
		else do return middle
	}
	return maximum
}

grid_search :: proc(input: [^]i64, union_start, count: int, quarry: i64) -> int {
	lower := 0
	upper := count - 1
	span := upper - lower
	for span > 1 {
		middle := lower + span/2
		if input[union_start+middle] > quarry do upper = middle
		else do lower = middle
		span = upper - lower
	}
	return lower
}

@(export)
doe_xsbench_unionized_macro_xs :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < c.size_t(22) || length > c.size_t(MAX_LENGTH) do return INVALID
	nuclides_raw, gridpoints_raw := input[0], input[1]
	material_nuclides_raw, query_raw := input[2], input[3]
	if nuclides_raw < 1 || nuclides_raw > MAX_NUCLIDES ||
		gridpoints_raw < MIN_GRIDPOINTS || gridpoints_raw > MAX_GRIDPOINTS ||
		material_nuclides_raw < 1 || material_nuclides_raw > nuclides_raw ||
		query_raw < 0 || query_raw > 1_000_000 do return INVALID
	nuclides, gridpoints, material_nuclides := int(nuclides_raw), int(gridpoints_raw), int(material_nuclides_raw)
	union_points := nuclides * gridpoints
	composition_start := 4
	union_start := composition_start + 2*material_nuclides
	pointer_start := union_start + union_points
	grid_start := pointer_start + union_points*nuclides
	if int(length) != grid_start + union_points*RECORD_SIZE do return INVALID

	composition_ids: [MAX_NUCLIDES]int = {}
	concentrations: [MAX_NUCLIDES]f64 = {}
	used: [MAX_NUCLIDES]bool = {}
	for item in 0..<material_nuclides {
		id_raw := input[composition_start+2*item]
		concentration_raw := input[composition_start+2*item+1]
		if id_raw < 0 || id_raw >= nuclides_raw || concentration_raw < 0 || concentration_raw > 1_000_000 do return INVALID
		id := int(id_raw)
		if used[id] do return INVALID
		used[id] = true
		composition_ids[item] = id
		concentrations[item] = decode(concentration_raw)
	}

	union_grid: [MAX_UNION_POINTS]i64 = {}
	for index in 0..<union_points {
		energy := input[union_start+index]
		if energy < 0 || energy > 1_000_000 || (index > 0 && energy <= union_grid[index-1]) do return INVALID
		union_grid[index] = energy
	}

	nuclide_energies: [MAX_NUCLIDES*MAX_GRIDPOINTS]i64 = {}
	for nuclide in 0..<nuclides {
		for point in 0..<gridpoints {
			record := grid_start+(nuclide*gridpoints+point)*RECORD_SIZE
			energy := input[record]
			energy_slot := nuclide*MAX_GRIDPOINTS+point
			if energy < 0 || energy > 1_000_000 || (point > 0 && energy <= nuclide_energies[energy_slot-1]) do return INVALID
			nuclide_energies[energy_slot] = energy
			for channel in 1..<RECORD_SIZE {
				field := input[record+channel]
				if field < 0 || field > 1_000_000 do return INVALID
			}
		}
	}

	for union_index in 0..<union_points {
		matches := 0
		for nuclide in 0..<nuclides {
			for point in 0..<gridpoints {
				if nuclide_energies[nuclide*MAX_GRIDPOINTS+point] == union_grid[union_index] do matches += 1
			}
		}
		if matches != 1 do return INVALID
		for nuclide in 0..<nuclides {
			pointer := input[pointer_start+union_index*nuclides+nuclide]
			if pointer != i64(binary_search(input, grid_start, nuclide, gridpoints, union_grid[union_index])) do return INVALID
		}
	}

	query_index := grid_search(input, union_start, union_points, query_raw)
	macro: [5]f64 = {}
	query := decode(query_raw)
	for item in 0..<material_nuclides {
		nuclide := composition_ids[item]
		pointer := int(input[pointer_start+query_index*nuclides+nuclide])
		low_index := if pointer == gridpoints-1 do pointer-1 else do pointer
		low_record := grid_start+(nuclide*gridpoints+low_index)*RECORD_SIZE
		high_record := low_record+RECORD_SIZE
		low_energy, high_energy := decode(input[low_record]), decode(input[high_record])
		factor := (high_energy-query)/(high_energy-low_energy)
		for channel in 0..<5 {
			low_xs, high_xs := decode(input[low_record+channel+1]), decode(input[high_record+channel+1])
			microscopic := high_xs-factor*(high_xs-low_xs)
			macro[channel] += microscopic*concentrations[item]
		}
	}
	return macro[0]+2.0*macro[1]+3.0*macro[2]+5.0*macro[3]+7.0*macro[4]
}
