package stanford_towers

import "core:c"

DISK_COUNT :: i32(14)
MAX_CELLS :: 18
MAX_RUNS :: i64(100)
MAX_OUTPUT_BYTES :: 600
STAGING_BYTES :: 2400

Cell :: struct { disc_size: i32, next: i32 }
Tower_State :: struct {
	stack: [4]i32,
	cells: [MAX_CELLS + 1]Cell,
	free_list: i32,
	moves_done: i32,
}

get_element :: proc(state: ^Tower_State) -> i32 {
	if state.free_list <= 0 do return 0
	element := state.free_list
	state.free_list = state.cells[int(element)].next
	return element
}

push :: proc(state: ^Tower_State, disc_size: i32, peg: int) {
	if state.stack[peg] > 0 && state.cells[int(state.stack[peg])].disc_size <= disc_size do return
	element := get_element(state)
	if element <= 0 do return
	state.cells[int(element)].next = state.stack[peg]
	state.stack[peg] = element
	state.cells[int(element)].disc_size = disc_size
}

initialize_peg :: proc(state: ^Tower_State, peg: int, disks: i32) {
	state.stack[peg] = 0
	for disk := disks; disk >= 1; disk -= 1 { push(state, disk, peg) }
}

pop :: proc(state: ^Tower_State, peg: int) -> i32 {
	if state.stack[peg] <= 0 do return 0
	element := state.stack[peg]
	disc_size := state.cells[int(element)].disc_size
	state.stack[peg] = state.cells[int(element)].next
	state.cells[int(element)].next = state.free_list
	state.free_list = element
	return disc_size
}

do_move :: proc(state: ^Tower_State, source, destination: int) {
	disc_size := pop(state, source)
	push(state, disc_size, destination)
	state.moves_done += 1
}

tower :: proc(state: ^Tower_State, source, destination: int, disks: i32) {
	if disks == 1 {
		do_move(state, source, destination)
	} else {
		auxiliary := 6 - source - destination
		tower(state, source, auxiliary, disks - 1)
		do_move(state, source, destination)
		tower(state, auxiliary, destination, disks - 1)
	}
}

run_towers :: proc() -> i32 {
	var state: Tower_State
	for index := 1; index <= MAX_CELLS; index += 1 { state.cells[index].next = i32(index - 1) }
	state.free_list = i32(MAX_CELLS)
	initialize_peg(&state, 1, DISK_COUNT)
	state.stack[2] = 0
	state.stack[3] = 0
	state.moves_done = 0
	tower(&state, 1, 2, DISK_COUNT)
	return state.moves_done
}

append_text :: proc(buffer: ^[STAGING_BYTES]u8, used: ^int, text: string) {
	for byte in transmute([]u8)text { buffer[used^] = byte; used^ += 1 }
}

append_integer :: proc(buffer: ^[STAGING_BYTES]u8, used: ^int, value: i32) {
	remaining := value
	if remaining < 0 { buffer[used^] = u8('-'); used^ += 1; remaining = -remaining }
	var reverse: [12]u8
	count := 0
	for { reverse[count] = u8('0') + u8(remaining % 10); count += 1; remaining /= 10; if remaining == 0 do break }
	for count > 0 { count -= 1; buffer[used^] = reverse[count]; used^ += 1 }
}

@(export)
stanford_towers :: proc "c" (runs: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if runs < 1 || runs > MAX_RUNS do return -1
	if output == nil do return -2
	var staged: [STAGING_BYTES]u8
	used := 0
	for run := i64(0); run < runs; run += 1 {
		moves_done := run_towers()
		if moves_done != 16383 { append_text(&staged, &used, " Error in Towers.\n") }
		append_integer(&staged, &used, moves_done)
		append_text(&staged, &used, "\n")
	}
	if used > MAX_OUTPUT_BYTES || output_capacity < c.size_t(used) do return -2
	for index := 0; index < used; index += 1 { output[index] = staged[index] }
	return i64(used)
}
