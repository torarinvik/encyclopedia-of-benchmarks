module evalloop

const min_passes = i64(0)
const max_passes = i64(1000)
const buffer_size = 2048
const max_output_bytes = 14

fn execute(mut sum u32, opcode int) {
	sum += u32(opcode)
}

fn eval(commands []int, mut sum u32) {
	mut pc := 0
	mut opcode := commands[pc]
	pc++
	for opcode != 0 {
		if opcode < 1 || opcode > 31 { return }
		execute(mut sum, opcode)
		opcode = commands[pc]
		pc++
	}
}

fn format_output(sum_input u32, mut staged []u8) int {
	staged[0] = 83
	staged[1] = 117
	staged[2] = 109
	staged[3] = 58
	staged[4] = 32
	mut used := 5
	mut reversed := [10]u8{}
	mut digits := 0
	mut sum := sum_input
	for {
		reversed[digits] = u8(48 + sum % 10)
		digits++
		sum /= 10
		if sum == 0 { break }
	}
	for digits > 0 {
		digits--
		staged[used] = reversed[digits]
		used++
	}
	staged[used] = 10
	return used + 1
}

@[export: 'evalloop']
pub fn evalloop(passes i64, mut output &u8, output_capacity usize) i64 {
	if passes < min_passes || passes > max_passes { return -1 }
	if unsafe { output == nil } { return -2 }

	mut commands := [buffer_size]int{}
	for index in 0 .. buffer_size - 1 { commands[index] = index % 31 + 1 }
	mut sum := u32(0)
	mut pass := i64(0)
	for pass < passes {
		eval(commands[..], mut sum)
		pass++
	}

	mut staged := [max_output_bytes]u8{}
	used := format_output(sum, mut staged[..])
	if output_capacity < usize(used) { return -2 }
	unsafe { for index in 0 .. used { output[index] = staged[index] } }
	return i64(used)
}
