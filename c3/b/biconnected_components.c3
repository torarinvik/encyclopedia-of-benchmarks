module biconnected_components;

import "core:c";

const usz MAX_N = 6;
const usz MAX_M = 10;
const usz MAX_ADJ = 20;
const usz MAX_BLOCKS = 16;
const usz MAX_OUTPUT_VALUES = 113;
const usz MAX_OUTPUT_BYTES = 904;
const usz MAX_INPUT_LENGTH = 22;

struct Context {
	usz n;
	usz m;
	usz[10] edge_left;
	usz[10] edge_right;
	usz[6] degree;
	usz[120] adjacent_vertex;
	usz[120] adjacent_edge;
	long[6] discovery;
	long[6] low;
	usz[10] edge_stack;
	usz stack_size;
	usz clock;
	usz[96] block_vertices;
	usz[16] block_size;
	usz block_count;
}

fn void append_block(Context* context, usz stop_edge) {
	bool[6] member = zeroed;
	while (context->stack_size != 0) {
		context->stack_size -= 1;
		usz edge = context->edge_stack[context->stack_size];
		member[context->edge_left[edge]] = true;
		member[context->edge_right[edge]] = true;
		if (edge == stop_edge) break;
	}
	usz block = context->block_count;
	context->block_count += 1;
	for (usz vertex = 0; vertex < context->n; vertex += 1) {
		if (member[vertex]) {
			context->block_vertices[block * MAX_N + context->block_size[block]] = vertex;
			context->block_size[block] += 1;
		}
	}
}

fn void visit(Context* context, usz vertex, usz parent_edge) {
	context->discovery[vertex] = (long)context->clock;
	context->low[vertex] = (long)context->clock;
	context->clock += 1;
	for (usz slot = 0; slot < context->degree[vertex]; slot += 1) {
		usz index = vertex * MAX_ADJ + slot;
		usz neighbor = context->adjacent_vertex[index];
		usz edge = context->adjacent_edge[index];
		if (edge == parent_edge) continue;
		if (context->discovery[neighbor] < 0) {
			context->edge_stack[context->stack_size] = edge;
			context->stack_size += 1;
			visit(context, neighbor, edge);
			if (context->low[neighbor] < context->low[vertex]) context->low[vertex] = context->low[neighbor];
			if (context->low[neighbor] >= context->discovery[vertex]) append_block(context, edge);
		} else if (context->discovery[neighbor] < context->discovery[vertex]) {
			context->edge_stack[context->stack_size] = edge;
			context->stack_size += 1;
			if (context->discovery[neighbor] < context->low[vertex]) context->low[vertex] = context->discovery[neighbor];
		}
	}
}

fn bool block_less(Context* context, usz left, usz right) {
	usz common = context->block_size[left] < context->block_size[right]
		? context->block_size[left] : context->block_size[right];
	for (usz i = 0; i < common; i += 1) {
		usz a = context->block_vertices[left * MAX_N + i];
		usz b = context->block_vertices[right * MAX_N + i];
		if (a != b) return a < b;
	}
	return context->block_size[left] < context->block_size[right];
}

fn void store_u64_le(uint8* output, usz offset, ulong value) {
	for (usz byte = 0; byte < 8; byte += 1)
		output[offset + byte] = (uint8)((value >> (byte * 8)) & 255);
}

long biconnected_components(long* input, usz length, uint8* output,
		usz output_capacity) @export("biconnected_components") {
	if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
	long n_value = input[0], m_value = input[1];
	if (n_value < 1 || n_value > 6 || m_value < 0 || m_value > 10) return -1;
	usz n = (usz)n_value, m = (usz)m_value;
	if (length != 2 + 2 * m) return -1;

	Context context = {};
	context.n = n;
	context.m = m;
	for (usz vertex = 0; vertex < n; vertex += 1) context.discovery[vertex] = -1;
	for (usz edge = 0; edge < m; edge += 1) {
		long left_value = input[2 + 2 * edge], right_value = input[3 + 2 * edge];
		if (left_value < 0 || left_value >= n_value || right_value < 0 ||
			right_value >= n_value || left_value == right_value) return -1;
		usz left = (usz)left_value, right = (usz)right_value;
		context.edge_left[edge] = left;
		context.edge_right[edge] = right;
		usz left_slot = context.degree[left], right_slot = context.degree[right];
		context.degree[left] += 1;
		context.degree[right] += 1;
		context.adjacent_vertex[left * MAX_ADJ + left_slot] = right;
		context.adjacent_edge[left * MAX_ADJ + left_slot] = edge;
		context.adjacent_vertex[right * MAX_ADJ + right_slot] = left;
		context.adjacent_edge[right * MAX_ADJ + right_slot] = edge;
	}
	for (usz root = 0; root < n; root += 1) {
		if (context.discovery[root] >= 0) continue;
		visit(&context, root, MAX_M);
		if (context.degree[root] == 0) {
			usz block = context.block_count;
			context.block_count += 1;
			context.block_vertices[block * MAX_N] = root;
			context.block_size[block] = 1;
		}
	}

	usz[16] order;
	for (usz i = 0; i < context.block_count; i += 1) {
		usz position = i;
		order[i] = i;
		while (position > 0 && block_less(&context, order[position], order[position - 1])) {
			usz temporary = order[position];
			order[position] = order[position - 1];
			order[position - 1] = temporary;
			position -= 1;
		}
	}
	ulong[113] packed = zeroed;
	usz packed_count = 0;
	packed[packed_count] = context.block_count;
	packed_count += 1;
	for (usz i = 0; i < context.block_count; i += 1) {
		usz block = order[i];
		packed[packed_count] = context.block_size[block];
		packed_count += 1;
		for (usz j = 0; j < context.block_size[block]; j += 1) {
			packed[packed_count] = context.block_vertices[block * MAX_N + j];
			packed_count += 1;
		}
	}
	usz bytes = 8 * packed_count;
	if (output == null || output_capacity < bytes) return -2;
	uint8[MAX_OUTPUT_BYTES] staged = zeroed;
	for (usz i = 0; i < packed_count; i += 1) store_u64_le(&staged[0], 8 * i, packed[i]);
	for (usz i = 0; i < bytes; i += 1) output[i] = staged[i];
	return (long)bytes;
}
