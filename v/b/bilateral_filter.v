module bilateral_filter

import math

const max_side = 32
const max_pixels = max_side * max_side

fn write_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 0xff) }
	}
}

fn bilateral_pixel(values &i64, width int, row int, column int, radius int,
	spatial_variance f64, intensity_variance f64) i64 {
	center := f64(unsafe { values[5+row*width+column] }) / 1_000_000.0
	mut weighted_sum := f64(0)
	mut weight_sum := f64(0)
	for dy in -radius .. radius+1 {
		for dx in -radius .. radius+1 {
			sample := f64(unsafe { values[5+(row+dy)*width+column+dx] }) / 1_000_000.0
			distance_squared := f64(dx*dx+dy*dy)
			difference := sample-center
			mut weight := math.exp(-distance_squared/(2.0*spatial_variance))
			weight *= math.exp(-(difference*difference)/(2.0*intensity_variance))
			weighted_sum += sample*weight
			weight_sum += weight
		}
	}
	return i64(weighted_sum/weight_sum*1_000_000.0+0.5)
}

@[export: 'bilateral_filter']
pub fn bilateral_filter(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 5 || length > 5+max_pixels { return -1 }
	height_value := unsafe { values[0] }
	width_value := unsafe { values[1] }
	kernel_value := unsafe { values[2] }
	spatial_q := unsafe { values[3] }
	intensity_q := unsafe { values[4] }
	if height_value < 1 || height_value > max_side || width_value < 1 || width_value > max_side ||
		(kernel_value != 1 && kernel_value != 3 && kernel_value != 5 && kernel_value != 7) ||
		spatial_q < 1 || spatial_q > 1_000_000 || intensity_q < 1 || intensity_q > 1_000_000 { return -1 }
	height, width := int(height_value), int(width_value)
	pixels := height*width
	if int(length) != 5+pixels { return -1 }
	for index in 0 .. pixels {
		value := unsafe { values[5+index] }
		if value < 0 || value > 1_000_000 { return -1 }
	}
	required := pixels*8
	if unsafe { output == nil } || output_capacity < usize(required) { return -2 }
	mut filtered := [max_pixels]i64{}
	kernel_size, radius := int(kernel_value), int(kernel_value/2)
	if height >= kernel_size && width >= kernel_size {
		spatial_variance := f64(spatial_q)/1_000_000.0
		intensity_variance := f64(intensity_q)/1_000_000.0
		for row in radius .. height-radius {
			for column in radius .. width-radius {
				filtered[row*width+column] = bilateral_pixel(values, width, row, column, radius,
					spatial_variance, intensity_variance)
			}
		}
	}
	for index in 0 .. pixels { write_i64_le(mut output, index*8, filtered[index]) }
	return i64(required)
}
