package freebench_fbench

import "core:c"
import "core:math"

// John Walker's Floating Point Benchmark, derived from the Marinchip
// Interactive Lens Design System (December 1980). Pinned origin:
// lac-dcc/Benchmarks/Misc/fbench/fbench.c at 5d7b75df749241efa7a6e6f5be613d3fcc5cce38.
// The source permits use, distribution, and modification if origin information is preserved.
MAX_PASSES :: 16
INVALID_RESULT :: -1.0e300
SPECTRAL_LINE := [9]f64{0.0, 7621.0, 6869.955, 6562.816, 5895.944, 5269.557, 4861.344, 4340.477, 3968.494}
LENS := [4][4]f64{
	{27.05, 1.5137, 63.6, 0.52},
	{-16.68, 1.0, 0.0, 0.138},
	{-16.68, 1.6164, 36.7, 0.38},
	{-78.1, 1.0, 0.0, 0.0},
}

Ray_State :: struct { object_distance: f64, axis_slope_angle: f64 }

trace_line :: proc "contextless" (line: int, initial_height: f64, paraxial: bool) -> Ray_State {
	object_distance := 0.0
	ray_height := initial_height
	axis_slope_angle := 0.0
	from_index := 1.0
	for surface := 0; surface < 4; surface += 1 {
		radius := LENS[surface][0]
		nominal_index := LENS[surface][1]
		abbe_number := LENS[surface][2]
		thickness := LENS[surface][3]
		to_index := nominal_index
		if to_index > 1.0 {
			to_index += ((SPECTRAL_LINE[4] - SPECTRAL_LINE[line])
				/ (SPECTRAL_LINE[3] - SPECTRAL_LINE[6]))
				* ((nominal_index - 1.0) / abbe_number)
		}
		if paraxial {
			if radius != 0.0 {
				incidence_sine: f64
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
			incidence_sine: f64
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
			sagitta := math.sin((old_axis_slope_angle + incidence_angle) / 2.0)
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
	return Ray_State{object_distance, axis_slope_angle}
}

one_pass_projection :: proc "contextless" (ray_height: f64) -> f64 {
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

@(export)
freebench_fbench :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 1 || values[0] < 1 || values[0] > MAX_PASSES do return INVALID_RESULT
	total := 0.0
	for pass := 0; pass < int(values[0]); pass += 1 {
		ray_height := 2.0 + 0.0002 * f64(pass)
		total += one_pass_projection(ray_height)
	}
	return total
}
