module extendible_hashing_trace

const key_count = 256
const max_ops = 40
const max_words = 82

struct Table {
	mut:
		directory [key_count]u8
		keys [key_count][2]u8
		counts [key_count]u8
		depths [key_count]u8
		active [key_count]bool
		gd int
		high int
		buckets int
		live int
}

fn new_table() Table {
	mut t := Table{gd: 1, high: 1, buckets: 2}
	t.directory[0] = 0; t.directory[1] = 1
	t.active[0] = true; t.active[1] = true
	t.depths[0] = 1; t.depths[1] = 1
	return t
}

fn (t Table) bucket_for(key int) int { return int(t.directory[key & ((1 << t.gd) - 1)]) }

fn (t Table) find_slot(bucket int, key int) int {
	for slot in 0 .. int(t.counts[bucket]) { if int(t.keys[bucket][slot]) == key { return slot } }
	return -1
}

fn (mut t Table) split(bucket int) bool {
	d := int(t.depths[bucket])
	if d >= 8 { return false }
	if d == t.gd {
		old_size := 1 << t.gd
		for i in 0 .. old_size { t.directory[i + old_size] = t.directory[i] }
		t.gd++
		if t.gd > t.high { t.high = t.gd }
	}
	mut fresh := 0
	for fresh < key_count && t.active[fresh] { fresh++ }
	if fresh == key_count { return false }
	t.active[fresh] = true; t.depths[bucket] = u8(d + 1); t.depths[fresh] = u8(d + 1)
	old_count := int(t.counts[bucket]); old_keys := t.keys[bucket]
	t.counts[bucket] = 0; t.counts[fresh] = 0
	t.keys[bucket] = [2]u8{}; t.keys[fresh] = [2]u8{}
	bit := 1 << d; size := 1 << t.gd
	for i in 0 .. size { if int(t.directory[i]) == bucket && (i & bit) != 0 { t.directory[i] = u8(fresh) } }
	for i in 0 .. old_count {
		key := int(old_keys[i]); target := if (key & bit) != 0 { fresh } else { bucket }
		t.keys[target][int(t.counts[target])] = old_keys[i]; t.counts[target]++
	}
	t.buckets++
	return true
}

fn (mut t Table) coalesce(start int) {
	mut bucket := start
	for int(t.depths[bucket]) > 1 {
		d := int(t.depths[bucket]); size := 1 << t.gd
		mut rep := -1
		for i in 0 .. size { if int(t.directory[i]) == bucket { rep = i; break } }
		if rep < 0 { break }
		prefix := rep & ((1 << d) - 1); buddy_prefix := prefix ^ (1 << (d - 1)); buddy := int(t.directory[buddy_prefix])
		if buddy == bucket || !t.active[buddy] || int(t.depths[buddy]) != d || int(t.counts[bucket]) + int(t.counts[buddy]) > 2 { break }
		mut keep := bucket; mut drop := buddy
		if buddy_prefix < prefix { keep = buddy; drop = bucket }
		keep_count := int(t.counts[keep]); drop_count := int(t.counts[drop])
		for j in 0 .. drop_count { t.keys[keep][keep_count+j] = t.keys[drop][j] }
		t.counts[keep] += t.counts[drop]; t.counts[drop] = 0; t.keys[drop] = [2]u8{}
		t.depths[keep] = u8(d - 1); t.active[drop] = false
		for i in 0 .. size { if int(t.directory[i]) == drop { t.directory[i] = u8(keep) } }
		t.buckets--; bucket = keep
	}
	for t.gd > 1 {
		half := 1 << (t.gd - 1); mut mirror := true
		for i in 0 .. half { if t.directory[i] != t.directory[i+half] { mirror = false; break } }
		if !mirror { break }
		t.gd--
	}
}

fn solve(values []i64) i64 {
	if values.len < 1 || values.len > max_words || values[0] < 0 || values[0] > max_ops { return -1 }
	q := int(values[0])
	if values.len != 1 + 2*q { return -1 }
	for i in 0 .. q { if values[1+2*i] < 0 || values[1+2*i] > 2 || values[2+2*i] < 0 || values[2+2*i] > 255 { return -1 } }
	mut t := new_table(); mut successes := u64(0)
	for i in 0 .. q {
		op := int(values[1+2*i]); key := int(values[2+2*i]); mut bucket := t.bucket_for(key); slot := t.find_slot(bucket, key); mut success := u64(0)
		if op == 0 && slot < 0 {
			for t.counts[bucket] == 2 { if !t.split(bucket) { break }; bucket = t.bucket_for(key) }
			if t.counts[bucket] < 2 { t.keys[bucket][int(t.counts[bucket])] = u8(key); t.counts[bucket]++; t.live++; success = 1 }
		} else if op == 1 && slot >= 0 {
			t.counts[bucket]--; t.keys[bucket][slot] = t.keys[bucket][int(t.counts[bucket])]; t.keys[bucket][int(t.counts[bucket])] = 0
			t.live--; success = 1; t.coalesce(bucket)
		} else if op == 2 { success = if slot >= 0 { u64(1) } else { u64(0) } }
		successes = (successes << 1) | success
	}
	return i64(successes | (u64(t.buckets) << 40) | (u64(t.gd) << 49) | (u64(t.high) << 53) | (u64(t.live) << 57))
}

@[export: 'extendible_hashing_trace']
pub fn extendible_hashing_trace(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_words { return -1 }
		mut frame := [max_words]i64{}
		for i in 0 .. length { frame[i] = input[i] }
		return solve(frame[..length])
	}
}
