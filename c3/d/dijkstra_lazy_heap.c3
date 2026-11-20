module dijkstra_lazy_heap;

const usz MAX_VERTICES = 64, MAX_EDGES = 256, MAX_HEAP = MAX_EDGES + 1;
const usz NONE = MAX_EDGES;

fn bool before(long left_distance, usz left_vertex, long right_distance, usz right_vertex) {
	return left_distance < right_distance || (left_distance == right_distance && left_vertex < right_vertex);
}

fn long dijkstra_lazy_heap(long* edges, usz vertices, usz edge_count, usz source,
		long* distances, char* reachable) @export("dijkstra_lazy_heap") {
	if (vertices > MAX_VERTICES || edge_count > MAX_EDGES) return -3;
	if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
	if (source >= vertices) return -3;
	for (usz edge = 0; edge < edge_count; edge++) {
		long origin = edges[3 * edge], destination = edges[3 * edge + 1], weight = edges[3 * edge + 2];
		if (origin < 0 || destination < 0 || (ulong)origin >= vertices || (ulong)destination >= vertices) return -3;
		if (weight < 0) return -4;
	}

	usz[MAX_VERTICES] head = {}, tail = {};
	usz[MAX_EDGES] next = {};
	for (usz vertex = 0; vertex < vertices; vertex++) head[vertex] = tail[vertex] = NONE;
	for (usz edge = 0; edge < edge_count; edge++) {
		usz origin = (usz)edges[3 * edge];
		next[edge] = NONE;
		if (head[origin] == NONE) head[origin] = edge;
		else next[tail[origin]] = edge;
		tail[origin] = edge;
	}

	for (usz vertex = 0; vertex < vertices; vertex++) {
		distances[vertex] = 0;
		reachable[vertex] = 0;
	}
	long[MAX_HEAP] heap_distance = {};
	usz[MAX_HEAP] heap_vertex = {};
	usz heap_count = 1;
	heap_distance[0] = 0;
	heap_vertex[0] = source;
	distances[source] = 0;
	reachable[source] = 1;

	while (heap_count > 0) {
		long current = heap_distance[0];
		usz origin = heap_vertex[0];
		heap_count--;
		if (heap_count > 0) {
			long last_distance = heap_distance[heap_count];
			usz last_vertex = heap_vertex[heap_count];
			usz position = 0;
			while (2 * position + 1 < heap_count) {
				usz child = 2 * position + 1;
				if (child + 1 < heap_count && before(heap_distance[child + 1], heap_vertex[child + 1], heap_distance[child], heap_vertex[child])) child++;
				if (!before(heap_distance[child], heap_vertex[child], last_distance, last_vertex)) break;
				heap_distance[position] = heap_distance[child];
				heap_vertex[position] = heap_vertex[child];
				position = child;
			}
			heap_distance[position] = last_distance;
			heap_vertex[position] = last_vertex;
		}
		if (current != distances[origin] || reachable[origin] == 2) continue;
		reachable[origin] = 2;
		for (usz edge = head[origin]; edge != NONE; edge = next[edge]) {
			usz destination = (usz)edges[3 * edge + 1];
			long weight = edges[3 * edge + 2];
			if (current > 9223372036854775807 - weight) return -2;
			long candidate = current + weight;
			if (reachable[destination] != 2 && (reachable[destination] == 0 || candidate < distances[destination])) {
				distances[destination] = candidate;
				reachable[destination] = 1;
				usz position = heap_count++;
				while (position > 0) {
					usz parent = (position - 1) / 2;
					if (!before(candidate, destination, heap_distance[parent], heap_vertex[parent])) break;
					heap_distance[position] = heap_distance[parent];
					heap_vertex[position] = heap_vertex[parent];
					position = parent;
				}
				heap_distance[position] = candidate;
				heap_vertex[position] = destination;
			}
		}
	}
	for (usz vertex = 0; vertex < vertices; vertex++) if (reachable[vertex] == 2) reachable[vertex] = 1;
	return 0;
}
