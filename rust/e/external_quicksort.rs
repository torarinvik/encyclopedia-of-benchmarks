//! Fixed-size sorted endpoint buffer quicksort.

const MAX_LENGTH: usize = 1024;
const BUFFER_SIZE: usize = 8;

fn sort_buffer(buffer: &mut [i64; BUFFER_SIZE], length: usize) {
    for index in 1..length {
        let value = buffer[index];
        let mut position = index;
        while position > 0 && value < buffer[position - 1] {
            buffer[position] = buffer[position - 1];
            position -= 1;
        }
        buffer[position] = value;
    }
}

fn sort_range(values: &mut [i64], first_arg: isize, last_arg: isize) {
    let mut first = first_arg;
    let mut last = last_arg;
    while last > first {
        let (mut read_low, mut write_low) = (first, first);
        let (mut read_high, mut write_high) = (last, last);
        let mut buffer = [0_i64; BUFFER_SIZE];
        let mut buffered = 0;
        let (mut have_max_lower, mut have_min_upper) = (false, false);
        let (mut max_lower, mut min_upper) = (0_i64, 0_i64);
        let (mut lower_written_bound, mut upper_written_bound) = (first - 1, last + 1);

        while read_high >= read_low {
            let incoming;
            if read_low - write_low < write_high - read_high {
                incoming = values[read_low as usize];
                read_low += 1;
            } else {
                incoming = values[read_high as usize];
                read_high -= 1;
            }

            if buffered < BUFFER_SIZE {
                buffer[buffered] = incoming;
                buffered += 1;
                sort_buffer(&mut buffer, buffered);
            } else if incoming > buffer[BUFFER_SIZE - 1] {
                if have_min_upper && incoming > min_upper {
                    upper_written_bound = write_high;
                } else {
                    min_upper = incoming;
                    have_min_upper = true;
                }
                values[write_high as usize] = incoming;
                write_high -= 1;
            } else if incoming < buffer[0] {
                if have_max_lower && incoming < max_lower {
                    lower_written_bound = write_low;
                } else {
                    max_lower = incoming;
                    have_max_lower = true;
                }
                values[write_low as usize] = incoming;
                write_low += 1;
            } else if write_low - first < last - write_high {
                let outgoing = buffer[0];
                values[write_low as usize] = outgoing;
                write_low += 1;
                max_lower = outgoing;
                have_max_lower = true;
                buffer[0] = incoming;
                sort_buffer(&mut buffer, BUFFER_SIZE);
            } else {
                let outgoing = buffer[BUFFER_SIZE - 1];
                values[write_high as usize] = outgoing;
                write_high -= 1;
                min_upper = outgoing;
                have_min_upper = true;
                buffer[BUFFER_SIZE - 1] = incoming;
                sort_buffer(&mut buffer, BUFFER_SIZE);
            }
        }

        while buffered > 0 {
            buffered -= 1;
            values[write_high as usize] = buffer[buffered];
            write_high -= 1;
        }

        if lower_written_bound - first < last - upper_written_bound {
            sort_range(values, first, lower_written_bound);
            first = upper_written_bound;
        } else {
            sort_range(values, upper_written_bound, last);
            last = lower_written_bound;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn external_quicksort(values: *mut i64, length: usize) {
    if length == 0 || length > MAX_LENGTH || values.is_null() {
        return;
    }
    sort_range(std::slice::from_raw_parts_mut(values, length), 0, length as isize - 1);
}
