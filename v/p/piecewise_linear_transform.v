module piecewise_linear_transform

@[export: 'piecewise_linear_transform']
pub fn piecewise_linear_transform(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 256 { return -1 }
	unsafe {
		for index := 0; index < int(length); index++ {
			if input[index] < 0 || input[index] > 255 { return -1 }
		}
		if output == nil || capacity < length { return -2 }
		for index := 0; index < int(length); index++ {
			pixel := f64(input[index])
			mapped := if pixel <= 100.0 {
				(50.0 / 100.0) * pixel
			} else if pixel <= 180.0 {
				((200.0 - 50.0) / (180.0 - 100.0)) * (pixel - 100.0) + 50.0
			} else {
				((255.0 - 200.0) / (255.0 - 180.0)) * (pixel - 180.0) + 200.0
			}
			output[index] = u8(mapped)
		}
		return i64(length)
	}
}
