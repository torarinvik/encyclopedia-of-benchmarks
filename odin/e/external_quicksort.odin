package external_quicksort

import "core:c"

MAX_LENGTH :: 1024
BUFFER_SIZE :: 8

sort_buffer :: proc(buffer: [^]i64, length: int) {
	for i := 1; i < length; i += 1 {
		value := buffer[i]
		position := i
		for position > 0 && value < buffer[position - 1] {
			buffer[position] = buffer[position - 1]
			position -= 1
		}
		buffer[position] = value
	}
}

sort_range :: proc(values: [^]i64, first_arg, last_arg: int) {
	first, last := first_arg, last_arg
	for last > first {
		read_low, write_low := first, first
		read_high, write_high := last, last
		buffer: [BUFFER_SIZE]i64
		buffered := 0
		have_max_lower, have_min_upper := false, false
		max_lower, min_upper: i64 = 0, 0
		lower_written_bound, upper_written_bound := first - 1, last + 1

		for read_high >= read_low {
			incoming: i64
			if read_low - write_low < write_high - read_high {
				incoming = values[read_low]
				read_low += 1
			} else {
				incoming = values[read_high]
				read_high -= 1
			}

			if buffered < BUFFER_SIZE {
				buffer[buffered] = incoming
				buffered += 1
				sort_buffer(&buffer[0], buffered)
			} else if incoming > buffer[BUFFER_SIZE - 1] {
				if have_min_upper && incoming > min_upper { upper_written_bound = write_high }
				else { min_upper = incoming; have_min_upper = true }
				values[write_high] = incoming
				write_high -= 1
			} else if incoming < buffer[0] {
				if have_max_lower && incoming < max_lower { lower_written_bound = write_low }
				else { max_lower = incoming; have_max_lower = true }
				values[write_low] = incoming
				write_low += 1
			} else if write_low - first < last - write_high {
				outgoing := buffer[0]
				values[write_low] = outgoing
				write_low += 1
				max_lower, have_max_lower = outgoing, true
				buffer[0] = incoming
				sort_buffer(&buffer[0], BUFFER_SIZE)
			} else {
				outgoing := buffer[BUFFER_SIZE - 1]
				values[write_high] = outgoing
				write_high -= 1
				min_upper, have_min_upper = outgoing, true
				buffer[BUFFER_SIZE - 1] = incoming
				sort_buffer(&buffer[0], BUFFER_SIZE)
			}
		}

		for buffered > 0 {
			buffered -= 1
			values[write_high] = buffer[buffered]
			write_high -= 1
		}
		if lower_written_bound - first < last - upper_written_bound {
			sort_range(values, first, lower_written_bound)
			first = upper_written_bound
		} else {
			sort_range(values, upper_written_bound, last)
			last = lower_written_bound
		}
	}
}

@(export)
external_quicksort :: proc "c" (values: [^]i64, length: c.size_t) {
	if length == 0 || length > c.size_t(MAX_LENGTH) || values == nil do return
	sort_range(values, 0, int(length) - 1)
}
