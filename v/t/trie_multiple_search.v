module trie_multiple_search

const max_operations = 64
const max_word_length = 32
const max_words = 32
const max_nodes = 1 + max_words * max_word_length
const max_valid_input_length = 2177
const max_parseable_input_length = 2178
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

struct Trie_node {
	mut:
	children [26]int
	word_index_plus_one int
}

struct Stored_word {
	mut:
	bytes [max_word_length]u8
	length int
	frequency u32
}

fn hash_byte(mut hash u64, byte u8) u64 {
	return (hash ^ u64(byte)) * fnv_prime
}

fn hash_u16(mut hash u64, value u16) u64 {
	for shift in 0 .. 2 { hash = hash_byte(mut hash, u8((value >> u16(shift * 8)) & 255)) }
	return hash
}

fn hash_u32(mut hash u64, value u32) u64 {
	for shift in 0 .. 4 { hash = hash_byte(mut hash, u8((value >> u32(shift * 8)) & 255)) }
	return hash
}

@[export: 'trie_multiple_search']
pub fn trie_multiple_search(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		if length > usize(max_valid_input_length) || input[0] < 0 || input[0] > max_operations { return -1 }
		operation_count := int(input[0])
		mut nodes := [max_nodes]Trie_node{}
		mut node_count := 1
		mut words := [max_words]Stored_word{}
		mut word_count := 0
		mut hash := fnv_offset
		hash = hash_u16(mut hash, u16(operation_count))
		mut offset := 1
		for _ in 0 .. operation_count {
			if offset + 2 > int(length) { return -1 }
			opcode_value, word_length_value := input[offset], input[offset + 1]
			offset += 2
			if opcode_value < 0 || opcode_value > 3 || word_length_value < 0 || word_length_value > max_word_length { return -1 }
			opcode, word_length := int(opcode_value), int(word_length_value)
			if opcode == 0 && word_length == 0 { return -1 }
			if offset + word_length > int(length) { return -1 }
			mut raw := [max_word_length]u8{}
			mut folded := [max_word_length]u8{}
			for index in 0 .. word_length {
				byte := input[offset + index]
				if byte >= 65 && byte <= 90 {
					raw[index] = u8(byte)
					folded[index] = u8(byte + 32)
				} else if byte >= 97 && byte <= 122 {
					raw[index] = u8(byte)
					folded[index] = u8(byte)
				} else { return -1 }
			}
			offset += word_length
			hash = hash_byte(mut hash, u8(opcode))

			mut node := 0
			mut matched := 0
			for index in 0 .. word_length {
				letter := int(folded[index] - u8(`a`))
				child := nodes[node].children[letter]
				if child == 0 { break }
				node = child
				matched++
			}
			if opcode == 0 {
				mut insert_node := 0
				for index in 0 .. word_length {
					letter := int(folded[index] - u8(`a`))
					child := nodes[insert_node].children[letter]
					if child == 0 {
						if node_count >= max_nodes { return -1 }
						child = node_count
						node_count++
						nodes[insert_node].children[letter] = child
					}
					insert_node = child
				}
				if nodes[insert_node].word_index_plus_one == 0 {
					if word_count >= max_words { return -1 }
					words[word_count].bytes = folded
					words[word_count].length = word_length
					nodes[insert_node].word_index_plus_one = word_count + 1
					word_count++
				}
				continue
			}

			mut exact_index := -1
			if matched == word_length && nodes[node].word_index_plus_one != 0 { exact_index = nodes[node].word_index_plus_one - 1 }
			if opcode == 1 {
				present := exact_index >= 0
				if present { words[exact_index].frequency++ }
				if present { hash = hash_byte(mut hash, 1) } else { hash = hash_byte(mut hash, 0) }
				continue
			}

			mut suggestions := [max_words]int{}
			mut suggestion_count := 0
			for word_index in 0 .. word_count {
				word := words[word_index]
				if word.length > matched {
					mut starts := true
					for index in 0 .. matched { if word.bytes[index] != folded[index] { starts = false; break } }
					if starts { suggestions[suggestion_count] = word_index; suggestion_count++ }
				}
			}
			if exact_index >= 0 { words[exact_index].frequency++ }
			for i := 1; i < suggestion_count; i++ {
				current := suggestions[i]
				mut j := i
				for j > 0 {
					previous := suggestions[j - 1]
					mut before := false
					common := if words[current].length < words[previous].length { words[current].length } else { words[previous].length }
					if opcode == 2 {
						for k in 0 .. common {
							if words[current].bytes[k] != words[previous].bytes[k] { before = words[current].bytes[k] < words[previous].bytes[k]; break }
							if k == common - 1 { before = words[current].length < words[previous].length }
						}
					} else {
						before = words[current].frequency > words[previous].frequency
						if words[current].frequency == words[previous].frequency {
							for k in 0 .. common {
								if words[current].bytes[k] != words[previous].bytes[k] { before = words[current].bytes[k] > words[previous].bytes[k]; break }
								if k == common - 1 { before = words[current].length > words[previous].length }
							}
						}
					}
					if !before { break }
					suggestions[j] = previous
					j--
				}
				suggestions[j] = current
			}
			mut limit := suggestion_count
			if opcode == 3 && limit > 3 { limit = 3 }
			result_count := limit
			if exact_index >= 0 { result_count++ }
			hash = hash_u16(mut hash, u16(result_count))
			if exact_index >= 0 {
				hash = hash_byte(mut hash, u8(word_length))
				for index in 0 .. word_length { hash = hash_byte(mut hash, raw[index]) }
			}
			for i in 0 .. limit {
				word := words[suggestions[i]]
				hash = hash_byte(mut hash, u8(word.length))
				for index in 0 .. word.length { hash = hash_byte(mut hash, word.bytes[index]) }
			}
		}
		if offset != int(length) { return -1 }
		hash = hash_u16(mut hash, u16(word_count))
		mut order := [max_words]int{}
		for index in 0 .. word_count { order[index] = index }
		for i := 1; i < word_count; i++ {
			current := order[i]
			mut j := i
			for j > 0 {
				previous := order[j - 1]
				mut before := false
				common := if words[current].length < words[previous].length { words[current].length } else { words[previous].length }
				for k in 0 .. common {
					if words[current].bytes[k] != words[previous].bytes[k] { before = words[current].bytes[k] < words[previous].bytes[k]; break }
					if k == common - 1 { before = words[current].length < words[previous].length }
				}
				if !before { break }
				order[j] = previous
				j--
			}
			order[j] = current
		}
		for i in 0 .. word_count {
			word := words[order[i]]
			hash = hash_byte(mut hash, u8(word.length))
			for index in 0 .. word.length { hash = hash_byte(mut hash, word.bytes[index]) }
			hash = hash_u32(mut hash, word.frequency)
		}
		return i64(hash & u64(0x7fffffffffffffff))
	}
}
