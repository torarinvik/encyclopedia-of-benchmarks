package stanford_bubblesort

import "core:c"

MIN_RUNS :: i64(1)
MAX_RUNS :: i64(100)
ELEMENT_COUNT :: 500
MAX_OUTPUT_BYTES :: 700

Pass_Result :: struct { value: i32, endpoint_error: bool }

build_and_sort_pass :: proc(run: int) -> Pass_Result {
	var sortlist: [ELEMENT_COUNT + 1]i32
	biggest: i32 = 0
	littlest: i32 = 0
	seed: i64 = 74755
	for index := 1; index <= ELEMENT_COUNT; index += 1 {
		seed = (seed * 1309 + 13849) & 65535
		temp := seed
		sortlist[index] = i32(temp - (temp / 100000) * 100000 - 50000)
		if sortlist[index] > biggest { biggest = sortlist[index] }
		else if sortlist[index] < littlest { littlest = sortlist[index] }
	}
	top := ELEMENT_COUNT
	for top > 1 {
		index := 1
		for index < top {
			if sortlist[index] > sortlist[index+1] {
				temp := sortlist[index]
			sortlist[index] = sortlist[index+1]
			sortlist[index+1] = temp
			}
			index += 1
		}
		top -= 1
	}
	return Pass_Result{sortlist[run+1], sortlist[1] != littlest || sortlist[ELEMENT_COUNT] != biggest}
}

append_text :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, text: string) {
	for byte in transmute([]u8)text { buffer[used^] = byte; used^ += 1 }
}

append_integer :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, value: i32) {
	remaining := value
	if remaining < 0 { buffer[used^] = u8('-'); used^ += 1; remaining = -remaining }
	var reversed: [12]u8
	count := 0
	for { reversed[count] = u8('0') + u8(remaining%10); count += 1; remaining /= 10; if remaining == 0 do break }
	for count > 0 { count -= 1; buffer[used^] = reversed[count]; used^ += 1 }
}

@(export)
stanford_bubblesort :: proc "c" (runs: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if runs < MIN_RUNS || runs > MAX_RUNS do return -1
	if output == nil do return -2
	var staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	for run := 0; run < int(runs); run += 1 {
		item := build_and_sort_pass(run)
		if item.endpoint_error { append_text(&staged, &used, "Error3 in Bubble.\n") }
		append_integer(&staged, &used, item.value)
		append_text(&staged, &used, "\n")
	}
	if output_capacity < c.size_t(used) do return -2
	for index := 0; index < used; index += 1 { output[index] = staged[index] }
	return i64(used)
}
