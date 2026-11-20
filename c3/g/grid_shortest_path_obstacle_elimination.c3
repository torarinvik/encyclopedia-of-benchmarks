module grid_shortest_path_obstacle_elimination;

fn long grid_shortest_path_obstacle_elimination(long* values, usz length)
	@export("grid_shortest_path_obstacle_elimination") {
	if (values == null || length < 3 || length > 40) return -2;
	long rows = values[0];
	long columns = values[1];
	long budget = values[2];
	if (rows < 1 || rows > 6 || columns < 1 || columns > 6 || budget < 0 || budget > 6 ||
		length != (usz)(3 + rows * columns)) return -2;

	usz cell_count = (usz)(rows * columns);
	long[36] cells;
	for (usz cell = 0; cell < cell_count; cell += 1) {
		long value = values[3 + cell];
		if (value != 0 && value != 1) return -2;
		cells[cell] = value;
	}
	if (cells[0] != 0 || cells[cell_count - 1] != 0) return -2;

	usz stride = (usz)(budget + 1);
	usz state_count = cell_count * stride;
	long[252] queue;
	long[252] distance;
	for (usz state = 0; state < state_count; state += 1) distance[state] = -1;
	usz head = 0;
	usz tail = 1;
	usz start = (usz)budget;
	queue[0] = (long)start;
	distance[start] = 0;

	while (head < tail) {
		usz state = (usz)queue[head];
		head += 1;
		usz cell = state / stride;
		long remaining = (long)(state % stride);
		if (cell + 1 == cell_count) return distance[state];
		long row = (long)(cell / (usz)columns);
		long column = (long)(cell % (usz)columns);
		long[4] next_rows = { row - 1, row, row, row + 1 };
		long[4] next_columns = { column, column - 1, column + 1, column };
		for (usz direction = 0; direction < 4; direction += 1) {
			long next_row = next_rows[direction];
			long next_column = next_columns[direction];
			if (next_row < 0 || next_row >= rows || next_column < 0 || next_column >= columns) continue;
			usz next_cell = (usz)(next_row * columns + next_column);
			long next_remaining = remaining - cells[next_cell];
			if (next_remaining < 0) continue;
			usz next_state = next_cell * stride + (usz)next_remaining;
			if (distance[next_state] != -1) continue;
			distance[next_state] = distance[state] + 1;
			queue[tail] = (long)next_state;
			tail += 1;
		}
	}
	return -1;
}
