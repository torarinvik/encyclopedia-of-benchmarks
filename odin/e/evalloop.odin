package evalloop

import "core:c"

MIN_PASSES :: i64(0)
MAX_PASSES :: i64(1000)
BUFFER_SIZE :: 2048
OUTPUT_CAPACITY :: 14

execute :: proc(sum: ^u32, opcode: i32) {
	sum^ += u32(opcode)
}

eval :: proc(commands: [^]i32, sum: ^u32) {
	pc := 0
	opcode := commands[pc]
	pc += 1
	for opcode != 0 {
		if opcode < 1 || opcode > 31 do return
		execute(sum, opcode)
		opcode = commands[pc]
		pc += 1
	}
}

format_output :: proc(sum_input: u32, staged: [^]u8) -> int {
	staged[0] = 83; staged[1] = 117; staged[2] = 109; staged[3] = 58; staged[4] = 32
	used := 5
	reversed: [10]u8
	digits := 0
	sum := sum_input
	for {
		reversed[digits] = u8(48 + sum % 10)
		digits += 1
		sum /= 10
		if sum == 0 do break
	}
	for digits > 0 {
		digits -= 1
		staged[used] = reversed[digits]
		used += 1
	}
	staged[used] = 10
	return used + 1
}

@(export, link_name="evalloop")
evalloop :: proc "c" (passes: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if passes < MIN_PASSES || passes > MAX_PASSES do return -1
	if output == nil do return -2

	commands: [BUFFER_SIZE]i32
	for index in 0..<BUFFER_SIZE-1 { commands[index] = i32(index % 31 + 1) }
	commands[BUFFER_SIZE-1] = 0
	sum: u32 = 0
	for _ in 0..<int(passes) { eval(&commands[0], &sum) }

	staged: [OUTPUT_CAPACITY]u8
	used := format_output(sum, &staged[0])
	if output_capacity < c.size_t(used) do return -2
	for index in 0..<used { output[index] = staged[index] }
	return i64(used)
}
