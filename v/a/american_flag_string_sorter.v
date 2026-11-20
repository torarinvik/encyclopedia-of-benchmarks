module american_flag_string_sorter

const max_strings = 256
const max_string_length = 32
const max_parseable = 8450
const bucket_count = 257

struct StringRecord {
	bytes [32]u8
	length int
}

fn symbol_at(records []StringRecord, record int, depth int) int {
	if depth == records[record].length { return 0 }
	return int(records[record].bytes[depth]) + 1
}

fn american_flag_sort(records []StringRecord, mut order []int, lo int, hi int, depth int) {
	if hi - lo < 2 { return }

	mut counts := [bucket_count]int{}
	for position in lo .. hi {
		counts[symbol_at(records, order[position], depth)]++
	}

	mut starts := [bucket_count + 1]int{}
	mut next := [bucket_count]int{}
	starts[0] = lo
	for bucket in 0 .. bucket_count {
		starts[bucket + 1] = starts[bucket] + counts[bucket]
		next[bucket] = starts[bucket]
	}

	for bucket in 0 .. bucket_count {
		for next[bucket] < starts[bucket + 1] {
			position := next[bucket]
			destination_bucket := symbol_at(records, order[position], depth)
			if destination_bucket == bucket {
				next[bucket]++
			} else {
				temporary := order[position]
				order[position] = order[next[destination_bucket]]
				order[next[destination_bucket]] = temporary
				next[destination_bucket]++
			}
		}
	}

	for bucket in 1 .. bucket_count {
		if counts[bucket] > 1 {
			american_flag_sort(records, mut order, starts[bucket], starts[bucket + 1], depth + 1)
		}
	}
}

@[export: 'american_flag_string_sorter']
pub fn american_flag_string_sorter(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable { return -1 }
		string_count_value := input[0]
		if string_count_value < 0 || string_count_value > max_strings { return -1 }
		string_count := int(string_count_value)

		mut records := []StringRecord{cap: string_count}
		mut position := 1
		for _ in 0 .. string_count {
			if position >= int(length) { return -1 }
			string_length_value := input[position]
			position++
			if string_length_value < 0 || string_length_value > max_string_length { return -1 }
			string_length := int(string_length_value)
			if string_length > int(length) - position { return -1 }
			mut record := StringRecord{}
			record.length = string_length
			for byte_index in 0 .. string_length {
				byte := input[position]
				position++
				if byte < 0 || byte > 255 { return -1 }
				record.bytes[byte_index] = u8(byte)
			}
			records << record
		}
		if position != int(length) { return -1 }

		mut order := []int{cap: string_count}
		for index in 0 .. string_count { order << index }
		american_flag_sort(records, mut order, 0, string_count, 0)

		mut checksum := i64(0)
		for rank in 0 .. string_count {
			record := records[order[rank]]
			mut contribution := i64(record.length + 1)
			for byte_index in 0 .. record.length {
				contribution += i64(record.bytes[byte_index]) + 1
			}
			checksum += i64(rank + 1) * contribution
		}
		return checksum
	}
}
