const min_runs = 1
const max_runs = 100
const element_count = 500
const max_output_bytes = 700

fn build_and_sort_pass(run int) (int, bool) {
	mut sortlist := [element_count + 1]i32{}
	mut biggest := i32(0)
	mut littlest := i32(0)
	mut seed := i64(74755)
	for index in 1 .. element_count + 1 {
		seed = (seed * 1309 + 13849) & 65535
		temp := seed
		sortlist[index] = i32(temp - (temp / 100000) * 100000 - 50000)
		if sortlist[index] > biggest { biggest = sortlist[index] }
		else if sortlist[index] < littlest { littlest = sortlist[index] }
	}
	mut top := element_count
	for top > 1 {
		mut index := 1
		for index < top {
			if sortlist[index] > sortlist[index + 1] {
				temp := sortlist[index]
				sortlist[index] = sortlist[index + 1]
				sortlist[index + 1] = temp
			}
			index++
		}
		top--
	}
	return sortlist[run + 1], sortlist[1] != littlest || sortlist[element_count] != biggest
}

fn append_text(mut buffer []u8, mut used int, text string) {
	for byte in text.bytes() {
		buffer[used] = byte
		used++
	}
}

fn append_integer(mut buffer []u8, mut used int, value i32) {
	mut remaining := value
	if remaining < 0 {
		buffer[used] = u8(`-`)
		used++
		remaining = -remaining
	}
	mut reversed := [12]u8{}
	mut count := 0
	for {
		reversed[count] = u8(48 + remaining % 10)
		count++
		remaining /= 10
		if remaining == 0 { break }
	}
	for count > 0 {
		count--
		buffer[used] = reversed[count]
		used++
	}
}

@[export: 'stanford_bubblesort']
pub fn stanford_bubblesort(runs i64, mut output &u8, output_capacity usize) i64 {
	if runs < min_runs || runs > max_runs { return -1 }
	if unsafe { output == nil } { return -2 }
	mut staged := [max_output_bytes]u8{}
	mut used := 0
	for run in 0 .. int(runs) {
		value, endpoint_error := build_and_sort_pass(run)
		if endpoint_error { append_text(mut staged[..], mut used, 'Error3 in Bubble.\n') }
		append_integer(mut staged[..], mut used, value)
		append_text(mut staged[..], mut used, '\n')
	}
	if output_capacity < usize(used) { return -2 }
	unsafe {
		for index in 0 .. used { output[index] = staged[index] }
	}
	return i64(used)
}
