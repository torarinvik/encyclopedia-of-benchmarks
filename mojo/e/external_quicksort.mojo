# Fixed-size sorted endpoint-buffer quicksort.
const MAX_LENGTH: Int = 1024
const BUFFER_SIZE: Int = 8

def sort_buffer(buffer: mutable view[i64], length: Int) -> None:
    var index = 1
    while index < length:
        let value = buffer[index]
        var position = index
        while position > 0 and value < buffer[position - 1]:
            buffer[position] = buffer[position - 1]
            position -= 1
        buffer[position] = value
        index += 1

def sort_range(values: mutable view[i64], first_arg: Int, last_arg: Int) -> None:
    var first = first_arg
    var last = last_arg
    while last > first:
        var read_low = first
        var write_low = first
        var read_high = last
        var write_high = last
        var buffer_storage: InlineArray[Int64, 8] = InlineArray[Int64, 8](fill=0)
        var buffer: mutable view[i64] = buffer_storage[0:BUFFER_SIZE]
        var buffered = 0
        var have_max_lower = False
        var have_min_upper = False
        var max_lower: i64 = 0
        var min_upper: i64 = 0
        var lower_written_bound = first - 1
        var upper_written_bound = last + 1

        while read_high >= read_low:
            var incoming: i64 = 0
            if read_low - write_low < write_high - read_high:
                incoming = values[read_low]
                read_low += 1
            else:
                incoming = values[read_high]
                read_high -= 1

            if buffered < BUFFER_SIZE:
                buffer[buffered] = incoming
                buffered += 1
                sort_buffer(buffer, buffered)
            elif incoming > buffer[BUFFER_SIZE - 1]:
                if have_min_upper and incoming > min_upper:
                    upper_written_bound = write_high
                else:
                    min_upper = incoming
                    have_min_upper = True
                values[write_high] = incoming
                write_high -= 1
            elif incoming < buffer[0]:
                if have_max_lower and incoming < max_lower:
                    lower_written_bound = write_low
                else:
                    max_lower = incoming
                    have_max_lower = True
                values[write_low] = incoming
                write_low += 1
            elif write_low - first < last - write_high:
                let outgoing = buffer[0]
                values[write_low] = outgoing
                write_low += 1
                max_lower = outgoing
                have_max_lower = True
                buffer[0] = incoming
                sort_buffer(buffer, BUFFER_SIZE)
            else:
                let outgoing = buffer[BUFFER_SIZE - 1]
                values[write_high] = outgoing
                write_high -= 1
                min_upper = outgoing
                have_min_upper = True
                buffer[BUFFER_SIZE - 1] = incoming
                sort_buffer(buffer, BUFFER_SIZE)

        while buffered > 0:
            buffered -= 1
            values[write_high] = buffer[buffered]
            write_high -= 1

        if lower_written_bound - first < last - upper_written_bound:
            sort_range(values, first, lower_written_bound)
            first = upper_written_bound
        else:
            sort_range(values, upper_written_bound, last)
            last = lower_written_bound

export fn external_quicksort(values: mutable i64&, length: usize) -> None:
    if length == 0 or length > MAX_LENGTH or values.is_null():
        return
    var view: mutable view[i64] = values[0:length]
    sort_range(view, 0, Int(length) - 1)
