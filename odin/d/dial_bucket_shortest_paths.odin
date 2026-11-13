package dial_bucket_shortest_paths

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_RECORDS :: 65
MAX_DISTANCE :: i64(120)
BUCKETS :: 9
MAX_OUTPUT :: 128

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 do output[offset + byte] = u8(bits >> (8 * byte))
}

@(export)
dial_bucket_shortest_paths :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 196 do return -1
	n64, m64, source64 := input[0], input[1], input[2]
	if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
		source64 < 0 || source64 >= n64 do return -1
	n, m, source := int(n64), int(m64), int(source64)
	if int(length) != 3 + 3 * m do return -1

	edge_to: [MAX_M]int = {}
	edge_next: [MAX_M]int = {}
	edge_weight: [MAX_M]i64 = {}
	edge_head: [MAX_N]int = {}
	for vertex := 0; vertex < n; vertex += 1 do edge_head[vertex] = MAX_M
	for edge := 0; edge < m; edge += 1 {
		u, v, w := input[3 + 3 * edge], input[4 + 3 * edge], input[5 + 3 * edge]
		if u < 0 || u >= n64 || v < 0 || v >= n64 || w < 0 || w > 8 do return -1
		from := int(u)
		edge_to[edge] = int(v)
		edge_weight[edge] = w
		edge_next[edge] = edge_head[from]
		edge_head[from] = edge
	}
	needed := 8 * n
	if output == nil || capacity < c.size_t(needed) do return -2

	distance: [MAX_N]i64 = {}
	settled: [MAX_N]bool = {}
	for vertex := 0; vertex < n; vertex += 1 do distance[vertex] = MAX_DISTANCE + 1
	distance[source] = 0
	bucket_head: [BUCKETS]int = {}
	bucket_tail: [BUCKETS]int = {}
	for bucket := 0; bucket < BUCKETS; bucket += 1 {
		bucket_head[bucket] = MAX_RECORDS
		bucket_tail[bucket] = MAX_RECORDS
	}
	record_vertex: [MAX_RECORDS]int = {}
	record_next: [MAX_RECORDS]int = {}
	record_distance: [MAX_RECORDS]i64 = {}
	record_vertex[0], record_distance[0], record_next[0] = source, 0, MAX_RECORDS
	bucket_head[0], bucket_tail[0] = 0, 0
	used := 1
	for current := 0; current <= int(MAX_DISTANCE); current += 1 {
		bucket := current % BUCKETS
		for bucket_head[bucket] != MAX_RECORDS {
			record := bucket_head[bucket]
			bucket_head[bucket] = record_next[record]
			if bucket_head[bucket] == MAX_RECORDS do bucket_tail[bucket] = MAX_RECORDS
			u := record_vertex[record]
			if record_distance[record] != i64(current) || settled[u] || distance[u] != i64(current) do continue
			settled[u] = true
			for edge := edge_head[u]; edge != MAX_M; edge = edge_next[edge] {
				v := edge_to[edge]
				candidate := i64(current) + edge_weight[edge]
				if !settled[v] && candidate < distance[v] {
					if used >= MAX_RECORDS do return -1
					distance[v] = candidate
					destination := int(candidate % i64(BUCKETS))
					record_vertex[used], record_distance[used] = v, candidate
					record_next[used] = MAX_RECORDS
					if bucket_tail[destination] == MAX_RECORDS do bucket_head[destination] = used
					else do record_next[bucket_tail[destination]] = used
					bucket_tail[destination] = used
					used += 1
				}
			}
		}
	}
	staged: [MAX_OUTPUT]u8 = {}
	for vertex := 0; vertex < n; vertex += 1 {
		value := distance[vertex]
		if value > MAX_DISTANCE do value = -1
		put_i64_le(&staged[0], 8 * vertex, value)
	}
	for byte := 0; byte < needed; byte += 1 do output[byte] = staged[byte]
	return i64(needed)
}

