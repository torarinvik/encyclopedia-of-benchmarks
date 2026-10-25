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

const invalid_result: f64 = -1.0e300;
const max_nuclides: usize = 4;
const min_gridpoints: usize = 2;
const max_gridpoints: usize = 5;
const max_union_points: usize = max_nuclides * max_gridpoints;
const max_length: usize = 232;
const record_size: usize = 6;

fn decode(raw: i64) f64 {
	return @as(f64, @floatFromInt(raw)) / 1_000_000.0;
}

fn binarySearch(
	energies: *const [max_nuclides * max_gridpoints]i64,
	nuclide: usize,
	gridpoints: usize,
	quarry: i64,
) i64 {
	var minimum: i64 = 0;
	var maximum: i64 = @as(i64, @intCast(gridpoints)) - 1;
	const first = energies[nuclide * max_gridpoints];
	const last = energies[nuclide * max_gridpoints + gridpoints - 1];
	if (first > quarry) return 0;
	if (last < quarry) return @as(i64, @intCast(gridpoints)) - 2;
	while (maximum >= minimum) {
		const middle = minimum + @divTrunc(maximum - minimum, 2);
		const energy = energies[nuclide * max_gridpoints + @as(usize, @intCast(middle))];
		if (energy < quarry) {
			minimum = middle + 1;
		} else if (energy > quarry) {
			maximum = middle - 1;
		} else {
			return middle;
		}
	}
	return maximum;
}

fn gridSearch(grid: *const [max_union_points]i64, count: usize, quarry: i64) usize {
	var lower: usize = 0;
	var upper = count - 1;
	var span = upper - lower;
	while (span > 1) {
		const middle = lower + span / 2;
		if (grid[middle] > quarry) {
			upper = middle;
		} else {
			lower = middle;
		}
		span = upper - lower;
	}
	return lower;
}

pub export fn doe_xsbench_unionized_macro_xs(input: [*c]const i64, length: usize) f64 {
	if (input == null or length < 22 or length > max_length) return invalid_result;
	const nuclides_raw = input[0];
	const gridpoints_raw = input[1];
	const material_nuclides_raw = input[2];
	const query_raw = input[3];
	if (nuclides_raw < 1 or nuclides_raw > @as(i64, @intCast(max_nuclides)) or
		gridpoints_raw < @as(i64, @intCast(min_gridpoints)) or
		gridpoints_raw > @as(i64, @intCast(max_gridpoints)) or
		material_nuclides_raw < 1 or material_nuclides_raw > nuclides_raw or
		query_raw < 0 or query_raw > 1_000_000) return invalid_result;
	const nuclides: usize = @intCast(nuclides_raw);
	const gridpoints: usize = @intCast(gridpoints_raw);
	const material_nuclides: usize = @intCast(material_nuclides_raw);
	const union_points = nuclides * gridpoints;
	const composition_start: usize = 4;
	const union_start = composition_start + 2 * material_nuclides;
	const pointer_start = union_start + union_points;
	const grid_start = pointer_start + union_points * nuclides;
	if (length != grid_start + union_points * record_size) return invalid_result;

	var composition_ids: [max_nuclides]usize = @splat(0);
	var concentrations: [max_nuclides]f64 = @splat(0.0);
	var used: [max_nuclides]bool = @splat(false);
	for (0..material_nuclides) |item| {
		const id_raw = input[composition_start + 2 * item];
		const concentration_raw = input[composition_start + 2 * item + 1];
		if (id_raw < 0 or id_raw >= nuclides_raw or concentration_raw < 0 or concentration_raw > 1_000_000)
			return invalid_result;
		const id: usize = @intCast(id_raw);
		if (used[id]) return invalid_result;
		used[id] = true;
		composition_ids[item] = id;
		concentrations[item] = decode(concentration_raw);
	}

	var union_grid: [max_union_points]i64 = @splat(0);
	for (0..union_points) |index| {
		const energy = input[union_start + index];
		if (energy < 0 or energy > 1_000_000 or (index > 0 and energy <= union_grid[index - 1]))
			return invalid_result;
		union_grid[index] = energy;
	}

	var nuclide_energies: [max_nuclides * max_gridpoints]i64 = @splat(0);
	for (0..nuclides) |nuclide| {
		for (0..gridpoints) |point| {
			const record = grid_start + (nuclide * gridpoints + point) * record_size;
			const energy = input[record];
			if (energy < 0 or energy > 1_000_000 or
				(point > 0 and energy <= nuclide_energies[nuclide * max_gridpoints + point - 1]))
				return invalid_result;
			nuclide_energies[nuclide * max_gridpoints + point] = energy;
			for (1..record_size) |channel| {
				const field = input[record + channel];
				if (field < 0 or field > 1_000_000) return invalid_result;
			}
		}
	}

	for (0..union_points) |union_index| {
		var matches: usize = 0;
		for (0..nuclides) |nuclide| {
			for (0..gridpoints) |point| {
				if (nuclide_energies[nuclide * max_gridpoints + point] == union_grid[union_index])
					matches += 1;
			}
		}
		if (matches != 1) return invalid_result;
		for (0..nuclides) |nuclide| {
			const pointer = input[pointer_start + union_index * nuclides + nuclide];
			const expected = binarySearch(&nuclide_energies, nuclide, gridpoints, union_grid[union_index]);
			if (pointer != expected) return invalid_result;
		}
	}

	const query_index = gridSearch(&union_grid, union_points, query_raw);
	var macro: [5]f64 = @splat(0.0);
	const query = decode(query_raw);
	for (0..material_nuclides) |item| {
		const nuclide = composition_ids[item];
		const pointer: usize = @intCast(input[pointer_start + query_index * nuclides + nuclide]);
		const low_index = if (pointer == gridpoints - 1) pointer - 1 else pointer;
		const low_record = grid_start + (nuclide * gridpoints + low_index) * record_size;
		const high_record = low_record + record_size;
		const low_energy = decode(input[low_record]);
		const high_energy = decode(input[high_record]);
		const factor = (high_energy - query) / (high_energy - low_energy);
		for (0..5) |channel| {
			const low_xs = decode(input[low_record + channel + 1]);
			const high_xs = decode(input[high_record + channel + 1]);
			const microscopic = high_xs - factor * (high_xs - low_xs);
			macro[channel] += microscopic * concentrations[item];
		}
	}
	return macro[0] + 2.0 * macro[1] + 3.0 * macro[2] + 5.0 * macro[3] + 7.0 * macro[4];
}
