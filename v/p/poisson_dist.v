module poisson_dist

import math

const max_milli_value = i64(100000)
const max_success_count = i64(20)
const invalid_result = -1.0e300

fn poisson_factorial(x f64) f64 {
	mut factorial := x
	mut index := i64(x) - 1
	for index > 0 {
		factorial *= f64(index)
		index--
	}
	if factorial <= 0.0 { factorial = 1.0 }
	return factorial
}

fn poisson_point(mean f64, successes i64) f64 {
	return (math.pow(mean, f64(successes)) * math.exp(-mean)) / poisson_factorial(f64(successes))
}

@[export: 'poisson_dist']
pub fn poisson_dist(input &i64, length usize) f64 {
	if length != 4 { return invalid_result }
	operation := unsafe { input[0] }
	first := unsafe { input[1] }
	second := unsafe { input[2] }
	third := unsafe { input[3] }
	if operation == 0 {
		if first < 0 || first > max_milli_value || second < 1 || second > max_milli_value || third != 0 { return invalid_result }
		return (f64(first) / 1000.0) / (f64(second) / 1000.0)
	}
	if operation == 1 {
		if first < 0 || first > max_milli_value || second < 0 || second > max_milli_value || third != 0 { return invalid_result }
		return (f64(first) / 1000.0) * (f64(second) / 1000.0)
	}
	if operation == 2 {
		if first < 0 || first > max_milli_value || second < 0 || second > max_success_count || third != 0 { return invalid_result }
		return poisson_point(f64(first) / 1000.0, second)
	}
	if operation == 3 {
		if first < 0 || first > max_milli_value || second < 0 || second > third || third > max_success_count { return invalid_result }
		mean := f64(first) / 1000.0
		mut probability := 0.0
		mut successes := second
		for successes <= third {
			probability += poisson_point(mean, successes)
			successes++
		}
		return probability
	}
	return invalid_result
}
