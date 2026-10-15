module find_triplets_with_0_sum_hashing

const max_items = 64
const max_triplets = 2048
const hash_capacity = 128
const bytes_per_triplet = 12

fn hash_slot(value i64) int {
	return int((value + 100000) * 37 % hash_capacity)
}

fn seen_contains(keys &i64, occupied &bool, value i64) bool {
	mut slot := hash_slot(value)
	unsafe {
		for _ in 0 .. hash_capacity {
			if !occupied[slot] { return false }
			if keys[slot] == value { return true }
			slot = (slot + 1) % hash_capacity
		}
	}
	return false
}

fn seen_add(keys &i64, occupied &bool, value i64) {
	mut slot := hash_slot(value)
	unsafe {
		for _ in 0 .. hash_capacity {
			if !occupied[slot] { keys[slot] = value; occupied[slot] = true; return }
			if keys[slot] == value { return }
			slot = (slot + 1) % hash_capacity
		}
	}
}

fn already_output(triples &i64, count int, a i64, b i64, c i64) bool {
	unsafe {
		for i in 0 .. count {
			if triples[i * 3] == a && triples[i * 3 + 1] == b && triples[i * 3 + 2] == c { return true }
		}
	}
	return false
}

fn write_i32_le(output &u8, offset int, value i64) {
	bits := u32(i32(value))
	unsafe { for byte in 0 .. 4 { output[offset + byte] = u8((bits >> u32(byte * 8)) & 255) } }
}

@[export: 'find_triplets_with_0_sum_hashing']
pub fn find_triplets_with_0_sum_hashing(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_items || (length > 0 && unsafe { input == nil }) { return -1 }
	unsafe { for i := usize(0); i < length; i++ { if input[i] < -100000 || input[i] > 100000 { return -1 } } }
	mut triples := [max_triplets * 3]i64{}
	mut count := 0
	unsafe {
		for i := 0; i + 2 < int(length); i++ {
			mut keys := [hash_capacity]i64{}
			mut occupied := [hash_capacity]bool{}
			for j := i + 1; j < int(length); j++ {
				other := input[j]
				required := -input[i] - other
				if required >= -100000 && required <= 100000 && seen_contains(&keys[0], &occupied[0], required) {
					mut a := input[i]
					mut b := other
					mut c := required
					if a > b { t := a; a = b; b = t }
					if b > c { t := b; b = c; c = t }
					if a > b { t := a; a = b; b = t }
					if !already_output(&triples[0], count, a, b, c) && count < max_triplets {
						triples[count * 3] = a; triples[count * 3 + 1] = b; triples[count * 3 + 2] = c
						count++
					}
				}
				seen_add(&keys[0], &occupied[0], other)
			}
		}
	}
	if count == 0 { return 0 }
	needed := usize(count * bytes_per_triplet)
	if unsafe { output == nil } || output_capacity < needed { return -2 }
	unsafe { for i := 0; i < count * 3; i++ { write_i32_le(output, i * 4, triples[i]) } }
	return i64(count)
}
