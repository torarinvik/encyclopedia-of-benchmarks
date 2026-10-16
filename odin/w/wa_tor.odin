package wa_tor

MAX_WIDTH :: 8
MAX_HEIGHT :: 8
MAX_CELLS :: 64
MAX_CHRONONS :: 32
MAX_ENTITY_RECORDS :: MAX_CELLS * (MAX_CHRONONS + 1)
HASH_MODULUS :: i64(2147483647)
HASH_MULTIPLIER :: i64(1000003)

Entity :: struct {
	kind: int,
	row: int,
	col: int,
	timer: int,
	energy: int,
	alive: bool,
}

breed_time :: proc "contextless" (kind: int) -> int {
	if kind == 1 do return 5
	return 20
}

move_and_reproduce :: proc "contextless" (entities: [^]Entity, entity_count: ^int, board: [^]int,
	entity_id, width, height: int) {
	old_row := entities[entity_id].row
	old_col := entities[entity_id].col
	delta_rows := [4]int{-1, 0, 1, 0} // N, E, S, W
	delta_cols := [4]int{0, 1, 0, -1}
	moved := false
	for direction := 0; direction < 4; direction += 1 {
		row := old_row + delta_rows[direction]
		col := old_col + delta_cols[direction]
		if row < 0 || row >= height || col < 0 || col >= width do continue
		destination := row * width + col
		if board[destination] != -1 do continue
		board[old_row * width + old_col] = -1
		board[destination] = entity_id
		entities[entity_id].row = row
		entities[entity_id].col = col
		moved = true
		break
	}
	if moved && entities[entity_id].timer <= 0 {
		if entity_count^ < MAX_ENTITY_RECORDS {
			child_id := entity_count^
			kind := entities[entity_id].kind
			breed := breed_time(kind)
			entities[child_id] = Entity{kind = kind, row = old_row, col = old_col,
				timer = breed, energy = (if kind == 1 { 0 } else { 15 }), alive = true}
			board[old_row * width + old_col] = child_id
			entities[entity_id].timer = breed
			entity_count^ += 1
		}
	} else {
		entities[entity_id].timer -= 1
	}
}

predator_action :: proc "contextless" (entities: [^]Entity, entity_count: ^int, board: [^]int,
	entity_id, width, height: int) {
	current := entities[entity_id].row * width + entities[entity_id].col
	if entities[entity_id].energy == 0 {
		board[current] = -1
		entities[entity_id].alive = false
		return
	}
	delta_rows := [4]int{-1, 1, 0, 0} // N, S, W, E
	delta_cols := [4]int{0, 0, -1, 1}
	target := -1
	for direction := 0; direction < 4; direction += 1 {
		row := entities[entity_id].row + delta_rows[direction]
		col := entities[entity_id].col + delta_cols[direction]
		if row < 0 || row >= height || col < 0 || col >= width do continue
		cell := row * width + col
		occupant := board[cell]
		if occupant != -1 && entities[occupant].kind == 1 { target = cell; break }
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
		move_and_reproduce(entities, entity_count, board, entity_id, width, height)
	}
	entities[entity_id].energy -= 1
}

@(export)
wa_tor :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 3 || length > 196 do return -1
	if values[0] < 1 || values[0] > MAX_WIDTH || values[1] < 1 || values[1] > MAX_HEIGHT ||
		values[2] < 0 || values[2] > MAX_CHRONONS do return -1
	width := int(values[0])
	height := int(values[1])
	chronons := int(values[2])
	cell_count := width * height
	if length != c.size_t(3 + 3 * cell_count) do return -1

	entities: [MAX_ENTITY_RECORDS]Entity
	entity_count := 0
	board: [MAX_CELLS]int
	snapshot: [MAX_CELLS]int
	for cell := 0; cell < cell_count; cell += 1 { board[cell] = -1 }
	for cell := 0; cell < cell_count; cell += 1 {
		kind_value := values[3 + 3 * cell]
		timer_value := values[4 + 3 * cell]
		energy_value := values[5 + 3 * cell]
		if kind_value == 0 {
			if timer_value != 0 || energy_value != 0 do return -1
			continue
		}
		if kind_value == 1 {
			if timer_value < 0 || timer_value > 5 || energy_value != 0 do return -1
		} else if kind_value == 2 {
			if timer_value < 0 || timer_value > 20 || energy_value < 0 || energy_value > 15 do return -1
		} else {
			return -1
		}
		entities[entity_count] = Entity{kind = int(kind_value), row = cell / width, col = cell % width,
			timer = int(timer_value), energy = int(energy_value), alive = true}
		board[cell] = entity_count
		entity_count += 1
	}

	for chronon := 0; chronon < chronons; chronon += 1 {
		snapshot_count := 0
		for cell := 0; cell < cell_count; cell += 1 {
			if board[cell] != -1 { snapshot[snapshot_count] = board[cell]; snapshot_count += 1 }
		}
		for i := 0; i < snapshot_count; i += 1 {
			entity_id := snapshot[i]
			if !entities[entity_id].alive do continue
			if entities[entity_id].kind == 1 {
				move_and_reproduce(&entities[0], &entity_count, &board[0], entity_id, width, height)
			} else {
				predator_action(&entities[0], &entity_count, &board[0], entity_id, width, height)
			}
		}
	}

	prey_count := i64(0)
	predator_count := i64(0)
	state_hash := i64(0)
	for cell := 0; cell < cell_count; cell += 1 {
		code := i64(0)
		if board[cell] != -1 {
			entity := entities[board[cell]]
			if entity.kind == 1 {
				prey_count += 1
				code = i64(entity.timer + 33)
			} else {
				predator_count += 1
				code = 1000 + 53 * i64(entity.energy) + i64(entity.timer) + 32
			}
		}
		state_hash = (state_hash * HASH_MULTIPLIER + code) % HASH_MODULUS
	}
	return state_hash * 4225 + 65 * prey_count + predator_count
}
