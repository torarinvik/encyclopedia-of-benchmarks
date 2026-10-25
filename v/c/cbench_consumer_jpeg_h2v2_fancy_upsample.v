// Independently written bounded IJG h2v2 adaptation; see package README/LICENSE.
module main

const max_width = 16
const max_height = 8
const max_output = 512

@[export: 'cbench_consumer_jpeg_h2v2_fancy_upsample']
pub fn cbench_consumer_jpeg_h2v2_fancy_upsample(input &i64, input_length usize,
    output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 5 || input_length > 131 { return -1 }
	width_value := unsafe { input[0] }
	height_value := unsafe { input[1] }
	if width_value < 3 || width_value > max_width || height_value < 1 || height_value > max_height { return -1 }
	width := int(width_value)
	height := int(height_value)
	pixels := width * height
	if input_length != usize(2 + pixels) { return -1 }
	for i in 0 .. pixels {
		value := unsafe { input[i + 2] }
		if value < 0 || value > 255 { return -1 }
	}
	output_size := 4 * pixels
	if unsafe { output == nil } || output_capacity < usize(output_size) { return -2 }
	mut staged := [max_output]u8{}
	mut p := 0
	for y in 0 .. height {
		for v in 0 .. 2 {
			far_y := if v == 0 { if y == 0 { 0 } else { y - 1 } } else { if y + 1 == height { y } else { y + 1 } }
			mut sums := [max_width]int{}
			for x in 0 .. width {
				sums[x] = 3 * int(unsafe { input[2 + y * width + x] }) + int(unsafe { input[2 + far_y * width + x] })
			}
			staged[p] = u8((sums[0] * 4 + 8) >> 4); p++
			staged[p] = u8((sums[0] * 3 + sums[1] + 7) >> 4); p++
			for x in 1 .. width - 1 {
				staged[p] = u8((sums[x] * 3 + sums[x - 1] + 8) >> 4); p++
				staged[p] = u8((sums[x] * 3 + sums[x + 1] + 7) >> 4); p++
			}
			staged[p] = u8((sums[width - 1] * 3 + sums[width - 2] + 8) >> 4); p++
			staged[p] = u8((sums[width - 1] * 4 + 7) >> 4); p++
		}
	}
	for i in 0 .. output_size { unsafe { output[i] = staged[i] } }
	return i64(output_size)
}
