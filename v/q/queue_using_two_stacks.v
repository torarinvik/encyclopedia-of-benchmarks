module queue_using_two_stacks

// Amortized FIFO queue implemented with an input and an output stack.
@[export: 'queue_using_two_stacks_benchmark']
pub fn queue_using_two_stacks_benchmark(values &i64, length usize) i64 {
    if length > 1024 || length % 2 != 0 { return -1 }
    operation_count := length / 2
    mut in_stack := [256]i64{init: 0}
    mut out_stack := [256]i64{init: 0}
    mut in_count := 0
    mut out_count := 0
    mut checksum := i64(0)
    for operation in 0 .. operation_count {
        opcode := unsafe { values[2 * operation] }
        payload := unsafe { values[2 * operation + 1] }
        mut observed := i64(0)
        mut returns_value := true
        if opcode == 0 {
            if payload < -1000000 || payload > 1000000 || in_count + out_count == 256 { return -1 }
            in_stack[in_count] = payload
            in_count++
            returns_value = false
        } else if opcode == 1 || opcode == 2 {
            if payload != 0 { return -1 }
            if out_count == 0 {
                for in_count > 0 {
                    in_count--
                    out_stack[out_count] = in_stack[in_count]
                    out_count++
                }
            }
            if out_count == 0 { return -1 }
            if opcode == 1 {
                out_count--
                observed = out_stack[out_count]
            } else {
                observed = out_stack[out_count - 1]
            }
        } else if opcode == 3 {
            if payload != 0 { return -1 }
            if in_count + out_count == 0 { observed = 1 }
        } else if opcode == 4 {
            if payload != 0 { return -1 }
            observed = i64(in_count + out_count)
        } else { return -1 }
        if returns_value { checksum += i64(operation + 1) * (observed + 1000000) }
    }
    for index in 0 .. out_count {
        checksum += i64(operation_count + index + 1) * (out_stack[out_count - index - 1] + 1000000)
    }
    for index in 0 .. in_count {
        checksum += (i64(operation_count) + i64(out_count) + i64(index) + 1) * (in_stack[index] + 1000000)
    }
    return checksum
}
