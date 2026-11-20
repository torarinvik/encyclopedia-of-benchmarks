module external_quicksort

const max_length = 1024
const buffer_size = 8

fn sort_buffer(mut buffer [buffer_size]i64, length int) {
	for i in 1 .. length {
		value := buffer[i]
		mut position := i
		for position > 0 && value < buffer[position - 1] {
			buffer[position] = buffer[position - 1]
			position--
		}
		buffer[position] = value
	}
}

fn sort_range(mut values &i64, first_arg int, last_arg int) {
	mut first := first_arg
	mut last := last_arg
	for last > first {
		mut read_low := first
		mut write_low := first
		mut read_high := last
		mut write_high := last
		mut buffer := [buffer_size]i64{}
		mut buffered := 0
		mut have_max_lower := false
		mut have_min_upper := false
		mut max_lower := i64(0)
		mut min_upper := i64(0)
		mut lower_written_bound := first - 1
		mut upper_written_bound := last + 1

		for read_high >= read_low {
			mut incoming := i64(0)
			if read_low - write_low < write_high - read_high {
				unsafe { incoming = values[read_low] }
				read_low++
			} else {
				unsafe { incoming = values[read_high] }
				read_high--
			}

			if buffered < buffer_size {
				buffer[buffered] = incoming
				buffered++
				sort_buffer(mut buffer, buffered)
			} else if incoming > buffer[buffer_size - 1] {
				if have_min_upper && incoming > min_upper { upper_written_bound = write_high }
				else { min_upper = incoming; have_min_upper = true }
				unsafe { values[write_high] = incoming }
				write_high--
			} else if incoming < buffer[0] {
				if have_max_lower && incoming < max_lower { lower_written_bound = write_low }
				else { max_lower = incoming; have_max_lower = true }
				unsafe { values[write_low] = incoming }
				write_low++
			} else if write_low - first < last - write_high {
				outgoing := buffer[0]
				unsafe { values[write_low] = outgoing }
				write_low++
				max_lower = outgoing
				have_max_lower = true
				buffer[0] = incoming
				sort_buffer(mut buffer, buffer_size)
			} else {
				outgoing := buffer[buffer_size - 1]
				unsafe { values[write_high] = outgoing }
				write_high--
				min_upper = outgoing
				have_min_upper = true
				buffer[buffer_size - 1] = incoming
				sort_buffer(mut buffer, buffer_size)
			}
		}

		for buffered > 0 {
			buffered--
			unsafe { values[write_high] = buffer[buffered] }
			write_high--
		}
		if lower_written_bound - first < last - upper_written_bound {
			sort_range(mut values, first, lower_written_bound)
			first = upper_written_bound
		} else {
			sort_range(mut values, upper_written_bound, last)
			last = lower_written_bound
		}
	}
}

@[export: 'external_quicksort']
pub fn external_quicksort(mut values &i64, length usize) {
	if length == 0 || length > usize(max_length) || unsafe { values == nil } { return }
	sort_range(mut values, 0, int(length) - 1)
}
