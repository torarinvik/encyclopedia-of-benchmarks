import math

#include <math.h>
fn C.hypot(x f64, y f64) f64

const max_points = 12
const max_output = 25

@[export: 'ramer_douglas_peucker']
pub fn ramer_douglas_peucker(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > 26 { return -1 }
		if input[0] != input[0] || input[0] < 0.0 || input[0] > 12.0 || math.floor(input[0]) != input[0] { return -1 }
		n := int(input[0])
		epsilon := input[1]
		if input_length != usize(2 + 2*n) || epsilon != epsilon || epsilon < 0.0 || epsilon > 100.0 { return -1 }
		mut xs := [max_points]f64{}
		mut ys := [max_points]f64{}
		for i in 0 .. n {
			xs[i] = input[2 + 2*i]
			ys[i] = input[3 + 2*i]
			if xs[i] != xs[i] || ys[i] != ys[i] || math.abs(xs[i]) > 100.0 || math.abs(ys[i]) > 100.0 { return -1 }
		}
		if n >= 3 {
			for i in 0 .. n {
				for j in i + 1 .. n {
					if xs[i] == xs[j] && ys[i] == ys[j] { return -1 }
					dx := xs[j] - xs[i]
					dy := ys[j] - ys[i]
					length_squared := dx*dx + dy*dy
					line_length := math.sqrt(length_squared)
					if length_squared != length_squared || length_squared <= 0.0 || line_length != line_length || line_length <= 0.0 { return -1 }
					mut max_clamped := 0.0
					mut max_line := 0.0
					mut index_clamped := i
					mut index_line := i
					for k in i + 1 .. j {
						px := xs[k]
						py := ys[k]
						t := ((px-xs[i])*dx + (py-ys[i])*dy) / length_squared
						if t < 0.0 || t > 1.0 { return -1 }
						nearest_x := xs[i] + t*dx
						nearest_y := ys[i] + t*dy
						ddx := px - nearest_x
						ddy := py - nearest_y
						clamped_distance := C.hypot(ddx, ddy)
						numerator := dy*px - dx*py + xs[j]*ys[i] - ys[j]*xs[i]
						line_distance := math.abs(numerator) / line_length
						if clamped_distance != clamped_distance || line_distance != line_distance { return -1 }
						if clamped_distance > max_clamped { max_clamped = clamped_distance; index_clamped = k }
						if line_distance > max_line { max_line = line_distance; index_line = k }
					}
					if index_clamped != index_line || (max_clamped > epsilon) != (max_line > epsilon) { return -1 }
				}
			}
		}
		mut keep := [max_points]bool{}
		if n > 0 { keep[0] = true }
		if n > 1 { keep[n-1] = true }
		if n >= 3 {
			mut starts := [24]int{}
			mut finishes := [24]int{}
			mut top := 1
			starts[0] = 0
			finishes[0] = n-1
			for top > 0 {
				top--
				start := starts[top]
				finish := finishes[top]
				dx := xs[finish] - xs[start]
				dy := ys[finish] - ys[start]
				length_squared := dx*dx + dy*dy
				mut max_distance := 0.0
				mut max_index := start
				for k in start + 1 .. finish {
					t := ((xs[k]-xs[start])*dx + (ys[k]-ys[start])*dy) / length_squared
					nearest_x := xs[start] + t*dx
					nearest_y := ys[start] + t*dy
					ddx := xs[k] - nearest_x
					ddy := ys[k] - nearest_y
					distance := C.hypot(ddx, ddy)
					if distance > max_distance { max_distance = distance; max_index = k }
				}
				if max_distance > epsilon {
					keep[max_index] = true
					starts[top] = start
					finishes[top] = max_index
					top++
					starts[top] = max_index
					finishes[top] = finish
					top++
				}
			}
		}
		mut staged := [max_output]f64{}
		mut result_count := 0
		for i in 0 .. n {
			if keep[i] {
				staged[1+2*result_count] = xs[i]
				staged[2+2*result_count] = ys[i]
				result_count++
			}
		}
		staged[0] = f64(result_count)
		output_size := 1 + 2*result_count
		if output == nil || capacity < usize(output_size) { return -2 }
		for i in 0 .. output_size { output[i] = staged[i] }
		return i64(output_size)
	}
}
