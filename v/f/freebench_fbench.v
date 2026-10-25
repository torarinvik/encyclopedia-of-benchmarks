// John Walker's Floating Point Benchmark, derived from the Marinchip
// Interactive Lens Design System (December 1980). Pinned origin:
// lac-dcc/Benchmarks/Misc/fbench/fbench.c at 5d7b75df749241efa7a6e6f5be613d3fcc5cce38.
// The source permits use, distribution, and modification when origin information is preserved.
module freebench_fbench

import math

const max_passes = i64(16)
const invalid_result = -1.0e300
const spectral_line = [9]f64{0.0, 7621.0, 6869.955, 6562.816, 5895.944, 5269.557, 4861.344, 4340.477, 3968.494}
const lens = [16]f64{27.05, 1.5137, 63.6, 0.52, -16.68, 1.0, 0.0, 0.138, -16.68, 1.6164, 36.7, 0.38, -78.1, 1.0, 0.0, 0.0}

struct RayState {
	object_distance f64
	axis_slope_angle f64
}

fn trace_line(line int, initial_height f64, paraxial bool) RayState {
	mut object_distance := 0.0
	mut ray_height := initial_height
	mut axis_slope_angle := 0.0
	mut from_index := 1.0
	for surface in 0 .. 4 {
		radius := lens[surface * 4]
		nominal_index := lens[surface * 4 + 1]
		abbe_number := lens[surface * 4 + 2]
		thickness := lens[surface * 4 + 3]
		mut to_index := nominal_index
		if to_index > 1.0 {
			to_index += ((spectral_line[4] - spectral_line[line])
				/ (spectral_line[3] - spectral_line[6]))
				* ((nominal_index - 1.0) / abbe_number)
		}
		if paraxial {
			if radius != 0.0 {
				mut incidence_sine := 0.0
				if object_distance == 0.0 {
					axis_slope_angle = 0.0
					incidence_sine = ray_height / radius
				} else {
					incidence_sine = ((object_distance - radius) / radius) * axis_slope_angle
				}
				refraction_sine := (from_index / to_index) * incidence_sine
				old_axis_slope_angle := axis_slope_angle
				axis_slope_angle = axis_slope_angle + incidence_sine - refraction_sine
				if object_distance != 0.0 { ray_height = object_distance * old_axis_slope_angle }
				object_distance = ray_height / axis_slope_angle
			} else {
				object_distance = object_distance * (to_index / from_index)
				axis_slope_angle = axis_slope_angle * (from_index / to_index)
			}
		} else if radius != 0.0 {
			mut incidence_sine := 0.0
			if object_distance == 0.0 {
				axis_slope_angle = 0.0
				incidence_sine = ray_height / radius
			} else {
				incidence_sine = ((object_distance - radius) / radius) * math.sin(axis_slope_angle)
			}
			incidence_angle := math.asin(incidence_sine)
			refraction_sine := (from_index / to_index) * incidence_sine
			old_axis_slope_angle := axis_slope_angle
			axis_slope_angle = axis_slope_angle + incidence_angle - math.asin(refraction_sine)
			mut sagitta := math.sin((old_axis_slope_angle + incidence_angle) / 2.0)
			sagitta = 2.0 * radius * sagitta * sagitta
			object_distance = (radius * math.sin(old_axis_slope_angle + incidence_angle))
				* (1.0 / math.tan(axis_slope_angle)) + sagitta
		} else {
			refraction_angle := -math.asin((from_index / to_index) * math.sin(axis_slope_angle))
			object_distance = object_distance * ((to_index * math.cos(-refraction_angle))
				/ (from_index * math.cos(axis_slope_angle)))
			axis_slope_angle = -refraction_angle
		}
		from_index = to_index
		if surface < 3 { object_distance = object_distance - thickness }
	}
	return RayState{object_distance: object_distance, axis_slope_angle: axis_slope_angle}
}

fn one_pass_projection(ray_height f64) f64 {
	marginal_d := trace_line(4, ray_height, false)
	paraxial_d := trace_line(4, ray_height, true)
	marginal_c := trace_line(3, ray_height, false).object_distance
	marginal_f := trace_line(6, ray_height, false).object_distance
	spherical_aberration := paraxial_d.object_distance - marginal_d.object_distance
	sine_condition_aberration := 1.0 - (paraxial_d.object_distance * paraxial_d.axis_slope_angle)
		/ (math.sin(marginal_d.axis_slope_angle) * marginal_d.object_distance)
	chromatic_aberration := marginal_f - marginal_c
	return spherical_aberration + sine_condition_aberration + chromatic_aberration
}

@[export: 'freebench_fbench']
pub fn freebench_fbench(values &i64, length usize) f64 {
	unsafe {
		if values == nil || length != 1 || values[0] < 1 || values[0] > max_passes { return invalid_result }
		mut total := 0.0
		for pass in 0 .. int(values[0]) {
			ray_height := 2.0 + 0.0002 * f64(pass)
			total += one_pass_projection(ray_height)
		}
		return total
	}
}
