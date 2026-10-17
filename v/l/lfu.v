module lfu

const max_capacity = 16
const max_operations = 32
const max_input_length = 2 + 3 * max_operations
const max_output_words = 3 * max_operations

struct CacheTrace {
	mut:
	keys   [max_capacity]i32
	values [max_capacity]i32
	size   int
	capacity int
}

fn move_to_front(mut cache CacheTrace, index int) {
	key := cache.keys[index]
	value := cache.values[index]
	mut i := index
	for i > 0 {
		cache.keys[i] = cache.keys[i - 1]
		cache.values[i] = cache.values[i - 1]
		i--
	}
	cache.keys[0] = key
	cache.values[0] = value
}

fn append_word(mut words [max_output_words]i64, mut count int, value i64) {
	words[count] = value
	count++
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & u64(255)) }
	}
}

@[export: 'lfu']
pub fn lfu(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(max_input_length) { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > 16 || input[1] < 0 || input[1] > 32 { return -1 }
		mut cache := CacheTrace{capacity: int(input[0])}
		mut words := [max_output_words]i64{}
		mut word_count := 0
		mut position := 2
		for _ in 0 .. int(input[1]) {
			if position >= int(length) { return -1 }
			opcode := input[position]
			position++
			if opcode == 0 {
				if position + 1 >= int(length) { return -1 }
				key_arg := input[position]
				value_arg := input[position + 1]
				position += 2
				if key_arg < -2147483648 || key_arg > 2147483647 || value_arg < -2147483648 || value_arg > 2147483647 { return -1 }
				key := i32(key_arg)
				mut index := 0
				for index < cache.size && cache.keys[index] != key { index++ }
				if index < cache.size {
					// The pinned Put mutates a copied item; the old value remains.
					move_to_front(mut cache, index)
				} else {
					if cache.size == cache.capacity { cache.size-- }
					mut i := cache.size
					for i > 0 {
						cache.keys[i] = cache.keys[i - 1]
						cache.values[i] = cache.values[i - 1]
						i--
					}
					cache.keys[0] = key
					cache.values[0] = i32(value_arg)
					cache.size++
				}
				append_word(mut words, mut word_count, 0)
			} else if opcode == 1 {
				if position >= int(length) { return -1 }
				key_arg := input[position]
				position++
				if key_arg < -2147483648 || key_arg > 2147483647 { return -1 }
				key := i32(key_arg)
				mut index := 0
				for index < cache.size && cache.keys[index] != key { index++ }
				append_word(mut words, mut word_count, 1)
				if index == cache.size {
					append_word(mut words, mut word_count, 1)
					append_word(mut words, mut word_count, 0)
				} else {
					value := cache.values[index]
					move_to_front(mut cache, index)
					append_word(mut words, mut word_count, 0)
					append_word(mut words, mut word_count, i64(value))
				}
			} else { return -1 }
		}
		if position != int(length) || word_count > max_output_words { return -1 }
		bytes := word_count * 8
		if output == nil || output_capacity < usize(bytes) { return -2 }
		for i in 0 .. word_count { put_i64_le(mut output, i * 8, words[i]) }
		return i64(bytes)
	}
}
