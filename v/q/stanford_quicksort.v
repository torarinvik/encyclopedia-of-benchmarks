const sort_elements = 5000
const max_prefix_count = i64(100)
const max_output_bytes = 700

fn source_quicksort(mut values []i64, left_value int, right_value int) {
	mut i := left_value
	mut j := right_value
	pivot := values[(left_value + right_value) / 2]
	for {
		for values[i] < pivot { i++ }
		for pivot < values[j] { j-- }
		if i <= j {
			temporary := values[i]
			values[i] = values[j]
			values[j] = temporary
			i++
			j--
		}
		if i > j { break }
	}
	if left_value < j { source_quicksort(mut values, left_value, j) }
	if i < right_value { source_quicksort(mut values, i, right_value) }
}

fn append_number(mut buffer []u8, mut used int, value_value i64) {
	mut value := value_value
	if value < 0 {
		buffer[used] = 45
		used++
		value = -value
	}
	mut reversed := [20]u8{}
	mut count := 0
	for {
		reversed[count] = u8(48 + value % 10)
		count++
		value /= 10
		if value == 0 { break }
	}
	for count > 0 {
		count--
		buffer[used] = reversed[count]
		used++
	}
	buffer[used] = 10
	used++
}

@[export: 'stanford_quicksort']
pub fn stanford_quicksort(prefix_count i64, mut output &u8, output_capacity usize) i64 {
	if prefix_count < 1 || prefix_count > max_prefix_count { return -1 }
	if unsafe { output == nil } { return -2 }

	mut staged := [max_output_bytes]u8{}
	mut used := 0
	for run in 0 .. int(prefix_count) {
		mut values := [sort_elements + 1]i64{}
		mut state := i64(74755)
		for index in 1 .. sort_elements + 1 {
			state = (state * 1309 + 13849) & 65535
			values[index] = state - 50000
		}
		unsafe {
			source_quicksort(mut values[..], 1, sort_elements)
			append_number(mut staged[..], mut used, values[run + 1])
		}
	}

	if output_capacity < used { return -2 }
	unsafe {
		for index in 0 .. used { output[index] = staged[index] }
	}
	return i64(used)
}
