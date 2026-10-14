module area

const max_operations = 256

fn integer_sqrt(value i64) i64 {
	mut low := i64(0)
	mut high := i64(3_037_000_499)
	mut answer := i64(0)
	for low <= high {
		middle := low + (high - low) / 2
		if middle == 0 || middle <= value / middle {
			answer = middle
			low = middle + 1
		} else {
			high = middle - 1
		}
	}
	return answer
}

fn scale_pi(value i64) i64 {
	return value * 3 + value * 141_592_654 / 1_000_000_000
}

fn scale_pi_squared(value i64) i64 {
	return value * 9 + value * 869_604_401 / 1_000_000_000
}

fn area_heron_milli(a i64, b i64, c i64) i64 {
	perimeter := a + b + c
	if a + b < c || a + c < b || b + c < a { return -1 }
	rad := perimeter * (perimeter - 2 * a) * (perimeter - 2 * b) * (perimeter - 2 * c)
	return integer_sqrt(rad * 1_000_000) / 4
}

fn regular_polygon_coefficient(sides i64) i64 {
	return match sides {
		3 { 433_012_701 }
		4 { 1_000_000_000 }
		5 { 1_720_477_400 }
		6 { 2_598_076_211 }
		7 { 3_633_912_444 }
		8 { 4_828_427_124 }
		9 { 6_181_824_193 }
		10 { 7_694_208_842 }
		11 { 9_365_639_906 }
		12 { 11_196_152_422 }
		13 { 13_185_768_328 }
		14 { 15_334_501_936 }
		15 { 17_642_362_910 }
		16 { 20_109_357_968 }
		17 { 22_735_491_898 }
		18 { 25_520_768_188 }
		19 { 28_465_189_427 }
		20 { 31_568_757_573 }
		21 { 34_831_474_123 }
		22 { 38_253_340_244 }
		23 { 41_834_356_852 }
		24 { 45_574_524_676 }
		25 { 49_473_844_301 }
		26 { 53_532_316_204 }
		27 { 57_749_940_771 }
		28 { 62_126_718_324 }
		29 { 66_662_649_129 }
		30 { 71_357_733_406 }
		31 { 76_211_971_344 }
		32 { 81_225_363_100 }
		else { -1 }
	}
}

fn regular_polygon_area_milli(sides i64, side i64) i64 {
	coefficient := regular_polygon_coefficient(sides)
	if coefficient < 0 { return -1 }
	return coefficient * side * side / 1_000_000
}

fn regular_prism_surface_milli(sides i64, side i64, height i64) i64 {
	coefficient := regular_polygon_coefficient(sides)
	if coefficient < 0 { return -1 }
	return 2 * (coefficient * side * side / 1_000_000) + sides * side * height * 1000
}

fn area_milli(operation i64, a i64, b i64, c i64) i64 {
	return match operation {
		0 { a * a * 1000 }
		1 { a * b * 1000 }
		2 { a * b * 500 }
		3 { scale_pi(a * a * 1000) }
		4 { a * b * 1000 }
		5 { (a + b) * c * 500 }
		6 { area_heron_milli(a, b, c) }
		7 { scale_pi(a * b * 1000) }
		8 { a * b * 500 }
		9 { 6 * a * a * 1000 }
		10 { 2 * (a * b + a * c + b * c) * 1000 }
		11 { scale_pi(4 * a * a * 1000) }
		12 { scale_pi(3 * a * a * 1000) }
		13 { scale_pi(2 * a * (b + a) * 1000) }
		14 { scale_pi(2 * a * b * 1000) }
		15 { scale_pi(a * a * 1000 + a * integer_sqrt((a * a + b * b) * 1_000_000)) }
		16 { scale_pi(a * integer_sqrt((a * a + b * b) * 1_000_000)) }
		17 { (a * a + 2 * a * b) * 1000 }
		18 {
			difference := if a >= b { a - b } else { b - a }
			slant_milli := integer_sqrt((c * c + difference * difference) * 1_000_000)
			scale_pi((a * a + b * b) * 1000 + (a + b) * slant_milli)
		}
		19 { scale_pi_squared(4 * a * b * 1000) }
		20 { regular_polygon_area_milli(a, b) }
		21 { regular_prism_surface_milli(a, b, c) }
		else { -1 }
	}
}

fn area_checksum(values &i64, index i64, count i64) i64 {
	if index >= count { return 0 }
	position := 1 + 4 * int(index)
	operation := unsafe { values[position] }
	a := unsafe { values[position + 1] }
	b := unsafe { values[position + 2] }
	c := unsafe { values[position + 3] }
	if operation < 0 || operation > 21 || a < 0 || a > 1000 || b < 0 || b > 1000 || c < 0 || c > 1000 { return -1 }
	if (operation == 0 || operation == 3 || operation == 9 || operation == 11 || operation == 12) && (b != 0 || c != 0) { return -1 }
	if ((operation >= 1 && operation <= 2) || operation == 4 || (operation >= 7 && operation <= 8) || (operation >= 13 && operation <= 17) || operation == 19 || operation == 20) && c != 0 { return -1 }
	result := area_milli(operation, a, b, c)
	if result < 0 { return -1 }
	remaining := area_checksum(values, index + 1, count)
	if remaining < 0 { return -1 }
	return (index + 1) * (result + 1000000007) + remaining
}

fn area_impl(values &i64, length usize) i64 {
	if length < 1 || length > 1025 { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 0 || count_value > max_operations || int(length) != 1 + 4 * int(count_value) { return -1 }
	return area_checksum(values, 0, count_value)
}

@[export: 'area_benchmark']
pub fn area_benchmark(values &i64, length usize) i64 {
	return area_impl(values, length)
}
