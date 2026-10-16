module ema_filter

import math

fn put_f64_le(mut output &u8, offset usize, value f64) {
	bits := math.bits_from_f64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits >> (8 * byte)) } }
}

// Apply the bounded Java EMAFilter recurrence to an integer sample stream.
@[export: 'ema_filter']
pub fn ema_filter(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 7 { return -1 }
	unsafe {
		alpha_units, count_value := input[0], input[1]
		if alpha_units < 1 || alpha_units > 1024 || count_value < 0 || count_value > 4 || length != usize(2 + count_value) { return -1 }
		count := int(count_value)
		for index in 0 .. count {
			if input[index + 2] < -1_000_000 || input[index + 2] > 1_000_000 { return -1 }
		}
		required := usize(count * 8)
		if output_capacity < required || (required > 0 && output == nil) { return -2 }
		alpha := f64(alpha_units) / 1024.0
		mut ema_value := f64(0)
		for index in 0 .. count {
			sample := f64(input[index + 2])
			if index == 0 { ema_value = sample }
			else { ema_value = alpha * sample + (1.0 - alpha) * ema_value }
			put_f64_le(mut output, usize(index * 8), ema_value)
		}
		return i64(required)
	}
}
