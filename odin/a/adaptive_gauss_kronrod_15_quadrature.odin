package adaptive_gauss_kronrod_15_quadrature

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 6
MAX_INTERVALS :: 16

Interval :: struct { left, right, value, error: f64 }

NODES :: [7]f64{0.9914553711208126392, 0.9491079123427585245, 0.8648644233597690728,
	0.7415311855993944399, 0.5860872354676911303, 0.4058451513773971669, 0.2077849550078984676}
KW :: [7]f64{0.022935322010529225, 0.06309209262997855, 0.10479001032225018,
	0.14065325971552592, 0.16900472663926790, 0.19035057806478541, 0.20443294007529889}
GW :: [3]f64{0.12948496616886969, 0.27970539148927667, 0.38183005050511894}

sample :: proc(id: i64, x: f64) -> f64 {
	if id == 0 do return math.exp_f64(4.0*x)
	if id == 1 do return math.sin_f64(10.0*x)
	if id == 2 do return 1.0/(1.0+9.0*x*x)
	x2 := x*x
	x4 := x2*x2
	x8 := x4*x4
	return x8*x4*x2
}

pair_estimate :: proc(id: i64, a, b: f64) -> (f64, f64) {
	center := (a+b)*0.5
	half := (b-a)*0.5
	fc := sample(id, center)
	ks := 0.2094821410847278280*fc
	gs := 0.4179591836734693878*fc
	for i in 0..<7 {
		offset := half*NODES[i]
		pair := sample(id, center-offset)+sample(id, center+offset)
		ks += KW[i]*pair
		if i == 1 do gs += GW[0]*pair
		if i == 3 do gs += GW[1]*pair
		if i == 5 do gs += GW[2]*pair
	}
	return half*ks, half*gs
}

exact_integer :: proc(x: f64, lo, hi: i64) -> bool {
	if math.is_nan(x) || math.is_inf(x) || x < f64(lo) || x > f64(hi) do return false
	return f64(i64(x)) == x
}

@(export)
adaptive_gauss_kronrod_15_quadrature :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != 5 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 0, 3) || !exact_integer(input[1], -1_000_000, 1_000_000) ||
		!exact_integer(input[2], -1_000_000, 1_000_000) || !exact_integer(input[3], 6, 8) ||
		!exact_integer(input[4], 1, MAX_INTERVALS) do return -1
	id := i64(input[0]); a_micro := i64(input[1]); b_micro := i64(input[2])
	exponent := i64(input[3]); limit := i64(input[4])
	if a_micro > b_micro do return -1
	if output == nil || output_capacity < 1 do return -2
	a := f64(a_micro)/1_000_000.0
	b := f64(b_micro)/1_000_000.0
	if a == b { output[0] = 0.0; return 1 }
	var intervals: [MAX_INTERVALS]Interval
	k, g := pair_estimate(id, a, b)
	intervals[0] = Interval{a, b, k, math.abs_f64(k-g)}
	count := i64(1)
	tolerance := f64(1.0)
	for _ in 0..<exponent { tolerance *= 0.1 }
	for {
		total := f64(0.0)
		error := f64(0.0)
		for i in 0..<count { total += intervals[i].value; error += intervals[i].error }
		scale := f64(1.0)
		if math.abs_f64(total) > 1.0 do scale = math.abs_f64(total)
		if error <= tolerance*scale {
			if math.is_nan(total) || math.is_inf(total) do return -1
			output[0] = total
			return 1
		}
		if count >= limit do return -3
		best := i64(0)
		for i in 1..<count {
			if intervals[i].error > intervals[best].error ||
				(intervals[i].error == intervals[best].error && intervals[i].left < intervals[best].left) do best = i
		}
		left := intervals[best].left; right := intervals[best].right; middle := (left+right)*0.5
		lk, lg := pair_estimate(id, left, middle)
		rk, rg := pair_estimate(id, middle, right)
		intervals[best] = Interval{left, middle, lk, math.abs_f64(lk-lg)}
		intervals[count] = Interval{middle, right, rk, math.abs_f64(rk-rg)}
		count += 1
	}
}
