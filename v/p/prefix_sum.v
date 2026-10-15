module prefix_sum

const max_length = 256
const hash_capacity = 1024

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}
fn hash_key(key i64) int {
	mut bucket := key % hash_capacity
	if bucket < 0 { bucket += hash_capacity }
	return int(bucket)
}
fn contains_sum(prefix &i64, count int, target i64) bool {
	mut keys := [hash_capacity]i64{init: 0}
	mut used := [hash_capacity]bool{init: false}
	mut slot := hash_key(0); keys[slot] = 0; used[slot] = true
	for ending in 1 .. (count + 1) {
		wanted := unsafe { prefix[ending] } - target; slot = hash_key(wanted)
		for used[slot] && keys[slot] != wanted { slot = (slot + 1) % hash_capacity }
		if used[slot] { return true }
		slot = hash_key(unsafe { prefix[ending] })
		for used[slot] && keys[slot] != unsafe { prefix[ending] } { slot = (slot + 1) % hash_capacity }
		if !used[slot] { used[slot] = true; keys[slot] = unsafe { prefix[ending] } }
	}
	return false
}

@[export: 'prefix_sum']
pub fn prefix_sum(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || unsafe { input[0] } < 0 || unsafe { input[0] } > 2 || unsafe { input[1] } < 0 || unsafe { input[1] } > max_length { return -1 }
	operation := int(unsafe { input[0] }); count := int(unsafe { input[1] }); extra := if operation == 1 { 2 } else if operation == 2 { 1 } else { 0 }
	if int(length) != 2 + count + extra || (operation == 1 && count == 0) { return -1 }
	for i in 0 .. count { value := unsafe { input[2+i] }; if value < -2147483648 || value > 2147483647 { return -1 } }
	if operation == 1 { left := unsafe { input[2+count] }; right := unsafe { input[3+count] }; if left < 0 || right < left || right >= i64(count) { return -1 } }
	if operation == 2 { target := unsafe { input[2+count] }; if target < -1000000000000 || target > 1000000000000 { return -1 } }
	mut prefix := [max_length + 1]i64{init: 0}
	for i in 0 .. count { prefix[i+1] = prefix[i] + unsafe { input[2+i] } }
	words := if operation == 0 { count } else { 1 }
	if output_capacity < usize(words * 8) { return -2 }
	if operation == 0 { for i in 0 .. count { store_i64_le(mut output, i*8, prefix[i+1]) }; return i64(count) }
	mut result := i64(0)
	if operation == 1 { result = prefix[int(unsafe { input[3+count] })+1] - prefix[int(unsafe { input[2+count] })] }
	else if contains_sum(prefix, count, unsafe { input[2+count] }) { result = 1 }
	store_i64_le(mut output, 0, result)
	return 1
}
