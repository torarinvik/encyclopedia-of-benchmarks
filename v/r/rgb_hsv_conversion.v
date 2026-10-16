module main
import math

fn write_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for i in 0 .. 8 {
		unsafe { output[offset + i] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'rgb_hsv_conversion']
pub fn rgb_hsv_conversion(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		for i in 0 .. 3 { if input[i] < 0 || input[i] > 255 { return -1 } }
		if output == nil || capacity < 24 { return -2 }
		red := f64(input[0]) / 255.0
		green := f64(input[1]) / 255.0
		blue := f64(input[2]) / 255.0
		value := max(max(red, green), blue)
		chroma := value - min(min(red, green), blue)
		saturation := if value == 0.0 { 0.0 } else { chroma / value }
		mut hue := 0.0
		if chroma != 0.0 {
			if value == red { hue = 60.0 * (0.0 + (green - blue) / chroma) }
			else if value == green { hue = 60.0 * (2.0 + (blue - red) / chroma) }
			else { hue = 60.0 * (4.0 + (red - green) / chroma) }
		}
		hue += 360.0
		if hue >= 360.0 { hue -= 360.0 }
		write_f64_le(mut output, 0, hue)
		write_f64_le(mut output, 8, saturation)
		write_f64_le(mut output, 16, value)
		return 24
	}
}
