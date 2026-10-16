package poisson_dist

import "core:c"
import "core:math"

MAX_MILLI_VALUE :: i64(100000)
MAX_SUCCESS_COUNT :: i64(20)
INVALID_RESULT :: f64(-1.0e300)

poisson_factorial :: proc(x: f64) -> f64 {
	factorial := x
	index := i64(x) - 1
	for index > 0 {
		factorial *= f64(index)
		index -= 1
	}
	if factorial <= 0.0 do factorial = 1.0
	return factorial
}

poisson_point :: proc(mean: f64, successes: i64) -> f64 {
	return (math.pow_f64(mean, f64(successes)) * math.exp_f64(-mean)) / poisson_factorial(f64(successes))
}

@(export)
poisson_dist :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length != 4 do return INVALID_RESULT
	operation, first, second, third := input[0], input[1], input[2], input[3]
	if operation == 0 {
		if first < 0 || first > MAX_MILLI_VALUE || second < 1 || second > MAX_MILLI_VALUE || third != 0 do return INVALID_RESULT
		return (f64(first) / 1000.0) / (f64(second) / 1000.0)
	}
	if operation == 1 {
		if first < 0 || first > MAX_MILLI_VALUE || second < 0 || second > MAX_MILLI_VALUE || third != 0 do return INVALID_RESULT
		return (f64(first) / 1000.0) * (f64(second) / 1000.0)
	}
	if operation == 2 {
		if first < 0 || first > MAX_MILLI_VALUE || second < 0 || second > MAX_SUCCESS_COUNT || third != 0 do return INVALID_RESULT
		return poisson_point(f64(first) / 1000.0, second)
	}
	if operation == 3 {
		if first < 0 || first > MAX_MILLI_VALUE || second < 0 || second > third || third > MAX_SUCCESS_COUNT do return INVALID_RESULT
		mean := f64(first) / 1000.0
		probability := 0.0
		for successes := second; successes <= third; successes += 1 {
			probability += poisson_point(mean, successes)
		}
		return probability
	}
	return INVALID_RESULT
}
