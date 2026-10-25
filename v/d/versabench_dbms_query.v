module versabench_dbms_query

const max_nodes = 7
const max_entries = 4
const max_records = 16

struct QueryEntry { lo [4]i64; hi [4]i64; reference i64 }
struct QueryNode { level i64; count int; entries [max_entries]QueryEntry }

fn valid_box(lo [4]i64, hi [4]i64) bool {
	for d in 0 .. 4 { if lo[d] < -8 || lo[d] > 8 || hi[d] < -8 || hi[d] > 8 || lo[d] >= hi[d] { return false } }
	return true
}
fn intersects(e QueryEntry, lo [4]i64, hi [4]i64) bool {
	for d in 0 .. 4 { if lo[d] > e.hi[d] || e.lo[d] > hi[d] { return false } }
	return true
}
fn write_i64(output &u8, word int, value i64) {
	bits := u64(value)
	for b in 0 .. 8 { unsafe { output[word*8+b] = u8((bits >> u64(8*b)) & 255) } }
}

@[export: 'versabench_dbms_query']
pub fn versabench_dbms_query(input &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 10 || length > 277 { return -1 }
		nn := input[0]; rootv := input[1]
		if nn < 1 || nn > max_nodes || rootv < 0 || rootv >= nn { return -1 }
		n := int(nn); root := int(rootv)
		mut qlo := [4]i64{}; mut qhi := [4]i64{}
		for d in 0 .. 4 { qlo[d] = input[2+d]; qhi[d] = input[6+d] }
		if !valid_box(qlo,qhi) { return -1 }
		mut nodes := [max_nodes]QueryNode{}
		mut parents := [max_nodes]int{}
		mut seen := [32]bool{}
		mut leaf_total := 0; mut pos := 10
		for ni in 0 .. n {
			if pos+2 > int(length) { return -1 }
			level := input[pos]; countv := input[pos+1]; pos += 2
			if level < 0 || level > 2 || countv < 1 || countv > max_entries || pos + int(countv)*9 > int(length) { return -1 }
			count := int(countv); nodes[ni].level = level; nodes[ni].count = count
			for ei in 0 .. count {
				mut e := QueryEntry{}
				for d in 0 .. 4 { e.lo[d] = input[pos+d] }; pos += 4
				for d in 0 .. 4 { e.hi[d] = input[pos+d] }; pos += 4
				e.reference = input[pos]; pos++
				if !valid_box(e.lo,e.hi) { return -1 }
				if level == 0 {
					if e.reference < 0 || e.reference >= 32 || seen[int(e.reference)] || leaf_total >= max_records { return -1 }
					seen[int(e.reference)] = true; leaf_total++
				} else {
					if e.reference < 0 || e.reference >= nn { return -1 }
					parents[int(e.reference)]++
					if parents[int(e.reference)] > 1 { return -1 }
				}
				nodes[ni].entries[ei] = e
			}
		}
		if pos != int(length) || parents[root] != 0 { return -1 }
		for ni in 0 .. n {
			if ni != root && parents[ni] != 1 { return -1 }
			if nodes[ni].level == 0 { continue }
			for ei in 0 .. nodes[ni].count {
				branch := nodes[ni].entries[ei]; child := nodes[int(branch.reference)]
				if child.level != nodes[ni].level - 1 { return -1 }
				for ce in 0 .. child.count { for d in 0 .. 4 { if branch.lo[d] > child.entries[ce].lo[d] || branch.hi[d] < child.entries[ce].hi[d] { return -1 } } }
			}
		}
		mut stack := [max_nodes]int{}; mut top := 1; stack[0] = root
		mut hits := [max_records]i64{}; mut hit_count := 0
		for top > 0 {
			top--; ni := stack[top]; node := nodes[ni]
			if node.level == 0 {
				for ei in 0 .. node.count { e := node.entries[ei]; if intersects(e,qlo,qhi) { hits[hit_count] = e.reference; hit_count++ } }
			} else {
				mut rev := node.count
				for rev > 0 { rev--; e := node.entries[rev]; if intersects(e,qlo,qhi) { stack[top] = int(e.reference); top++ } }
			}
		}
		bytes := hit_count * 8
		if output == nil || output_capacity < usize(bytes) { return -2 }
		for i in 0 .. hit_count { write_i64(output,i,hits[i]) }
		return i64(bytes)
	}
}
