module external_quicksort;

const usz MAX_LENGTH = 1024;
const usz BUFFER_SIZE = 8;

fn void sort_buffer(long* buffer, usz length) {
    for (usz i = 1; i < length; i++) {
        long value = buffer[i];
        usz position = i;
        while (position > 0 && value < buffer[position - 1]) {
            buffer[position] = buffer[position - 1];
            position--;
        }
        buffer[position] = value;
    }
}

fn void sort_range(long* values, long first, long last) {
    while (last > first) {
        long read_low = first, write_low = first;
        long read_high = last, write_high = last;
        long[BUFFER_SIZE] buffer = {};
        usz buffered = 0;
        bool have_max_lower = false, have_min_upper = false;
        long max_lower = 0, min_upper = 0;
        long lower_written_bound = first - 1;
        long upper_written_bound = last + 1;

        while (read_high >= read_low) {
            long incoming;
            if (read_low - write_low < write_high - read_high)
                incoming = values[read_low++];
            else
                incoming = values[read_high--];

            if (buffered < BUFFER_SIZE) {
                buffer[buffered++] = incoming;
                sort_buffer(&buffer[0], buffered);
            } else if (incoming > buffer[BUFFER_SIZE - 1]) {
                if (have_min_upper && incoming > min_upper) upper_written_bound = write_high;
                else { min_upper = incoming; have_min_upper = true; }
                values[write_high--] = incoming;
            } else if (incoming < buffer[0]) {
                if (have_max_lower && incoming < max_lower) lower_written_bound = write_low;
                else { max_lower = incoming; have_max_lower = true; }
                values[write_low++] = incoming;
            } else if (write_low - first < last - write_high) {
                long outgoing = buffer[0];
                values[write_low++] = outgoing;
                max_lower = outgoing;
                have_max_lower = true;
                buffer[0] = incoming;
                sort_buffer(&buffer[0], BUFFER_SIZE);
            } else {
                long outgoing = buffer[BUFFER_SIZE - 1];
                values[write_high--] = outgoing;
                min_upper = outgoing;
                have_min_upper = true;
                buffer[BUFFER_SIZE - 1] = incoming;
                sort_buffer(&buffer[0], BUFFER_SIZE);
            }
        }

        while (buffered > 0) values[write_high--] = buffer[--buffered];
        if (lower_written_bound - first < last - upper_written_bound) {
            sort_range(values, first, lower_written_bound);
            first = upper_written_bound;
        } else {
            sort_range(values, upper_written_bound, last);
            last = lower_written_bound;
        }
    }
}

fn void external_quicksort(long* values, usz length) @export("external_quicksort") {
    if (length == 0 || length > MAX_LENGTH || values == null) return;
    sort_range(values, 0, (long)length - 1);
}
