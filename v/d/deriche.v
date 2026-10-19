module deriche

import math

const max_width = 32
const max_height = 32
const max_pixels = max_width * max_height
const invalid_result = -1.0e300

fn filter_once(width int, height int, image []f32, mut output []f32, mut y1 []f32, mut y2 []f32) {
	alpha := f32(0.25)
	exp_neg_alpha := f32(math.exp(-f64(alpha)))
	difference := f32(1.0) - exp_neg_alpha
	numerator := difference * difference
	denominator_left := f32(1.0) + f32(2.0) * alpha * exp_neg_alpha
	k := numerator / (denominator_left - f32(math.exp(2.0 * f64(alpha))))
	a1 := k
	a2 := k * exp_neg_alpha * (alpha - f32(1.0))
	a3 := k * exp_neg_alpha * (alpha + f32(1.0))
	a4 := -k * f32(math.exp(-2.0 * f64(alpha)))
	a5, a6, a7, a8 := k, a2, a3, a4
	b1 := f32(math.pow(2.0, -f64(alpha)))
	b2 := -f32(math.exp(-2.0 * f64(alpha)))
	for i in 0 .. width {
		mut ym1 := f32(0); mut ym2 := f32(0); mut xm1 := f32(0)
		for j in 0 .. height {
			at := i * height + j
			mut value := a1 * image[at] + a2 * xm1
			value = value + b1 * ym1; value = value + b2 * ym2; y1[at] = value
			xm1 = image[at]; ym2 = ym1; ym1 = value
		}
	}
	for i in 0 .. width {
		mut yp1 := f32(0); mut yp2 := f32(0); mut xp1 := f32(0); mut xp2 := f32(0)
		mut j := height
		for j > 0 {
			j--; at := i * height + j
			mut value := a3 * xp1 + a4 * xp2
			value = value + b1 * yp1; value = value + b2 * yp2; y2[at] = value
			xp2 = xp1; xp1 = image[at]; yp2 = yp1; yp1 = value
		}
	}
	for i in 0 .. width { for j in 0 .. height {
		at := i * height + j; output[at] = f32(1) * (y1[at] + y2[at])
	}}
	for j in 0 .. height {
		mut tm1 := f32(0); mut ym1 := f32(0); mut ym2 := f32(0)
		for i in 0 .. width {
			at := i * height + j
			mut value := a5 * output[at] + a6 * tm1
			value = value + b1 * ym1; value = value + b2 * ym2; y1[at] = value
			tm1 = output[at]; ym2 = ym1; ym1 = value
		}
	}
	for j in 0 .. height {
		mut tp1 := f32(0); mut tp2 := f32(0); mut yp1 := f32(0); mut yp2 := f32(0)
		mut i := width
		for i > 0 {
			i--; at := i * height + j
			mut value := a7 * tp1 + a8 * tp2
			value = value + b1 * yp1; value = value + b2 * yp2; y2[at] = value
			tp2 = tp1; tp1 = output[at]; yp2 = yp1; yp1 = value
		}
	}
	for at in 0 .. width * height { output[at] = f32(1) * (y1[at] + y2[at]) }
}

@[export: 'deriche']
pub fn deriche(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 3 { return invalid_result }
	unsafe {
		if values[0] < 1 || values[0] > max_width || values[1] < 1 || values[1] > max_height || values[2] < 1 || values[2] > 4 { return invalid_result }
		width, height := int(values[0]), int(values[1])
		mut image := []f32{len: max_pixels, init: 0.0}
		mut output := []f32{len: max_pixels, init: 0.0}
		mut y1 := []f32{len: max_pixels, init: 0.0}
		mut y2 := []f32{len: max_pixels, init: 0.0}
		for i in 0 .. width { for j in 0 .. height {
			image[i * height + j] = f32((313 * i + 991 * j) % 65536) / f32(65535)
		}}
		for _ in 0 .. int(values[2]) {
			filter_once(width, height, image, mut output, mut y1, mut y2)
			for at in 0 .. width * height { image[at] = output[at] }
		}
		mut checksum := 0.0
		for at in 0 .. width * height { checksum += f64(output[at]) }
		return checksum
	}
}
