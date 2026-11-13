module dial_bucket_shortest_paths

const max_n = 16
const max_m = 64
const max_records = max_m + 1
const max_distance = i64(120)
const buckets = 9
const max_output = 128

fn put_i64_le(mut output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'dial_bucket_shortest_paths']
pub fn dial_bucket_shortest_paths(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 3 || length > 196 { return -1 }
	unsafe {
		n64, m64, source64 := input[0], input[1], input[2]
		if n64 < 1 || n64 > max_n || m64 < 0 || m64 > max_m ||
			source64 < 0 || source64 >= n64 { return -1 }
		n, m, source := int(n64), int(m64), int(source64)
		if int(length) != 3 + 3 * m { return -1 }
		mut edge_to := [max_m]int{}
		mut edge_next := [max_m]int{}
		mut edge_weight := [max_m]i64{}
		mut edge_head := [max_n]int{}
		for vertex in 0 .. n { edge_head[vertex] = max_m }
		for edge in 0 .. m {
			u, v, w := input[3 + 3 * edge], input[4 + 3 * edge], input[5 + 3 * edge]
			if u < 0 || u >= n64 || v < 0 || v >= n64 || w < 0 || w > 8 { return -1 }
			from := int(u)
			edge_to[edge] = int(v)
			edge_weight[edge] = w
			edge_next[edge] = edge_head[from]
			edge_head[from] = edge
		}
		needed := 8 * n
		if output == nil || capacity < usize(needed) { return -2 }
		mut distance := [max_n]i64{}
		mut settled := [max_n]bool{}
		for vertex in 0 .. n { distance[vertex] = max_distance + 1 }
		distance[source] = 0
		mut bucket_head := [buckets]int{}
		mut bucket_tail := [buckets]int{}
		for bucket in 0 .. buckets {
			bucket_head[bucket] = max_records
			bucket_tail[bucket] = max_records
		}
		mut record_vertex := [max_records]int{}
		mut record_next := [max_records]int{}
		mut record_distance := [max_records]i64{}
		record_vertex[0], record_distance[0], record_next[0] = source, 0, max_records
		bucket_head[0], bucket_tail[0] = 0, 0
		mut used := 1
		for current in 0 .. int(max_distance + 1) {
			bucket := current % buckets
			for bucket_head[bucket] != max_records {
				record := bucket_head[bucket]
				bucket_head[bucket] = record_next[record]
				if bucket_head[bucket] == max_records { bucket_tail[bucket] = max_records }
				u := record_vertex[record]
				if record_distance[record] != i64(current) || settled[u] || distance[u] != i64(current) { continue }
				settled[u] = true
				mut edge := edge_head[u]
				for edge != max_m {
					v := edge_to[edge]
					candidate := i64(current) + edge_weight[edge]
					if !settled[v] && candidate < distance[v] {
						if used >= max_records { return -1 }
						distance[v] = candidate
						destination := int(candidate % i64(buckets))
						record_vertex[used], record_distance[used], record_next[used] = v, candidate, max_records
						if bucket_tail[destination] == max_records { bucket_head[destination] = used }
						else { record_next[bucket_tail[destination]] = used }
						bucket_tail[destination] = used
						used++
					}
					edge = edge_next[edge]
				}
			}
		}
		mut staged := [max_output]u8{}
		for vertex in 0 .. n {
			value := if distance[vertex] > max_distance { i64(-1) } else { distance[vertex] }
			put_i64_le(mut staged[0], 8 * vertex, value)
		}
		for byte in 0 .. needed { output[byte] = staged[byte] }
		return i64(needed)
	}
}

