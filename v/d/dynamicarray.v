module dynamicarray

fn write_word(output &u8, word int, value i64) {
    mut bits := u64(value)
    for byte in 0 .. 8 {
        unsafe { output[word * 8 + byte] = u8(bits & 255) }
        bits >>= 8
    }
}

@[export: 'dynamicarray']
pub fn dynamicarray(input &i64, length usize, output &u8, output_capacity usize) i64 {
    if length < 1 || length > 385 { return -1 }
    operation_count := unsafe { input[0] }
    if operation_count < 0 || operation_count > 128 { return -1 }
    mut a := [64]i64{init: 0}
    mut b := [64]i64{init: 0}
    mut queries := [128]i64{init: 0}
    mut size := 0
    mut capacity := 0
    mut cursor := 1
    mut query_count := 0
    mut active := 0
    for _ in 0 .. int(operation_count) {
        if cursor >= int(length) { return -1 }
        op := unsafe { input[cursor] }
        cursor++
        if op == 0 {
            if cursor >= int(length) || size >= 64 { return -1 }
            if size == capacity {
                if active == 0 {
                    for i in 0 .. size { b[i] = a[i] }
                    active = 1
                } else {
                    for i in 0 .. size { a[i] = b[i] }
                    active = 0
                }
                capacity = if capacity == 0 { 10 } else { capacity * 2 }
            }
            value := unsafe { input[cursor] }
            if active == 0 { a[size] = value } else { b[size] = value }
            size++
            cursor++
        } else if op == 1 {
            if cursor + 1 >= int(length) { return -1 }
            index := unsafe { input[cursor] }
            value := unsafe { input[cursor + 1] }
            cursor += 2
            if index < 0 || index >= i64(size) { return -1 }
            if active == 0 { a[int(index)] = value } else { b[int(index)] = value }
        } else if op == 2 || op == 3 {
            if cursor >= int(length) { return -1 }
            index := unsafe { input[cursor] }
            cursor++
            if index < 0 || index >= i64(size) { return -1 }
            at := int(index)
            if op == 2 {
                if query_count >= 128 { return -1 }
                queries[query_count] = if active == 0 { a[at] } else { b[at] }
                query_count++
            } else {
                if active == 0 { for i := at; i + 1 < size; i++ { a[i] = a[i + 1] } }
                else { for i := at; i + 1 < size; i++ { b[i] = b[i + 1] } }
                size--
            }
        } else if op >= 4 && op <= 6 {
            if query_count >= 128 { return -1 }
            queries[query_count] = if op == 4 { i64(size) } else if op == 5 { i64(capacity) } else { if size == 0 { i64(1) } else { i64(0) } }
            query_count++
        } else { return -1 }
    }
    if cursor != int(length) { return -1 }
    words := 3 + query_count + size
    if output_capacity < usize(words * 8) { return -2 }
    write_word(output, 0, i64(query_count))
    for i in 0 .. query_count { write_word(output, i + 1, queries[i]) }
    write_word(output, query_count + 1, i64(size))
    write_word(output, query_count + 2, i64(capacity))
    for i in 0 .. size { write_word(output, query_count + 3 + i, if active == 0 { a[i] } else { b[i] }) }
    return i64(words)
}
