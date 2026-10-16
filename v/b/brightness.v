module brightness

@[export: 'brightness']
pub fn brightness(input &i64, length usize) i64 {
	if length != 3 { return -1 }
	red := unsafe { input[0] }
	green := unsafe { input[1] }
	blue := unsafe { input[2] }
	if red < 0 || red > 255 || green < 0 || green > 255 || blue < 0 || blue > 255 {
		return -1
	}

	mut training := [44]i64{}
	training[0], training[1], training[2], training[3] = 2, 99, 255, 1
	training[4], training[5], training[6], training[7] = 37, 44, 58, 0
	training[8], training[9], training[10], training[11] = 139, 169, 229, 1
	training[12], training[13], training[14], training[15] = 14, 255, 10, 1
	training[16], training[17], training[18], training[19] = 2, 28, 1, 0
	training[20], training[21], training[22], training[23] = 20, 33, 20, 0
	training[24], training[25], training[26], training[27] = 252, 227, 65, 1
	training[28], training[29], training[30], training[31] = 71, 65, 24, 0
	training[32], training[33], training[34], training[35] = 168, 80, 80, 1
	training[36], training[37], training[38], training[39] = 119, 35, 90, 0
	training[40], training[41], training[42], training[43] = 186, 13, 126, 1
	mut best_distance := i64(195076)
	mut best_label := i64(-1)
	for sample in 0 .. 11 {
		red_delta := red - training[sample * 4]
		green_delta := green - training[sample * 4 + 1]
		blue_delta := blue - training[sample * 4 + 2]
		distance := red_delta * red_delta + green_delta * green_delta + blue_delta * blue_delta
		if distance < best_distance {
			best_distance = distance
			best_label = training[sample * 4 + 3]
		}
	}
	return best_label
}
