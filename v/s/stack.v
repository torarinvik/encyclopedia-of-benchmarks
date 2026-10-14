module stack

// Bounded array-backed integer stack with a deterministic operation-trace checksum.
@[export: 'stack_benchmark']
pub fn stack_benchmark(values &i64, length usize) i64 {
    if length > 1024 || length % 2 != 0 { return -1 }
    operation_count := length / 2
    mut data_stack := [256]i64{init: 0}
    mut top := 0
    mut checksum := i64(0)
    for operation in 0 .. operation_count {
        opcode := unsafe { values[2 * operation] }
        payload := unsafe { values[2 * operation + 1] }
        mut observed := i64(0)
        mut returns_value := true
        if opcode == 0 {
            if payload < -1000000 || payload > 1000000 || top == 256 { return -1 }
            data_stack[top] = payload
            top++
            returns_value = false
        } else if opcode == 1 {
            if payload != 0 || top == 0 { return -1 }
            top--
            observed = data_stack[top]
        } else if opcode == 2 {
            if payload != 0 || top == 0 { return -1 }
            observed = data_stack[top - 1]
        } else if opcode == 3 {
            if payload != 0 { return -1 }
            if top == 0 { observed = 1 }
        } else {
            return -1
        }
        if returns_value { checksum += i64(operation + 1) * (observed + 1000000) }
    }
    for index in 0 .. top {
        checksum += i64(operation_count + index + 1) * (data_stack[index] + 1000000)
    }
    return checksum
}
