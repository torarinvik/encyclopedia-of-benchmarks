package linear_probing_sort

import "core:c"

MAX_LENGTH :: c.size_t(1024)

insertion_sort :: proc(values: [^]i64, length: c.size_t) {
	for index := c.size_t(1); index < length; index += 1 {
		key := values[index]
		position := index
		for position > 0 && values[position - 1] > key {
			values[position] = values[position - 1]
			position -= 1
		}
		values[position] = key
	}
}

@(export)
linear_probing_sort :: proc "c" (values: [^]i64, length: c.size_t) {
	if values == nil || length < 2 do return
	if length > MAX_LENGTH {
		insertion_sort(values, length)
		return
	}

	minimum := values[0]
	maximum := values[0]
	for index := c.size_t(0); index < length; index += 1 {
		if values[index] < 0 || values[index] > 255 {
			insertion_sort(values, length)
			return
		}
		if values[index] < minimum do minimum = values[index]
		if values[index] > maximum do maximum = values[index]
	}

	main_slots := c.size_t(256) * (length + 1) + 1
	table_length := main_slots + length
	table := make([]i64, int(table_length))
	defer delete(table)
	span := maximum - minimum
	for index := c.size_t(0); index < length; index += 1 {
		home := c.size_t(0)
		if span != 0 {
			home = c.size_t((values[index] - minimum) * i64(main_slots - 1) / span)
		}
		slot := home
		for table[int(slot)] != 0 { slot += 1 }
		table[int(slot)] = values[index] + 1
	}
	output := c.size_t(0)
	for slot := c.size_t(0); slot < table_length; slot += 1 {
		if table[int(slot)] != 0 {
			values[output] = table[int(slot)] - 1
			output += 1
		}
	}
}
