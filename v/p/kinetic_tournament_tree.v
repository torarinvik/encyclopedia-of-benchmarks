module kinetic_tournament_tree

const ktt_n = 8
const ktt_m = 32
const ktt_base = 8
const ktt_input_max = 2 + 2 * ktt_n + 4 * ktt_m
const ktt_inf = i64(1) << 60

struct KttNode {
	valid bool
	winner int
	best i64
	lazy i64
	deadline i64
}
struct KttOp { kind i64; left i64; right i64; delta i64 }

fn ktt_min(a i64, b i64) i64 { return if a < b { a } else { b } }

fn ktt_pull(mut tree [2 * ktt_base]KttNode, node int, slope [ktt_n]i64) {
	l, r := 2 * node, 2 * node + 1
	if !tree[l].valid && !tree[r].valid { tree[node].valid = false; tree[node].deadline = ktt_inf; return }
	if !tree[l].valid || !tree[r].valid {
		child := if tree[r].valid { r } else { l }
		tree[node].valid = true; tree[node].winner = tree[child].winner; tree[node].best = tree[child].best; tree[node].deadline = tree[child].deadline; return
	}
	li, ri := tree[l].winner, tree[r].winner
	choose_left := tree[l].best > tree[r].best || (tree[l].best == tree[r].best && slope[li] > slope[ri])
	win := if choose_left { l } else { r }
	lose := if choose_left { r } else { l }
	wi, lo := tree[win].winner, tree[lose].winner
	mut crossing := ktt_inf
	if slope[wi] < slope[lo] {
		gap, sg := tree[win].best - tree[lose].best, slope[lo] - slope[wi]
		crossing = if gap <= 0 { 0 } else { (gap + sg - 1) / sg }
	}
	tree[node].valid = true; tree[node].winner = wi; tree[node].best = tree[win].best
	tree[node].deadline = ktt_min(crossing, ktt_min(tree[l].deadline, tree[r].deadline))
}
fn ktt_apply(mut tree [2 * ktt_base]KttNode, node int, slope [ktt_n]i64, delta i64) {
	if !tree[node].valid { return }
	tree[node].best += slope[tree[node].winner] * delta; tree[node].lazy += delta; tree[node].deadline -= delta
}
fn ktt_push(mut tree [2 * ktt_base]KttNode, node int, slope [ktt_n]i64) {
	delta := tree[node].lazy
	if delta == 0 || node >= ktt_base { return }
	ktt_apply(mut tree, 2 * node, slope, delta); ktt_apply(mut tree, 2 * node + 1, slope, delta); tree[node].lazy = 0
}
fn ktt_repair(mut tree [2 * ktt_base]KttNode, node int, slope [ktt_n]i64) {
	if node >= ktt_base || !tree[node].valid { return }
	ktt_push(mut tree, node, slope)
	if tree[2 * node].valid && tree[2 * node].deadline <= 0 { ktt_repair(mut tree, 2 * node, slope) }
	if tree[2 * node + 1].valid && tree[2 * node + 1].deadline <= 0 { ktt_repair(mut tree, 2 * node + 1, slope) }
	ktt_pull(mut tree, node, slope)
}
fn ktt_translate(mut tree [2 * ktt_base]KttNode, node int, lo int, hi int, ql int, qr int, delta i64, slope [ktt_n]i64) {
	if ql <= lo && hi <= qr { ktt_apply(mut tree, node, slope, delta); ktt_repair(mut tree, node, slope); return }
	ktt_push(mut tree, node, slope); mid := (lo + hi) / 2
	if ql < mid { ktt_translate(mut tree, 2 * node, lo, mid, ql, qr, delta, slope) }
	if mid < qr { ktt_translate(mut tree, 2 * node + 1, mid, hi, ql, qr, delta, slope) }
	ktt_pull(mut tree, node, slope)
}
fn ktt_query(mut tree [2 * ktt_base]KttNode, node int, lo int, hi int, ql int, qr int, slope [ktt_n]i64) i64 {
	if ql <= lo && hi <= qr { return tree[node].best }
	ktt_push(mut tree, node, slope); mid := (lo + hi) / 2
	mut answer := i64(-9223372036854775807 - 1)
	if ql < mid { answer = ktt_query(mut tree, 2 * node, lo, mid, ql, qr, slope) }
	if mid < qr { other := ktt_query(mut tree, 2 * node + 1, mid, hi, ql, qr, slope); if other > answer { answer = other } }
	ktt_pull(mut tree, node, slope); return answer
}
fn ktt_store(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'kinetic_tournament_tree']
pub fn kinetic_tournament_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > ktt_input_max { return -1 }
		nr, mr := input[0], input[1]
		if nr < 1 || nr > ktt_n || mr < 1 || mr > ktt_m { return -1 }
		n, m := int(nr), int(mr); mut cursor := 2
		mut slope, intercept := [ktt_n]i64{}, [ktt_n]i64{}
		for i in 0 .. n {
			if cursor + 2 > int(length) { return -1 }
			slope[i], intercept[i] = input[cursor], input[cursor + 1]; cursor += 2
			if slope[i] < -8 || slope[i] > 8 || intercept[i] < -64 || intercept[i] > 64 || (i > 0 && slope[i] <= slope[i - 1]) { return -1 }
		}
		mut operations := [ktt_m]KttOp{}
		mut query_count := 0
		for i in 0 .. m {
			if cursor >= int(length) { return -1 }
			kind := input[cursor]; cursor++
			if kind == 0 {
				if cursor + 3 > int(length) { return -1 }
				left, right, delta := input[cursor], input[cursor + 1], input[cursor + 2]; cursor += 3
				if left < 0 || left > right || right >= nr || delta < 1 || delta > 8 { return -1 }
				operations[i] = KttOp{kind: kind, left: left, right: right, delta: delta}
			} else if kind == 1 {
				if cursor + 2 > int(length) { return -1 }
				left, right := input[cursor], input[cursor + 1]; cursor += 2
				if left < 0 || left > right || right >= nr { return -1 }
				operations[i] = KttOp{kind: kind, left: left, right: right, delta: 0}; query_count++
			} else { return -1 }
		}
		if cursor != int(length) || query_count == 0 { return -1 }
		required := 8 * query_count
		if output == nil || capacity < usize(required) { return -2 }
		mut tree := [2 * ktt_base]KttNode{}
		for i in 0 .. 2 * ktt_base { tree[i].deadline = ktt_inf }
		for i in 0 .. n { node := ktt_base + i; tree[node].valid = true; tree[node].winner = i; tree[node].best = intercept[i] }
		for node := ktt_base - 1; node > 0; node-- { ktt_pull(mut tree, node, slope) }
		mut answers := [ktt_m]i64{}
		mut answer_count := 0
		for i in 0 .. m {
			op := operations[i]
			if op.kind == 0 { ktt_translate(mut tree, 1, 0, ktt_base, int(op.left), int(op.right) + 1, op.delta, slope) }
			else { answers[answer_count] = ktt_query(mut tree, 1, 0, ktt_base, int(op.left), int(op.right) + 1, slope); answer_count++ }
		}
		for i in 0 .. answer_count { ktt_store(mut output, 8 * i, answers[i]) }
		return i64(required)
	}
}
