package trie_multiple_search

import "core:c"

MAX_OPERATIONS :: 64
MAX_WORD_LENGTH :: 32
MAX_WORDS :: 32
MAX_NODES :: 1 + MAX_WORDS * MAX_WORD_LENGTH
MAX_VALID_INPUT_LENGTH :: c.size_t(2177)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(2178)
FNV_OFFSET :: u64(14695981039346656037)
FNV_PRIME :: u64(1099511628211)

Node :: struct { children: [26]int, word_index_plus_one: int }
Word :: struct { bytes: [MAX_WORD_LENGTH]u8, length: int, frequency: u32 }

hash_byte :: proc "contextless" (hash: ^u64, byte: u8) {
	hash^ = (hash^ ^ u64(byte)) * FNV_PRIME
}

hash_u16 :: proc "contextless" (hash: ^u64, value: u16) {
	for shift in 0 ..< 2 { hash_byte(hash, u8((value >> (shift * 8)) & 255)) }
}

hash_u32 :: proc "contextless" (hash: ^u64, value: u32) {
	for shift in 0 ..< 4 { hash_byte(hash, u8((value >> (shift * 8)) & 255)) }
}

word_less :: proc "contextless" (words: [^]Word, left, right: int) -> bool {
	a, b := words[left], words[right]
	for index in 0 ..< min(a.length, b.length) {
		if a.bytes[index] != b.bytes[index] { return a.bytes[index] < b.bytes[index] }
	}
	return a.length < b.length
}

@(export)
trie_multiple_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	if length > MAX_VALID_INPUT_LENGTH || input[0] < 0 || input[0] > MAX_OPERATIONS do return -1
	operation_count := int(input[0])
	var nodes: [MAX_NODES]Node
	node_count := 1
	var words: [MAX_WORDS]Word
	word_count := 0
	hash := FNV_OFFSET
	hash_u16(&hash, u16(operation_count))
	offset := 1

	for _ in 0 ..< operation_count {
		if offset + 2 > int(length) do return -1
		opcode_value, word_length_value := input[offset], input[offset+1]
		offset += 2
		if opcode_value < 0 || opcode_value > 3 || word_length_value < 0 || word_length_value > MAX_WORD_LENGTH do return -1
		opcode, word_length := int(opcode_value), int(word_length_value)
		if opcode == 0 && word_length == 0 do return -1
		if offset + word_length > int(length) do return -1
		var raw: [MAX_WORD_LENGTH]u8
		var folded: [MAX_WORD_LENGTH]u8
		for index in 0 ..< word_length {
			byte := input[offset+index]
			if byte >= 65 && byte <= 90 {
				raw[index] = u8(byte)
				folded[index] = u8(byte + 32)
			} else if byte >= 97 && byte <= 122 {
				raw[index] = u8(byte)
				folded[index] = u8(byte)
			} else { return -1 }
		}
		offset += word_length
		hash_byte(&hash, u8(opcode))

		mut node := 0
		mut matched := 0
		for index in 0 ..< word_length {
			letter := int(folded[index] - u8('a'))
			child := nodes[node].children[letter]
			if child == 0 { break }
			node = child
			matched += 1
		}
		if opcode == 0 {
			mut insert_node := 0
			for index in 0 ..< word_length {
				letter := int(folded[index] - u8('a'))
				child := nodes[insert_node].children[letter]
				if child == 0 {
					if node_count >= MAX_NODES do return -1
					child = node_count
					node_count += 1
					nodes[insert_node].children[letter] = child
				}
				insert_node = child
			}
			if nodes[insert_node].word_index_plus_one == 0 {
				if word_count >= MAX_WORDS do return -1
				words[word_count].bytes = folded
				words[word_count].length = word_length
				nodes[insert_node].word_index_plus_one = word_count + 1
				word_count += 1
			}
			continue
		}

		exact_index := -1
		if matched == word_length && nodes[node].word_index_plus_one != 0 { exact_index = nodes[node].word_index_plus_one - 1 }
		if opcode == 1 {
			present := exact_index >= 0
			if present { words[exact_index].frequency += 1 }
			if present { hash_byte(&hash, 1) } else { hash_byte(&hash, 0) }
			continue
		}

		var suggestions: [MAX_WORDS]int
		suggestion_count := 0
		for word_index in 0 ..< word_count {
			word := words[word_index]
			if word.length > matched {
				starts := true
				for index in 0 ..< matched { if word.bytes[index] != folded[index] { starts = false; break } }
				if starts { suggestions[suggestion_count] = word_index; suggestion_count += 1 }
			}
		}
		if exact_index >= 0 { words[exact_index].frequency += 1 }
		for i in 1 ..< suggestion_count {
			current := suggestions[i]
			mut j := i
			for j > 0 {
				previous := suggestions[j-1]
				mut before := word_less(&words[0], current, previous)
				if opcode == 3 {
					before = words[current].frequency > words[previous].frequency || (words[current].frequency == words[previous].frequency && word_less(&words[0], previous, current))
				}
				if !before { break }
				suggestions[j] = previous
				j -= 1
			}
			suggestions[j] = current
		}
		limit := suggestion_count
		if opcode == 3 && limit > 3 { limit = 3 }
		result_count := limit
		if exact_index >= 0 { result_count += 1 }
		hash_u16(&hash, u16(result_count))
		if exact_index >= 0 {
			hash_byte(&hash, u8(word_length))
			for index in 0 ..< word_length { hash_byte(&hash, raw[index]) }
		}
		for i in 0 ..< limit {
			word := words[suggestions[i]]
			hash_byte(&hash, u8(word.length))
			for index in 0 ..< word.length { hash_byte(&hash, word.bytes[index]) }
		}
	}
	if offset != int(length) do return -1
	hash_u16(&hash, u16(word_count))
	var order: [MAX_WORDS]int
	for index in 0 ..< word_count { order[index] = index }
	for i in 1 ..< word_count {
		current := order[i]
		mut j := i
		for j > 0 && word_less(&words[0], current, order[j-1]) { order[j] = order[j-1]; j -= 1 }
		order[j] = current
	}
	for order_index in 0 ..< word_count {
		word := words[order[order_index]]
		hash_byte(&hash, u8(word.length))
		for index in 0 ..< word.length { hash_byte(&hash, word.bytes[index]) }
		hash_u32(&hash, word.frequency)
	}
	return i64(hash & 0x7fffffffffffffff)
}
