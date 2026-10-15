module brute_force_caesar_cipher

const max_message_length = 64
const key_count = 26

@[export: 'brute_force_caesar_cipher']
pub fn brute_force_caesar_cipher(input &i64, length usize, output &u8, capacity usize) i64 {
	if length > max_message_length || (length > 0 && unsafe { input == nil }) { return -1 }
	unsafe { for i := usize(0); i < length; i++ { if input[i] < 0 || input[i] > 127 { return -1 } } }
	needed := length * key_count + (key_count - 1)
	if unsafe { output == nil } || capacity < needed { return -2 }
	mut position := usize(0)
	unsafe {
		for key := usize(0); key < key_count; key++ {
			for i := usize(0); i < length; i++ {
				mut value := input[i]
				if value >= 65 && value <= 90 { value = 65 + (value - 65 + 26 - i64(key)) % 26 }
				output[position] = u8(value)
				position++
			}
			if key + 1 < key_count { output[position] = 10; position++ }
		}
	}
	return i64(key_count)
}
