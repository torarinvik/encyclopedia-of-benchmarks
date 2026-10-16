package bilateral_filter

import "core:c"
import "core:math"

MAX_SIDE :: 32
MAX_PIXELS :: MAX_SIDE * MAX_SIDE

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0..<8 do output[offset+byte] = u8((bits >> u32(8*byte)) & 0xff)
}

@(export)
bilateral_filter :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 5 || length > 5+MAX_PIXELS do return -1
	height_value, width_value, kernel_value := values[0], values[1], values[2]
	spatial_q, intensity_q := values[3], values[4]
	if height_value < 1 || height_value > MAX_SIDE || width_value < 1 || width_value > MAX_SIDE ||
		(kernel_value != 1 && kernel_value != 3 && kernel_value != 5 && kernel_value != 7) ||
		spatial_q < 1 || spatial_q > 1_000_000 || intensity_q < 1 || intensity_q > 1_000_000 {
		return -1
	}
	height, width := int(height_value), int(width_value)
	pixels := height*width
	if int(length) != 5+pixels do return -1
	for index in 0..<pixels {
		if values[5+index] < 0 || values[5+index] > 1_000_000 do return -1
	}
	required := pixels*8
	if output == nil || output_capacity < c.size_t(required) do return -2

	kernel_size, radius := int(kernel_value), int(kernel_value/2)
	spatial_variance := f64(spatial_q)/1_000_000.0
	intensity_variance := f64(intensity_q)/1_000_000.0
	filtered: [MAX_PIXELS]i64 = {}
	if height >= kernel_size && width >= kernel_size {
		for row in radius..<height-radius {
			for column in radius..<width-radius {
				center := f64(values[5+row*width+column])/1_000_000.0
				weighted_sum, weight_sum: f64 = 0.0, 0.0
				for dy in -radius..=radius {
					for dx in -radius..=radius {
						sample := f64(values[5+(row+dy)*width+column+dx])/1_000_000.0
						distance_squared := f64(dx*dx+dy*dy)
						difference := sample-center
						weight := math.exp(-distance_squared/(2.0*spatial_variance))*math.exp(-(difference*difference)/(2.0*intensity_variance))
						weighted_sum += sample*weight
						weight_sum += weight
					}
				}
				filtered[row*width+column] = i64(weighted_sum/weight_sum*1_000_000.0+0.5)
			}
		}
	}
	for index in 0..<pixels do write_i64_le(output, index*8, filtered[index])
	return i64(required)
}
