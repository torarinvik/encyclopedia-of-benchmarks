module negafibonacci_representation

const max_index = 17
const value_limit = 1000

fn encode(value i64, mut output [17]u8) int {
	mut fib := [18]i64{}
	mut weight := [18]i64{}
	mut low := [18]i64{}
	mut high := [18]i64{}
	mut digit := [18]u8{}
	fib[1] = 1
	fib[2] = 1
	for k in 3 .. max_index + 1 { fib[k] = fib[k-1] + fib[k-2] }
	for k in 1 .. max_index + 1 {
		weight[k] = fib[k]
		if k % 2 == 0 { weight[k] = -fib[k] }
	}
	for k in 1 .. max_index + 1 {
		suffix_low := if k == 1 { i64(0) } else { low[k-2] }
		suffix_high := if k == 1 { i64(0) } else { high[k-2] }
		with_low := weight[k] + suffix_low
		with_high := weight[k] + suffix_high
		low[k] = if low[k-1] < with_low { low[k-1] } else { with_low }
		high[k] = if high[k-1] > with_high { high[k-1] } else { with_high }
	}
	mut remaining := value
	mut selected_above := false
	for k := max_index; k > 0; k-- {
		mut choose := false
		if !selected_above {
			suffix_low := if k == 1 { i64(0) } else { low[k-2] }
			suffix_high := if k == 1 { i64(0) } else { high[k-2] }
			candidate := remaining - weight[k]
			choose = suffix_low <= candidate && candidate <= suffix_high
		}
		if choose { digit[k] = 1; remaining -= weight[k] }
		selected_above = choose
	}
	mut highest := max_index
	for highest > 1 && digit[highest] == 0 { highest-- }
	for k := highest; k > 0; k-- {
		output[highest-k] = u8('0')
		if digit[k] == 1 { output[highest-k] = u8('1') }
	}
	return highest
}

@[export: 'negafibonacci_representation']
pub fn negafibonacci_representation(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 1 { return -1 }
		value := input[0]
		if value < -value_limit || value > value_limit { return -1 }
		mut staged := [max_index]u8{}
		required := encode(value, mut staged)
		if output == nil || output_capacity < usize(required) { return -2 }
		for index in 0 .. required { output[index] = staged[index] }
		return i64(required)
	}
}
