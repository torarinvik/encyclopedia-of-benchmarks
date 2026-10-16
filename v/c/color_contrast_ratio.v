module color_contrast_ratio

const invalid_result = -1.0e300

fn component(channel i64) f64 {
	srgb := f64(channel) / 255.0
	if srgb <= 0.03928 { return srgb / 12.92 }
	return math.pow((srgb + 0.055) / 1.055, 2.4)
}

fn luminance(red i64, green i64, blue i64) f64 {
	return 0.2126 * component(red) + 0.7152 * component(green) + 0.0722 * component(blue)
}

@[export: 'color_contrast_ratio']
pub fn color_contrast_ratio(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 6 { return invalid_result }
	for i in 0 .. 6 {
		channel := unsafe { values[i] }
		if channel < 0 || channel > 255 { return invalid_result }
	}
	first := luminance(unsafe { values[0] }, unsafe { values[1] }, unsafe { values[2] })
	second := luminance(unsafe { values[3] }, unsafe { values[4] }, unsafe { values[5] })
	if first > second { return (first + 0.05) / (second + 0.05) }
	return (second + 0.05) / (first + 0.05)
}
