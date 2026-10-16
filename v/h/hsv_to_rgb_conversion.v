module hsv_to_rgb_conversion

fn section_remainder_two(section f64) f64 {
	if section < 2.0 { return section }
	if section < 4.0 { return section - 2.0 }
	if section < 6.0 { return section - 4.0 }
	return section - 6.0
}

@[export: 'hsv_to_rgb_conversion']
pub fn hsv_to_rgb_conversion(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length != 3 { return -1 }
		if input[0] < 0 || input[0] > 360000 || input[1] < 0 || input[1] > 255000000 ||
			input[2] < 0 || input[2] > 255000000 { return -1 }
		if output == nil || capacity < 3 { return -2 }

		hue := f64(input[0]) / 1000.0
		saturation := f64(input[1]) / 255000000.0
		value := f64(input[2]) / 255000000.0
		chroma := value * saturation
		hue_section := hue / 60.0
		remainder := section_remainder_two(hue_section)
		delta := remainder - 1.0
		absolute_delta := delta
		if delta < 0.0 { absolute_delta = -delta }
		second := chroma * (1.0 - absolute_delta)
		matched := value - chroma
		mut red := 0.0
		mut green := 0.0
		mut blue := 0.0
		if hue_section >= 0.0 && hue_section <= 1.0 {
			red=chroma+matched; green=second+matched; blue=matched
		} else if hue_section > 1.0 && hue_section <= 2.0 {
			red=second+matched; green=chroma+matched; blue=matched
		} else if hue_section > 2.0 && hue_section <= 3.0 {
			red=matched; green=chroma+matched; blue=second+matched
		} else if hue_section > 3.0 && hue_section <= 4.0 {
			red=matched; green=second+matched; blue=chroma+matched
		} else if hue_section > 4.0 && hue_section <= 5.0 {
			red=second+matched; green=matched; blue=chroma+matched
		} else {
			red=chroma+matched; green=matched; blue=second+matched
		}
		output[0] = u8(int(255.0*red+0.5))
		output[1] = u8(int(255.0*green+0.5))
		output[2] = u8(int(255.0*blue+0.5))
		return 3
	}
}
