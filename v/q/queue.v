module queue

// Bounded ring-buffer queue with a deterministic operation-trace checksum.
@[export: 'queue_benchmark']
pub fn queue_benchmark(values &i64, length usize) i64 {
    if length > 1024 || length % 2 != 0 { return -1 }
    operation_count := length / 2
    mut data_queue := [256]i64{init: 0}
    mut head := 0
    mut count := 0
    mut checksum := i64(0)
    for operation in 0 .. operation_count {
        opcode := unsafe { values[2 * operation] }
        payload := unsafe { values[2 * operation + 1] }
        mut observed := i64(0)
        mut returns_value := true
        if opcode == 0 {
            if payload < -1000000 || payload > 1000000 || count == 256 { return -1 }
            data_queue[(head + count) % 256] = payload
            count++
            returns_value = false
        } else if opcode == 1 {
            if payload != 0 || count == 0 { return -1 }
            observed = data_queue[head]
            head = (head + 1) % 256
            count--
        } else if opcode == 2 {
            if payload != 0 || count == 0 { return -1 }
            observed = data_queue[head]
        } else if opcode == 3 {
            if payload != 0 || count == 0 { return -1 }
            observed = data_queue[(head + count - 1) % 256]
        } else if opcode == 4 {
            if payload != 0 { return -1 }
            if count == 0 { observed = 1 }
        } else if opcode == 5 {
            if payload != 0 { return -1 }
            observed = i64(count)
        } else { return -1 }
        if returns_value { checksum += i64(operation + 1) * (observed + 1000000) }
    }
    for index in 0 .. count {
        checksum += i64(operation_count + index + 1) * (data_queue[(head + index) % 256] + 1000000)
    }
    return checksum
}
