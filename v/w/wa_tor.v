module main

const max_width = 8
const max_height = 8
const max_cells = 64
const max_chronons = 32
const max_entity_records = max_cells * (max_chronons + 1)
const hash_modulus = i64(2147483647)
const hash_multiplier = i64(1000003)

struct Entity {
mut:
	kind int
	row int
	col int
	timer int
	energy int
	alive bool
}

fn breed_time(kind int) int {
	if kind == 1 { return 5 }
	return 20
}

fn move_and_reproduce(mut entities []Entity, mut entity_count int, mut board []int,
	entity_id int, width int, height int) {
	old_row := entities[entity_id].row
	old_col := entities[entity_id].col
	delta_rows := [-1, 0, 1, 0] // N, E, S, W
	delta_cols := [0, 1, 0, -1]
	mut moved := false
	for direction in 0 .. 4 {
		row := old_row + delta_rows[direction]
		col := old_col + delta_cols[direction]
		if row < 0 || row >= height || col < 0 || col >= width { continue }
		destination := row * width + col
		if board[destination] != -1 { continue }
		board[old_row * width + old_col] = -1
		board[destination] = entity_id
		entities[entity_id].row = row
		entities[entity_id].col = col
		moved = true
		break
	}
	if moved && entities[entity_id].timer <= 0 {
		if entity_count < max_entity_records {
			child_id := entity_count
			kind := entities[entity_id].kind
			breed := breed_time(kind)
			entities[child_id] = Entity{kind: kind, row: old_row, col: old_col, timer: breed,
				energy: if kind == 1 { 0 } else { 15 }, alive: true}
			board[old_row * width + old_col] = child_id
			entities[entity_id].timer = breed
			entity_count++
		}
	} else {
		entities[entity_id].timer--
	}
}

fn predator_action(mut entities []Entity, mut entity_count int, mut board []int,
	entity_id int, width int, height int) {
	current := entities[entity_id].row * width + entities[entity_id].col
	if entities[entity_id].energy == 0 {
		board[current] = -1
		entities[entity_id].alive = false
		return
	}
	delta_rows := [-1, 1, 0, 0] // N, S, W, E
	delta_cols := [0, 0, -1, 1]
	mut target := -1
	for direction in 0 .. 4 {
		row := entities[entity_id].row + delta_rows[direction]
		col := entities[entity_id].col + delta_cols[direction]
		if row < 0 || row >= height || col < 0 || col >= width { continue }
		cell := row * width + col
		occupant := board[cell]
		if occupant != -1 && entities[occupant].kind == 1 {
			target = cell
			break
		}
	}
	if target != -1 {
		prey_id := board[target]
		entities[prey_id].alive = false
		board[current] = -1
		board[target] = entity_id
		entities[entity_id].row = target / width
		entities[entity_id].col = target % width
		entities[entity_id].energy += 5
	} else {
		move_and_reproduce(mut entities, mut entity_count, mut board, entity_id, width, height)
	}
	entities[entity_id].energy--
}

@[export: 'wa_tor']
pub fn wa_tor(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 3 || length > 196 { return -1 }
		if values[0] < 1 || values[0] > max_width || values[1] < 1 || values[1] > max_height ||
			values[2] < 0 || values[2] > max_chronons { return -1 }
		width := int(values[0])
		height := int(values[1])
		chronons := int(values[2])
		cell_count := width * height
		if length != usize(3 + 3 * cell_count) { return -1 }

		mut entities := []Entity{len: max_entity_records}
		mut entity_count := 0
		mut board := []int{len: max_cells, init: -1}
		mut snapshot := []int{len: max_cells}
		for cell in 0 .. cell_count {
			kind_value := values[3 + 3 * cell]
			timer_value := values[4 + 3 * cell]
			energy_value := values[5 + 3 * cell]
			if kind_value == 0 {
				if timer_value != 0 || energy_value != 0 { return -1 }
				continue
			}
			if kind_value == 1 {
				if timer_value < 0 || timer_value > 5 || energy_value != 0 { return -1 }
			} else if kind_value == 2 {
				if timer_value < 0 || timer_value > 20 || energy_value < 0 || energy_value > 15 { return -1 }
			} else {
				return -1
			}
			entities[entity_count] = Entity{kind: int(kind_value), row: cell / width, col: cell % width,
				timer: int(timer_value), energy: int(energy_value), alive: true}
			board[cell] = entity_count
			entity_count++
		}

		for _ in 0 .. chronons {
			mut snapshot_count := 0
			for cell in 0 .. cell_count {
				if board[cell] != -1 { snapshot[snapshot_count] = board[cell]; snapshot_count++ }
			}
			for i in 0 .. snapshot_count {
				entity_id := snapshot[i]
				if !entities[entity_id].alive { continue }
				if entities[entity_id].kind == 1 {
					move_and_reproduce(mut entities, mut entity_count, mut board, entity_id, width, height)
				} else {
					predator_action(mut entities, mut entity_count, mut board, entity_id, width, height)
				}
			}
		}

		mut prey_count := i64(0)
		mut predator_count := i64(0)
		mut state_hash := i64(0)
		for cell in 0 .. cell_count {
			mut code := i64(0)
			if board[cell] != -1 {
				entity := entities[board[cell]]
				if entity.kind == 1 {
					prey_count++
					code = i64(entity.timer + 33)
				} else {
					predator_count++
					code = i64(1000 + 53 * entity.energy + entity.timer + 32)
				}
			}
			state_hash = (state_hash * hash_multiplier + code) % hash_modulus
		}
		return state_hash * 4225 + 65 * prey_count + predator_count
	}
}
