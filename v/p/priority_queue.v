const max_ops = 64
const max_input = 130
const max_output = 256

@[export: 'priority_queue']
pub fn priority_queue(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || input_length == 0 || input_length > max_input { return -1 }
        if input[0] < 0 || input[0] > max_ops { return -1 }
        op_count := int(input[0])
        mut heap := [max_ops]i32{}
        mut seen := [max_ops]i32{}
        mut staged := [max_output]u8{}
        mut heap_size := 0
        mut seen_count := 0
        mut offset := 1
        mut output_size := 0
        for _ in 0 .. op_count {
            if usize(offset) >= input_length { return -1 }
            op := input[offset]
            offset++
            if op == 0 {
                if usize(offset) >= input_length { return -1 }
                raw := input[offset]
                offset++
                if raw < -2147483648 || raw > 2147483647 { return -1 }
                value := i32(raw)
                for j in 0 .. seen_count { if seen[j] == value { return -1 } }
                seen[seen_count] = value
                seen_count++
                mut i := heap_size
                heap_size++
                heap[i] = value
                for i > 0 {
                    parent := (i - 1) / 2
                    if heap[parent] <= heap[i] { break }
                    temp := heap[parent]
                    heap[parent] = heap[i]
                    heap[i] = temp
                    i = parent
                }
            } else if op == 1 || op == 2 {
                if heap_size == 0 { return -1 }
                bits := u32(heap[0])
                staged[output_size] = u8(bits & 0xff); output_size++
                staged[output_size] = u8((bits >> 8) & 0xff); output_size++
                staged[output_size] = u8((bits >> 16) & 0xff); output_size++
                staged[output_size] = u8((bits >> 24) & 0xff); output_size++
                if op == 2 {
                    heap_size--
                    heap[0] = heap[heap_size]
                    mut i := 0
                    for i < heap_size {
                        mut child := 2 * i + 1
                        if child >= heap_size { break }
                        if child + 1 < heap_size && heap[child + 1] < heap[child] { child++ }
                        if heap[i] <= heap[child] { break }
                        temp := heap[i]
                        heap[i] = heap[child]
                        heap[child] = temp
                        i = child
                    }
                }
            } else {
                return -1
            }
        }
        if usize(offset) != input_length { return -1 }
        if output == nil || capacity < output_size { return -2 }
        for i in 0 .. output_size { output[i] = staged[i] }
        return i64(output_size)
    }
}
