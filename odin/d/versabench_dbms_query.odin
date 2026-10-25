package versabench_dbms_query
import "core:c"

MAX_NODES :: 7
MAX_ENTRIES :: 4
MAX_RECORDS :: 16
Entry :: struct { lo: [4]i64, hi: [4]i64, reference: i64 }
Node :: struct { level: i64, count: int, entries: [MAX_ENTRIES]Entry }

valid_box :: proc "contextless" (lo, hi: [4]i64) -> bool {
	for d := 0; d < 4; d += 1 { if lo[d] < -8 || lo[d] > 8 || hi[d] < -8 || hi[d] > 8 || lo[d] >= hi[d] do return false }
	return true
}
intersects :: proc "contextless" (e: Entry, lo, hi: [4]i64) -> bool {
	for d := 0; d < 4; d += 1 { if lo[d] > e.hi[d] || e.lo[d] > hi[d] do return false }
	return true
}
write_i64 :: proc "contextless" (output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { output[word*8+b] = u8((bits >> u64(8*b)) & 255) }
}

@(export, link_name="versabench_dbms_query")
versabench_dbms_query :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 10 || length > 277 do return -1
	nn := values[0]; rootv := values[1]
	if nn < 1 || nn > MAX_NODES || rootv < 0 || rootv >= nn do return -1
	n := int(nn); root := int(rootv)
	qlo: [4]i64; qhi: [4]i64
	for d := 0; d < 4; d += 1 { qlo[d] = values[2+d]; qhi[d] = values[6+d] }
	if !valid_box(qlo,qhi) do return -1
	nodes: [MAX_NODES]Node
	parents: [MAX_NODES]int
	seen: [32]bool
	leaf_total := 0
	pos := 10
	for ni := 0; ni < n; ni += 1 {
		if pos+2 > int(length) do return -1
		level := values[pos]; countv := values[pos+1]; pos += 2
		if level < 0 || level > 2 || countv < 1 || countv > MAX_ENTRIES || pos+int(countv)*9 > int(length) do return -1
		count := int(countv); nodes[ni].level = level; nodes[ni].count = count
		for ei := 0; ei < count; ei += 1 {
			entry: Entry
			for d := 0; d < 4; d += 1 { entry.lo[d] = values[pos+d] }; pos += 4
			for d := 0; d < 4; d += 1 { entry.hi[d] = values[pos+d] }; pos += 4
			entry.reference = values[pos]; pos += 1
			if !valid_box(entry.lo,entry.hi) do return -1
			if level == 0 {
				if entry.reference < 0 || entry.reference >= 32 || seen[int(entry.reference)] || leaf_total >= MAX_RECORDS do return -1
				seen[int(entry.reference)] = true; leaf_total += 1
			} else {
				if entry.reference < 0 || entry.reference >= nn do return -1
				parents[int(entry.reference)] += 1
				if parents[int(entry.reference)] > 1 do return -1
			}
			nodes[ni].entries[ei] = entry
		}
	}
	if pos != int(length) || parents[root] != 0 do return -1
	for ni := 0; ni < n; ni += 1 {
		if ni != root && parents[ni] != 1 do return -1
		if nodes[ni].level == 0 do continue
		for ei := 0; ei < nodes[ni].count; ei += 1 {
			branch := nodes[ni].entries[ei]
			child := nodes[int(branch.reference)]
			if child.level != nodes[ni].level-1 do return -1
			for ce := 0; ce < child.count; ce += 1 { for d := 0; d < 4; d += 1 { if branch.lo[d] > child.entries[ce].lo[d] || branch.hi[d] < child.entries[ce].hi[d] do return -1 } }
		}
	}
	stack: [MAX_NODES]int; top := 1; stack[0] = root
	hits: [MAX_RECORDS]i64; hit_count := 0
	for top > 0 {
		top -= 1; ni := stack[top]; node := nodes[ni]
		if node.level == 0 {
			for ei := 0; ei < node.count; ei += 1 { e := node.entries[ei]; if intersects(e,qlo,qhi) { hits[hit_count] = e.reference; hit_count += 1 } }
		} else {
			rev := node.count
			for rev > 0 { rev -= 1; e := node.entries[rev]; if intersects(e,qlo,qhi) { stack[top] = int(e.reference); top += 1 } }
		}
	}
	bytes := hit_count*8
	if output == nil || output_capacity < c.size_t(bytes) do return -2
	for i := 0; i < hit_count; i += 1 { write_i64(output,i,hits[i]) }
	return i64(bytes)
}
