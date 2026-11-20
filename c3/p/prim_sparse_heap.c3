module prim_sparse_heap;

const usz MAX_VERTICES = 64, MAX_EDGES = 4096, MAX_ARCS = 2 * MAX_EDGES;
const usz NONE = MAX_VERTICES, NO_ARC = MAX_ARCS;

fn bool before(long[MAX_VERTICES]* best, usz left, usz right) {
	return best[left] < best[right] || (best[left] == best[right] && left < right);
}

fn void exchange(usz[MAX_VERTICES]* heap, usz[MAX_VERTICES]* position, usz first, usz second) {
	usz saved = heap[first];
	heap[first] = heap[second];
	heap[second] = saved;
	position[heap[first]] = first;
	position[heap[second]] = second;
}

fn void sift_up(usz[MAX_VERTICES]* heap, usz[MAX_VERTICES]* position,
		long[MAX_VERTICES]* best, usz at) {
	while (at > 0) {
		usz parent = (at - 1) / 2;
		if (!before(best, heap[at], heap[parent])) break;
		exchange(heap, position, at, parent);
		at = parent;
	}
}

fn usz pop_min(usz[MAX_VERTICES]* heap, usz[MAX_VERTICES]* position,
		usz* count, long[MAX_VERTICES]* best) {
	usz result = heap[0];
	position[result] = NONE;
	(*count)--;
	if (*count > 0) {
		heap[0] = heap[*count];
		position[heap[0]] = 0;
		usz at = 0;
		while (2 * at + 1 < *count) {
			usz child = 2 * at + 1;
			if (child + 1 < *count && before(best, heap[child + 1], heap[child])) child++;
			if (!before(best, heap[child], heap[at])) break;
			exchange(heap, position, at, child);
			at = child;
		}
	}
	return result;
}

fn long prim_sparse_heap(long* values, usz length) @export("prim_sparse_heap") {
	if (values == null || length < 2 || length > 12290) return -2;
	if (values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 4096) return -2;
	usz vertices = (usz)values[0], edge_count = (usz)values[1];
	if (length != 2 + 3 * edge_count || (vertices == 0 && edge_count != 0)) return -2;
	if (vertices == 0) return 0;
	for (usz edge = 0; edge < edge_count; edge++) {
		long origin = values[2 + 3 * edge], destination = values[3 + 3 * edge], weight = values[4 + 3 * edge];
		if (origin < 0 || destination < 0 || (ulong)origin >= vertices || (ulong)destination >= vertices || weight < 0 || weight > 2147483647) return -2;
	}

	usz[MAX_VERTICES] head = {};
	usz[MAX_ARCS] next = {}, to = {};
	long[MAX_ARCS] arc_weight = {};
	for (usz vertex = 0; vertex < vertices; vertex++) head[vertex] = NO_ARC;
	usz arc_count = 0;
	for (usz edge = 0; edge < edge_count; edge++) {
		usz origin = (usz)values[2 + 3 * edge], destination = (usz)values[3 + 3 * edge];
		long weight = values[4 + 3 * edge];
		if (origin == destination) continue;
		to[arc_count] = destination; arc_weight[arc_count] = weight;
		next[arc_count] = head[origin]; head[origin] = arc_count; arc_count++;
		to[arc_count] = origin; arc_weight[arc_count] = weight;
		next[arc_count] = head[destination]; head[destination] = arc_count; arc_count++;
	}

	long[MAX_VERTICES] best = {};
	bool[MAX_VERTICES] has_best = {}, selected = {};
	usz[MAX_VERTICES] heap = {}, position = {};
	for (usz vertex = 0; vertex < vertices; vertex++) position[vertex] = NONE;
	usz heap_count = 1, selected_count = 0;
	heap[0] = 0; position[0] = 0; has_best[0] = true;
	long total = 0;
	while (heap_count > 0) {
		usz origin = pop_min(&heap, &position, &heap_count, &best);
		selected[origin] = true; selected_count++; total += best[origin];
		for (usz arc = head[origin]; arc != NO_ARC; arc = next[arc]) {
			usz destination = to[arc];
			if (selected[destination] || (has_best[destination] && arc_weight[arc] >= best[destination])) continue;
			best[destination] = arc_weight[arc]; has_best[destination] = true;
			if (position[destination] == NONE) {
				heap[heap_count] = destination; position[destination] = heap_count; heap_count++;
			}
			sift_up(&heap, &position, &best, position[destination]);
		}
	}
	return selected_count == vertices ? total : -1;
}
