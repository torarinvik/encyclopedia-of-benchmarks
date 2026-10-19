package almabench

import "core:c"
import "core:c/libc"
import "core:math"

MIN_DAYS :: 1
MAX_DAYS :: 36525
MAX_OUTPUT_BYTES :: 248
PI :: 3.14159265358979323846
TWOPI :: 2.0 * PI
A2R :: PI / 648000.0
R2H :: 12.0 / PI
R2D :: 180.0 / PI
JMILLENIA :: 365250.0
SINEPS :: 0.3977771559319137
COSEPS :: 0.9174820620691818
GAUSSK :: 0.01720209895
AMAS: [8]f64 = {6023600.0, 408523.5, 328900.5, 3098710.0, 1047.355, 3498.5, 22869.0, 19314.0}
DATA: [600]f64 = {
	0.3870983098, 0.0, 0.0, 0.72332982, 0.0, 0.0,
	1.0000010178, 0.0, 0.0, 1.5236793419, 3e-10, 0.0,
	5.2026032092, 1.9132e-06, -3.9e-09, 9.5549091915, -2.13896e-05, 4.44e-08,
	19.2184460618, -3.716e-07, 9.79e-08, 30.1103868694, -1.6635e-06, 6.86e-08,
	252.25090552, 5381016286.88982, -1.92789, 181.97980085, 2106641364.33548, 0.59381,
	100.46645683, 1295977422.83429, -2.04411, 355.43299958, 689050774.93988, 0.94264,
	34.35151874, 109256603.77991, -30.60378, 50.0774443, 43996098.55732, 75.61614,
	314.05500511, 15424811.93933, -1.75083, 304.34866548, 7865503.20744, 0.21103,
	0.2056317526, 0.0002040653, -2.8349e-06, 0.0067719164, -0.0004776521, 9.8127e-06,
	0.0167086342, -0.0004203654, -1.26734e-05, 0.0934006477, 0.0009048438, -8.0641e-06,
	0.0484979255, 0.0016322542, -4.71366e-05, 0.0555481426, -0.0034664062, -6.43639e-05,
	0.0463812221, -0.0002729293, 7.8913e-06, 0.009455747, 6.03263e-05, 0.0,
	77.45611904, 5719.1159, -4.83016, 131.563703, 175.4864, -498.48184,
	102.93734808, 11612.3529, 53.27577, 336.06023395, 15980.45908, -62.328,
	14.33120687, 7758.75163, 259.95938, 93.05723748, 20395.49439, 190.25952,
	173.00529106, 3215.56238, -34.09288, 48.12027554, 1050.71912, 27.39717,
	7.00498625, -214.25629, 0.28977, 3.39466189, -30.84437, -11.67836,
	0.0, 469.97289, -3.35053, 1.84972648, -293.31722, -8.1183,
	1.30326698, -71.5589, 11.95297, 2.48887878, 91.85195, -17.66225,
	0.77319689, -60.72723, 1.25759, 1.76995259, 8.12333, 0.08135,
	48.33089304, -4515.21727, -31.79892, 76.67992019, -10008.48154, -51.32614,
	174.87317577, -8679.27034, 15.34191, 49.55809321, -10620.90088, -230.57416,
	100.46440702, 6362.03561, 326.52178, 113.66550252, -9240.19942, -66.23743,
	74.00595701, 2669.15033, 145.93964, 131.78405702, -221.94322, -0.78728,
	69613.0, 75645.0, 88306.0, 59899.0, 15746.0, 71087.0,
	142173.0, 3086.0, 0.0, 21863.0, 32794.0, 26934.0,
	10931.0, 26250.0, 43725.0, 53867.0, 28939.0, 0.0,
	16002.0, 21863.0, 32004.0, 10931.0, 14529.0, 16368.0,
	15318.0, 32794.0, 0.0, 6345.0, 7818.0, 15636.0,
	7077.0, 8184.0, 14163.0, 1107.0, 4872.0, 0.0,
	1760.0, 1454.0, 1167.0, 880.0, 287.0, 2640.0,
	19.0, 2047.0, 1454.0, 574.0, 0.0, 880.0,
	287.0, 19.0, 1760.0, 1167.0, 306.0, 574.0,
	204.0, 0.0, 177.0, 1265.0, 4.0, 385.0,
	200.0, 208.0, 204.0, 0.0, 102.0, 106.0,
	4.0, 98.0, 1367.0, 487.0, 204.0, 0.0,
	4.0, -13.0, 11.0, -9.0, -9.0, -3.0,
	-1.0, 4.0, 0.0, -156.0, 59.0, -42.0,
	6.0, 19.0, -20.0, -10.0, -12.0, 0.0,
	64.0, -152.0, 62.0, -8.0, 32.0, -41.0,
	19.0, -11.0, 0.0, 124.0, 621.0, -145.0,
	208.0, 54.0, -57.0, 30.0, 15.0, 0.0,
	-23437.0, -2634.0, 6601.0, 6259.0, -1507.0, -1821.0,
	2620.0, -2115.0, -1489.0, 62911.0, -119919.0, 79336.0,
	17814.0, -24241.0, 12068.0, 8306.0, -4893.0, 8902.0,
	389061.0, -262125.0, -44088.0, 8387.0, -22976.0, -2093.0,
	-615.0, -9720.0, 6633.0, -412235.0, -157046.0, -31430.0,
	37817.0, -9740.0, -13.0, -7449.0, 9644.0, 0.0,
	-29.0, -1.0, 9.0, 6.0, -6.0, 5.0,
	4.0, 0.0, 0.0, -48.0, -125.0, -26.0,
	-37.0, 18.0, -13.0, -20.0, -2.0, 0.0,
	-150.0, -46.0, 68.0, 54.0, 14.0, 24.0,
	-28.0, 22.0, 0.0, -621.0, 532.0, -694.0,
	-20.0, 192.0, -94.0, 71.0, -73.0, 0.0,
	-14614.0, -19828.0, -5869.0, 1881.0, -4372.0, -2255.0,
	782.0, 930.0, 913.0, 139737.0, 0.0, 24667.0,
	51123.0, -5102.0, 7429.0, -4095.0, -1976.0, -9566.0,
	-138081.0, 0.0, 37205.0, -49039.0, -41901.0, -33872.0,
	-27037.0, -12474.0, 18797.0, 0.0, 28492.0, 133236.0,
	69654.0, 52322.0, -49577.0, -26430.0, -3593.0, 0.0,
	3086.0, 15746.0, 69613.0, 59899.0, 75645.0, 88306.0,
	12661.0, 2658.0, 0.0, 0.0, 21863.0, 32794.0,
	10931.0, 73.0, 4387.0, 26934.0, 1473.0, 2157.0,
	0.0, 0.0, 10.0, 16002.0, 21863.0, 10931.0,
	1473.0, 32004.0, 4387.0, 73.0, 0.0, 0.0,
	10.0, 6345.0, 7818.0, 1107.0, 15636.0, 7077.0,
	8184.0, 532.0, 10.0, 0.0, 19.0, 1760.0,
	1454.0, 287.0, 1167.0, 880.0, 574.0, 2640.0,
	19.0, 1454.0, 19.0, 574.0, 287.0, 306.0,
	1760.0, 12.0, 31.0, 38.0, 19.0, 574.0,
	4.0, 204.0, 177.0, 8.0, 31.0, 200.0,
	1265.0, 102.0, 4.0, 204.0, 4.0, 102.0,
	106.0, 8.0, 98.0, 1367.0, 487.0, 204.0,
	4.0, 102.0, 21.0, -95.0, -157.0, 41.0,
	-5.0, 42.0, 23.0, 30.0, 0.0, 0.0,
	-160.0, -313.0, -235.0, 60.0, -74.0, -76.0,
	-27.0, 34.0, 0.0, 0.0, -325.0, -322.0,
	-79.0, 232.0, -52.0, 97.0, 55.0, -41.0,
	0.0, 0.0, 2268.0, -979.0, 802.0, 602.0,
	-668.0, -33.0, 345.0, 201.0, -55.0, 0.0,
	7610.0, -4997.0, -7689.0, -5841.0, -2617.0, 1115.0,
	-748.0, -607.0, 6074.0, 354.0, -18549.0, 30125.0,
	20012.0, -730.0, 824.0, 23.0, 1289.0, -352.0,
	-14767.0, -2062.0, -135245.0, -14594.0, 4197.0, -4030.0,
	-5630.0, -2898.0, 2540.0, -306.0, 2939.0, 1986.0,
	89948.0, 2103.0, 8963.0, 2695.0, 3682.0, 1648.0,
	866.0, -154.0, -1963.0, -283.0, -342.0, 136.0,
	-23.0, 62.0, 66.0, -52.0, -33.0, 17.0,
	0.0, 0.0, 524.0, -149.0, -35.0, 117.0,
	151.0, 122.0, -71.0, -62.0, 0.0, 0.0,
	-105.0, -137.0, 258.0, 35.0, -116.0, -88.0,
	-112.0, -80.0, 0.0, 0.0, 854.0, -205.0,
	-936.0, -240.0, 140.0, -341.0, -97.0, -232.0,
	536.0, 0.0, -56980.0, 8016.0, 1012.0, 1448.0,
	-3024.0, -3710.0, 318.0, 503.0, 3767.0, 577.0,
	138606.0, -13478.0, -4964.0, 1441.0, -1319.0, -1482.0,
	427.0, 1236.0, -9167.0, -1918.0, 71234.0, -41116.0,
	5334.0, -4935.0, -1848.0, 66.0, 434.0, -1748.0,
	3780.0, -701.0, -47645.0, 11647.0, 2166.0, 3194.0,
	679.0, 0.0, -244.0, -419.0, -2531.0, 48.0
}

