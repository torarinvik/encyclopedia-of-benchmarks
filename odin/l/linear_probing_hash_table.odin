package linear_probing_hash_table

import "core:c"

MAX_TABLE_CAPACITY :: 128
MAX_OPERATIONS :: 32
MAX_INPUT_LENGTH :: 66
MAX_OUTPUT_WORDS :: 1088
MAX_KEY :: 2_147_483_520

find_slot :: proc(table: ^[MAX_TABLE_CAPACITY]i32, capacity: int, key: i32) -> int {
    index := int(key) % capacity
    for _ := 0; _ < capacity; _ += 1 {
        if table[index] == 0 do return -1
        if table[index] == key do return index
        index = (index + 1) % capacity
    }
    return -1
}

insertion_slot :: proc(table: ^[MAX_TABLE_CAPACITY]i32, capacity: int, key: i32) -> int {
    index := int(key) % capacity
    for _ := 0; _ < capacity; _ += 1 {
        if table[index] == 0 || table[index] == -1 do return index
        index = (index + 1) % capacity
    }
    return -1
}

rehash :: proc(table: ^[MAX_TABLE_CAPACITY]i32, capacity: ^int) {
    old_table: [MAX_TABLE_CAPACITY]i32
    old_capacity := capacity^
    for i := 0; i < old_capacity; i += 1 { old_table[i] = table[i] }
    capacity^ *= 2
    for i := 0; i < capacity^; i += 1 { table[i] = 0 }
    for i := 0; i < old_capacity; i += 1 {
        key := old_table[i]
        if key <= 0 do continue
        slot := insertion_slot(table, capacity^, key)
        if slot >= 0 do table[slot] = key
    }
}

@(export)
linear_probing_hash_table :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
    if input[0] < 2 || input[0] > 16 || input[1] < 0 || input[1] > MAX_OPERATIONS do return -1
    table_capacity := int(input[0])
    operation_count := int(input[1])
    var table: [MAX_TABLE_CAPACITY]i32
    size := 0
    var words: [MAX_OUTPUT_WORDS]i64
    word_count: c.size_t = 0
    position: c.size_t = 2
    for _ in 0..<operation_count {
        if position >= length do return -1
        opcode := input[position]
        position += 1
        if opcode >= 0 && opcode <= 3 {
            if position >= length do return -1
            key_arg := input[position]
            position += 1
            if key_arg < 1 || key_arg > MAX_KEY do return -1
            key := i32(key_arg)
            if opcode == 0 {
                slot := insertion_slot(&table, table_capacity, key)
                if slot < 0 do return -1
                table[slot] = key
                size += 1
                words[word_count] = 0; words[word_count+1] = 1; word_count += 2
                if size * 2 >= table_capacity do rehash(&table, &table_capacity)
            } else if opcode == 1 {
                slot := find_slot(&table, table_capacity, key)
                if slot < 0 do return -1
                table[slot] = -1
                size -= 1
                words[word_count] = 1; words[word_count+1] = 1; word_count += 2
            } else if opcode == 2 {
                words[word_count] = 2
                words[word_count+1] = i64(find_slot(&table, table_capacity, key) >= 0)
                word_count += 2
            } else {
                words[word_count] = 3; words[word_count+1] = key_arg; word_count += 2
            }
        } else if opcode == 4 {
            words[word_count] = 4; words[word_count+1] = i64(table_capacity); word_count += 2
            for i := 0; i < table_capacity; i += 1 {
                words[word_count] = if table[i] == 0 do -2 else i64(table[i])
                word_count += 1
            }
        } else do return -1
    }
    if position != length || word_count > MAX_OUTPUT_WORDS do return -1
    bytes := word_count * 8
    if output == nil || output_capacity < bytes do return -2
    for i: c.size_t = 0; i < word_count; i += 1 {
        bits := transmute(u64)words[i]
        for b := 0; b < 8; b += 1 { output[8*int(i)+b] = u8((bits >> u64(8*b)) & 255) }
    }
    return i64(bytes)
}
