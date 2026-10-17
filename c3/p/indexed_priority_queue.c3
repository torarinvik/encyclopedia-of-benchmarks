module indexed_priority_queue;

const MAX_EVENTS = 256;
const MAX_ACTIVE = 64;
const MAX_INPUT_VALUES = 1538;

fn void store_i64_le(char* output, usz position, long value) {
	ulong bits = (ulong)value;
	for (usz byte = 0; byte < 8; byte++) output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn bool key_in_use(long* heap_ids, long* heap_keys, usz size, long key, long except_id) {
	for (usz index = 0; index < size; index++) if (heap_ids[index] != except_id && heap_keys[index] == key) return true;
	return false;
}

fn bool sift_up(long* heap_ids, long* heap_keys, int* positions, usz index) {
	long item_id = heap_ids[index];
	long item_key = heap_keys[index];
	usz original = index;
	while (index > 0) {
		usz parent = (index - 1) / 2;
		if (item_key >= heap_keys[parent]) break;
		heap_ids[index] = heap_ids[parent];
		heap_keys[index] = heap_keys[parent];
		positions[(usz)heap_ids[index]] = (int)index;
		index = parent;
	}
	heap_ids[index] = item_id;
	heap_keys[index] = item_key;
	positions[(usz)item_id] = (int)index;
	return index != original;
}

fn void sift_down(long* heap_ids, long* heap_keys, int* positions, usz size, usz index) {
	long item_id = heap_ids[index];
	long item_key = heap_keys[index];
	usz half = size / 2;
	while (index < half) {
		usz child = index * 2 + 1;
		usz right = child + 1;
		if (right < size && heap_keys[child] > heap_keys[right]) child = right;
		if (item_key <= heap_keys[child]) break;
		heap_ids[index] = heap_ids[child];
		heap_keys[index] = heap_keys[child];
		positions[(usz)heap_ids[index]] = (int)index;
		index = child;
	}
	heap_ids[index] = item_id;
	heap_keys[index] = item_key;
	positions[(usz)item_id] = (int)index;
}

fn void remove_at(usz* size_ptr, long* heap_ids, long* heap_keys, int* positions, usz index) {
	usz new_size = *size_ptr - 1;
	long removed_id = heap_ids[index];
	long moved_id = heap_ids[new_size];
	long moved_key = heap_keys[new_size];
	*size_ptr = new_size;
	positions[(usz)removed_id] = -1;
	if (index == new_size) return;
	heap_ids[index] = moved_id;
	heap_keys[index] = moved_key;
	positions[(usz)moved_id] = (int)index;
	if (!sift_up(heap_ids, heap_keys, positions, index)) sift_down(heap_ids, heap_keys, positions, new_size, index);
}

fn long indexed_priority_queue(long* values, usz length, char* output, usz output_capacity)
	@export("indexed_priority_queue")
{
	if (values == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
	if (values[0] < 0 || values[0] > MAX_EVENTS) return -1;
	usz event_count = (usz)values[0];
	if (length != 1 + 6 * event_count) return -1;
	if (event_count == 0) return 0;

	long[MAX_ACTIVE] heap_ids;
	long[MAX_ACTIVE] heap_keys;
	int[MAX_ACTIVE] positions;
	long[MAX_EVENTS * 6] records;
	for (usz id = 0; id < MAX_ACTIVE; id++) positions[id] = -1;
	usz size = 0;

	for (usz event_index = 0; event_index < event_count; event_index++) {
		usz start = 1 + event_index * 6;
		long opcode = values[start];
		long element_id = values[start + 1];
		long key = values[start + 2];
		if (values[start + 3] != 0 || values[start + 4] != 0 || values[start + 5] != 0) return -1;
		long status = 1, result_id = 0, result_key = 0;

		if (opcode == 0) {
			if (element_id < 0 || element_id >= MAX_ACTIVE || key < -2147483648 || key > 2147483647 ||
				positions[(usz)element_id] >= 0 || size >= MAX_ACTIVE || key_in_use(heap_ids, heap_keys, size, key, -1)) return -1;
			heap_ids[size] = element_id;
			heap_keys[size] = key;
			positions[(usz)element_id] = (int)size;
			size++;
			(void)sift_up(heap_ids, heap_keys, positions, size - 1);
		} else if (opcode == 1 || opcode == 2) {
			if (element_id != 0 || key != 0) return -1;
			if (size == 0) status = 0;
			else {
				result_id = heap_ids[0];
				result_key = heap_keys[0];
				if (opcode == 2) remove_at(&size, heap_ids, heap_keys, positions, 0);
			}
		} else if (opcode == 3 || opcode == 4) {
			if (element_id < 0 || element_id >= MAX_ACTIVE || key != 0) return -1;
			int position = positions[(usz)element_id];
			status = position >= 0 ? 1 : 0;
			if (opcode == 3 && position >= 0) remove_at(&size, heap_ids, heap_keys, positions, (usz)position);
		} else if (opcode >= 5 && opcode <= 7) {
			if (element_id < 0 || element_id >= MAX_ACTIVE || key < -2147483648 || key > 2147483647) return -1;
			int position = positions[(usz)element_id];
			if (position < 0) return -1;
			long old_key = heap_keys[(usz)position];
			if ((opcode == 6 && key >= old_key) || (opcode == 7 && key <= old_key) ||
				key_in_use(heap_ids, heap_keys, size, key, element_id)) return -1;
			heap_keys[(usz)position] = key;
			if (opcode == 6) (void)sift_up(heap_ids, heap_keys, positions, (usz)position);
			else if (opcode == 7) sift_down(heap_ids, heap_keys, positions, size, (usz)position);
			else if (!sift_up(heap_ids, heap_keys, positions, (usz)position)) sift_down(heap_ids, heap_keys, positions, size, (usz)position);
		} else if (opcode == 8 || opcode == 9 || opcode == 10) {
			if (element_id != 0 || key != 0) return -1;
			if (opcode == 8) {
				for (usz index = 0; index < size; index++) positions[(usz)heap_ids[index]] = -1;
				size = 0;
			} else if (opcode == 9) result_id = (long)size;
			else result_id = size == 0 ? 1 : 0;
		} else return -1;

		usz record = event_index * 6;
		records[record] = status;
		records[record + 1] = result_id;
		records[record + 2] = result_key;
		records[record + 3] = (long)size;
		records[record + 4] = size == 0 ? 0 : heap_ids[0];
		records[record + 5] = size == 0 ? 0 : heap_keys[0];
	}

	usz required = event_count * 48;
	if (output == null || output_capacity < required) return -2;
	for (usz event = 0; event < event_count; event++)
		for (usz field = 0; field < 6; field++) store_i64_le(output, event * 48 + field * 8, records[event * 6 + field]);
	return (long)required;
}