table_value :: proc(offset, width, planet, term: int) -> f64 { return DATA[offset + width * planet + term] }
remainder_f64 :: proc(value, divisor: f64) -> f64 {
	return libc.fmod(value, divisor)
}
normalize_angle :: proc(angle: f64) -> f64 {
	value := remainder_f64(angle, TWOPI)
	if math.abs(value) >= PI { value -= if angle < 0.0 { -TWOPI } else { TWOPI } }
	return value
}
planet_position :: proc(planet: int, day: i64) -> [3]f64 {
	t := f64(day) / JMILLENIA
	semi_major := table_value(0,3,planet,0) + (table_value(0,3,planet,1) + table_value(0,3,planet,2) * t) * t
	mean_longitude := (3600.0 * table_value(24,3,planet,0) + (table_value(24,3,planet,1) + table_value(24,3,planet,2) * t) * t) * A2R
	eccentricity := table_value(48,3,planet,0) + (table_value(48,3,planet,1) + table_value(48,3,planet,2) * t) * t
	perihelion := normalize_angle((3600.0 * table_value(72,3,planet,0) + (table_value(72,3,planet,1) + table_value(72,3,planet,2) * t) * t) * A2R)
	inclination := (3600.0 * table_value(96,3,planet,0) + (table_value(96,3,planet,1) + table_value(96,3,planet,2) * t) * t) * A2R
	node := normalize_angle((3600.0 * table_value(120,3,planet,0) + (table_value(120,3,planet,1) + table_value(120,3,planet,2) * t) * t) * A2R)
	secular_phase := 0.35953620 * t
	for term := 0; term < 8; term += 1 {
		a_arg := table_value(144,9,planet,term) * secular_phase
		l_arg := table_value(360,10,planet,term) * secular_phase
		semi_major += (table_value(216,9,planet,term) * math.cos(a_arg) + table_value(288,9,planet,term) * math.sin(a_arg)) * 0.0000001
		mean_longitude += (table_value(440,10,planet,term) * math.cos(l_arg) + table_value(520,10,planet,term) * math.sin(l_arg)) * 0.0000001
	}
	a_arg := table_value(144,9,planet,8) * secular_phase
	semi_major += t * (table_value(216,9,planet,8) * math.cos(a_arg) + table_value(288,9,planet,8) * math.sin(a_arg)) * 0.0000001
	for term := 8; term <= 9; term += 1 {
		l_arg := table_value(360,10,planet,term) * secular_phase
		mean_longitude += t * (table_value(440,10,planet,term) * math.cos(l_arg) + table_value(520,10,planet,term) * math.sin(l_arg)) * 0.0000001
	}
	mean_longitude = remainder_f64(mean_longitude, TWOPI)
	mean_anomaly := mean_longitude - perihelion
	eccentric_anomaly := mean_anomaly + eccentricity * math.sin(mean_anomaly)
	for iteration := 0; iteration < 10; iteration += 1 {
		correction := (mean_anomaly - eccentric_anomaly + eccentricity * math.sin(eccentric_anomaly)) / (1.0 - eccentricity * math.cos(eccentric_anomaly))
		eccentric_anomaly += correction
		if math.abs(correction) < 1.0e-12 { break }
	}
	true_anomaly := 2.0 * math.atan2(math.sqrt_f64((1.0 + eccentricity) / (1.0 - eccentricity)) * math.sin(eccentric_anomaly / 2.0), math.cos(eccentric_anomaly / 2.0))
	radius := semi_major * (1.0 - eccentricity * math.cos(eccentric_anomaly))
	half_sin := math.sin(inclination / 2.0)
	node_cos := half_sin * math.cos(node)
	node_sin := half_sin * math.sin(node)
	longitude := true_anomaly + perihelion
	longitude_sin := math.sin(longitude)
	longitude_cos := math.cos(longitude)
	correction := 2.0 * (node_sin * longitude_cos - node_cos * longitude_sin)
	inclination_cos := math.cos(inclination / 2.0)
	x := radius * (longitude_cos - correction * node_sin)
	ecliptic_y := radius * (longitude_sin + correction * node_cos)
	ecliptic_z := radius * (-correction * inclination_cos)
	speed := GAUSSK * math.sqrt_f64((1.0 + 1.0 / AMAS[planet]) / (semi_major * semi_major * semi_major))
	xf := semi_major / math.sqrt_f64(1.0 - eccentricity * eccentricity)
	xms := (eccentricity * math.sin(perihelion) + longitude_sin) * xf
	xmc := (eccentricity * math.cos(perihelion) + longitude_cos) * xf
	xpxq2 := 2.0 * node_sin * node_cos
	velocity_x := speed * ((-1.0 + 2.0 * node_sin * node_sin) * xms + xpxq2 * xmc)
	velocity_y := speed * ((1.0 - 2.0 * node_cos * node_cos) * xmc - xpxq2 * xms)
	velocity_z := speed * (2.0 * inclination_cos * (node_sin * xms + node_cos * xmc))
	equatorial_velocity_y := velocity_y * COSEPS - velocity_z * SINEPS
	equatorial_velocity_z := velocity_y * SINEPS + velocity_z * COSEPS
	_ = velocity_x; _ = equatorial_velocity_y; _ = equatorial_velocity_z
	y := ecliptic_y * COSEPS - ecliptic_z * SINEPS
	z := ecliptic_y * SINEPS + ecliptic_z * COSEPS
	distance := math.sqrt_f64(x*x + y*y + z*z)
	right_ascension := math.atan2(y, x) * R2H
	if right_ascension < 0.0 { right_ascension += 24.0 }
	return [3]f64{right_ascension, math.asin(z / distance) * R2D, distance}
}
append_text :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, text: string) {
	for byte in transmute([]u8)text { buffer[used^] = byte; used^ += 1 }
}
append_integer :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, value: i64) {
	var reverse: [20]u8
	remaining := value
	count := 0
	for {
		reverse[count] = u8('0') + u8(remaining % 10); count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for count > 0 { count -= 1; buffer[used^] = reverse[count]; used^ += 1 }
}
rounded_micro_units :: proc(bits: u64) -> u64 {
	exponent := int((bits >> 52) & 0x7ff)
	if exponent == 0 do return 0
	significand := (bits & 0x000f_ffff_ffff_ffff) | (u64(1) << 52)
	shift := 1075 - exponent
	if shift >= 74 do return 0
	low_product := (significand & 0xffff_ffff) * 1_000_000
	high_product := (significand >> 32) * 1_000_000
	middle := (low_product >> 32) + (high_product & 0xffff_ffff)
	limb0 := low_product & 0xffff_ffff
	limb1 := middle & 0xffff_ffff
	limb2 := (high_product >> 32) + (middle >> 32)
	quotient: u64
	half_bit: u64
	lower_nonzero: bool
	if shift < 64 {
		part := shift - 32
		quotient = (limb1 >> u64(part)) | (limb2 << u64(32 - part))
		half_bit = (limb1 >> u64(part - 1)) & 1
		lower_nonzero = limb0 != 0 || (limb1 & ((u64(1) << u64(part - 1)) - 1)) != 0
	} else if shift == 64 {
		quotient = limb2
		half_bit = limb1 >> 31
		lower_nonzero = limb0 != 0 || (limb1 & 0x7fff_ffff) != 0
	} else {
		part := shift - 64
		quotient = limb2 >> u64(part)
		half_bit = (limb2 >> u64(part - 1)) & 1
		lower_nonzero = limb0 != 0 || limb1 != 0 || (limb2 & ((u64(1) << u64(part - 1)) - 1)) != 0
	}
	if half_bit != 0 && (lower_nonzero || (quotient & 1) != 0) { quotient += 1 }
	return quotient
}

append_fixed :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, value: f64) {
	bits := transmute(u64)value
	negative := (bits >> 63) != 0
	scaled := i64(rounded_micro_units(bits & 0x7fff_ffff_ffff_ffff))
	if negative { buffer[used^] = u8('-'); used^ += 1 }
	append_integer(buffer, used, scaled / 1000000)
	buffer[used^] = u8('.'); used^ += 1
	fraction := scaled % 1000000
	place := 100000
	for place > 0 {
		buffer[used^] = u8('0') + u8(fraction / place); used^ += 1
		fraction %= place; place /= 10
	}
}

@(export)
almabench :: proc "c" (days: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if days < MIN_DAYS || days > MAX_DAYS do return -1
	if output == nil do return -2
	var positions: [8][3]f64
	for day: i64 = 1; day <= days; day += 1 {
		for planet := 0; planet < 8; planet += 1 { positions[planet] = planet_position(planet, day) }
	}
	var staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	for position in positions {
		append_fixed(&staged, &used, position[0]); append_text(&staged, &used, " ")
		append_fixed(&staged, &used, position[1]); append_text(&staged, &used, " ")
		append_fixed(&staged, &used, position[2]); append_text(&staged, &used, "\n")
	}
	if output_capacity < c.size_t(used) do return -2
	for index := 0; index < used; index += 1 { output[index] = staged[index] }
	return i64(used)
}
