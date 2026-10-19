module stanford_towers

const disk_count = 14
const max_cells = 18
const max_runs = i64(100)
const max_output_bytes = 600
const staging_bytes = 2400

struct Cell {
	disc_size int
	next int
}

struct TowerState {
	stack [4]int
	cells [max_cells + 1]Cell
	free_list int
	moves_done int
}

fn get_element(mut state TowerState) int {
	if state.free_list <= 0 { return 0 }
	element := state.free_list
	state.free_list = state.cells[element].next
	return element
}

fn push(mut state TowerState, disc_size int, peg int) {
	if state.stack[peg] > 0 && state.cells[state.stack[peg]].disc_size <= disc_size { return }
	element := get_element(mut state)
	if element <= 0 { return }
	state.cells[element].next = state.stack[peg]
	state.stack[peg] = element
	state.cells[element].disc_size = disc_size
}

fn initialize_peg(mut state TowerState, peg int, disks int) {
	state.stack[peg] = 0
	mut disk := disks
	for disk >= 1 {
		push(mut state, disk, peg)
		disk--
	}
}

fn pop(mut state TowerState, peg int) int {
	if state.stack[peg] <= 0 { return 0 }
	element := state.stack[peg]
	disc_size := state.cells[element].disc_size
	state.stack[peg] = state.cells[element].next
	state.cells[element].next = state.free_list
	state.free_list = element
	return disc_size
}

fn do_move(mut state TowerState, source int, destination int) {
	disc_size := pop(mut state, source)
	push(mut state, disc_size, destination)
	state.moves_done++
}

fn tower(mut state TowerState, source int, destination int, disks int) {
	if disks == 1 {
		do_move(mut state, source, destination)
	} else {
		auxiliary := 6 - source - destination
		tower(mut state, source, auxiliary, disks - 1)
		do_move(mut state, source, destination)
		tower(mut state, auxiliary, destination, disks - 1)
	}
}

fn run_towers() int {
	mut state := TowerState{}
	for index in 1 .. max_cells + 1 { state.cells[index].next = index - 1 }
	state.free_list = max_cells
	initialize_peg(mut state, 1, disk_count)
	state.stack[2] = 0
	state.stack[3] = 0
	state.moves_done = 0
	tower(mut state, 1, 2, disk_count)
	return state.moves_done
}

fn append_text(mut buffer []u8, mut used int, text string) {
	for byte in text.bytes() { buffer[used] = byte; used++ }
}

fn append_integer(mut buffer []u8, mut used int, value int) {
	mut remaining := value
	if remaining < 0 { buffer[used] = u8(`-`); used++; remaining = -remaining }
	mut reversed := [12]u8{}
	mut count := 0
	for {
		reversed[count] = u8(48 + remaining % 10)
		count++
		remaining /= 10
		if remaining == 0 { break }
	}
	for count > 0 { count--; buffer[used] = reversed[count]; used++ }
}

@[export: 'stanford_towers']
pub fn stanford_towers(runs i64, mut output &u8, output_capacity usize) i64 {
	if runs < 1 || runs > max_runs { return -1 }
	if unsafe { output == nil } { return -2 }
	mut staged := [staging_bytes]u8{}
	mut used := 0
	for _ in 0 .. int(runs) {
		moves_done := run_towers()
		if moves_done != 16383 { append_text(mut staged[..], mut used, ' Error in Towers.\n') }
		append_integer(mut staged[..], mut used, moves_done)
		append_text(mut staged[..], mut used, '\n')
	}
	if used > max_output_bytes || output_capacity < usize(used) { return -2 }
	unsafe { for index in 0 .. used { output[index] = staged[index] } }
	return i64(used)
}
