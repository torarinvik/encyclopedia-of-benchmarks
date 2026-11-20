module recursive_backtracker_maze_generation;

fn long recursive_backtracker_maze_generation(long* input, usz length,
                                               uint8* output, usz capacity)
    @export("recursive_backtracker_maze_generation") {
	if (input == null || length < 4 || length > 68) return -1;
	long rows_word = input[0];
	long cols_word = input[1];
	long start_word = input[2];
	long draw_count = input[3];
	if (rows_word < 1 || rows_word > 64 || cols_word < 1 || cols_word > 64) return -1;
	usz rows = (usz)rows_word;
	usz cols = (usz)cols_word;
	usz cells = rows * cols;
	if (cells > 64 || start_word < 0 || (usz)start_word >= cells ||
		draw_count != (long)cells - 1 || length != 4 + cells - 1) return -1;
	for (usz i = 0; i < cells - 1; i += 1) if (input[4 + i] < 0 || input[4 + i] > 3) return -1;

	bool[64] visited;
	uint8[64] walls;
	usz[64] stack;
	for (usz i = 0; i < cells; i += 1) { visited[i] = false; walls[i] = 15; }
	usz depth = 1;
	usz cursor = 0;
	stack[0] = (usz)start_word;
	visited[stack[0]] = true;
	while (depth > 0) {
		usz cell = stack[depth - 1];
		usz row = cell / cols;
		usz col = cell % cols;
		usz[4] next_cells;
		usz[4] directions;
		usz count = 0;
		if (row > 0 && !visited[cell - cols]) { next_cells[count] = cell - cols; directions[count] = 0; count += 1; }
		if (col + 1 < cols && !visited[cell + 1]) { next_cells[count] = cell + 1; directions[count] = 1; count += 1; }
		if (row + 1 < rows && !visited[cell + cols]) { next_cells[count] = cell + cols; directions[count] = 2; count += 1; }
		if (col > 0 && !visited[cell - 1]) { next_cells[count] = cell - 1; directions[count] = 3; count += 1; }
		if (count == 0) { depth -= 1; continue; }
		if (cursor >= cells - 1) return -1;
		usz choice = (usz)input[4 + cursor];
		cursor += 1;
		if (choice >= count) return -1;
		usz next = next_cells[choice];
		usz direction = directions[choice];
		visited[next] = true;
		walls[cell] &= (uint8)~(1u8 << direction);
		walls[next] &= (uint8)~(1u8 << ((direction + 2) & 3));
		stack[depth] = next;
		depth += 1;
	}
	if (cursor != cells - 1) return -1;
	for (usz i = 0; i < cells; i += 1) if (!visited[i]) return -1;
	if (output == null || capacity < cells) return -2;
	for (usz i = 0; i < cells; i += 1) output[i] = walls[i];
	return (long)cells;
}
