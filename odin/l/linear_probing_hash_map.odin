package linear_probing_hash_map

import "core:c"

MAX_OPS :: 32
MAX_CAPACITY :: 128
MAX_WORDS :: 320

Hash_Map :: struct {
    keys: [MAX_CAPACITY]i32,
    values: [MAX_CAPACITY]i32,
    occupied: [MAX_CAPACITY]bool,
    capacity, size: c.size_t,
}

hash_index :: proc(key: i32, capacity: c.size_t) -> c.size_t {
    return c.size_t((u32(key) & 0x7fffffff) % u32(capacity))
}

resize_map :: proc(map: ^Hash_Map, new_capacity: c.size_t) {
    old_keys, old_values, old_occupied := map.keys, map.values, map.occupied
    old_capacity := map.capacity
    map.capacity = new_capacity
    for i: c.size_t = 0; i < new_capacity; i += 1 { map.occupied[i] = false }
    for i: c.size_t = 0; i < old_capacity; i += 1 {
        if !old_occupied[i] do continue
        index := hash_index(old_keys[i], new_capacity)
        for map.occupied[index] { index = (index + 1) % new_capacity }
        map.keys[index], map.values[index], map.occupied[index] = old_keys[i], old_values[i], true
    }
}

find_slot :: proc(map: ^Hash_Map, key: i32) -> c.size_t {
    index := hash_index(key, map.capacity)
    for probe: c.size_t = 0; probe < map.capacity; probe += 1 {
        if !map.occupied[index] do return map.capacity
        if map.keys[index] == key do return index
        index = (index + 1) % map.capacity
    }
    return map.capacity
}

put :: proc(map: ^Hash_Map, key, value: i32) {
    if map.size > map.capacity / 2 do resize_map(map, map.capacity * 2)
    index := hash_index(key, map.capacity)
    for map.occupied[index] {
        if map.keys[index] == key { map.values[index] = value; return }
        index = (index + 1) % map.capacity
    }
    map.keys[index], map.values[index], map.occupied[index] = key, value, true
    map.size += 1
}

delete_key :: proc(map: ^Hash_Map, key: i32) -> bool {
    index := find_slot(map, key)
    if index == map.capacity do return false
    map.occupied[index], map.values[index] = false, 0
    index = (index + 1) % map.capacity
    for map.occupied[index] {
        key_to_rehash, value_to_rehash := map.keys[index], map.values[index]
        map.occupied[index], map.values[index] = false, 0
        map.size -= 1
        put(map, key_to_rehash, value_to_rehash)
        index = (index + 1) % map.capacity
    }
    map.size -= 1
    if map.size > 0 && map.size <= map.capacity / 8 do resize_map(map, map.capacity / 2)
    return true
}

append :: proc(words: [^]i64, count: ^c.size_t, value: i64) {
    words[count^] = value
    count^ += 1
}

@(export)
linear_probing_hash_map :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 98 do return -1
    if input[0] < 4 || input[0] > 16 || input[1] < 0 || input[1] > MAX_OPS do return -1
    op_count := c.size_t(input[1])
    if length > 2 + 3 * op_count do return -1
    var map: Hash_Map
    map.capacity = c.size_t(input[0])
    map.size = 0
    for i: c.size_t = 0; i < MAX_CAPACITY; i += 1 { map.occupied[i] = false }
    words: [MAX_WORDS]i64
    word_count, pos: c.size_t = 0, 2
    for opi: c.size_t = 0; opi < op_count; opi += 1 {
        if pos >= length do return -1
        op := input[pos]
        pos += 1
        if op == 0 {
            if pos + 1 >= length do return -1
            key, value := input[pos], input[pos+1]
            pos += 2
            if key < -2_147_483_648 || key > 2_147_483_647 || value < -2_147_483_648 || value > 2_147_483_647 do return -1
            put(&map, i32(key), i32(value))
            append(&words[0], &word_count, 0); append(&words[0], &word_count, 1)
        } else if op >= 1 && op <= 3 {
            if pos >= length do return -1
            key := input[pos]; pos += 1
            if key < -2_147_483_648 || key > 2_147_483_647 do return -1
            k := i32(key)
            index := find_slot(&map, k)
            if op == 1 {
                append(&words[0], &word_count, 1)
                if index == map.capacity { append(&words[0], &word_count, 1); append(&words[0], &word_count, 0) }
                else { append(&words[0], &word_count, 0); append(&words[0], &word_count, i64(map.values[index])) }
            } else if op == 2 {
                append(&words[0], &word_count, 2)
                append(&words[0], &word_count, i64(delete_key(&map, k)))
            } else {
                append(&words[0], &word_count, 3)
                append(&words[0], &word_count, i64(index != map.capacity))
            }
        } else if op == 4 {
            append(&words[0], &word_count, 4); append(&words[0], &word_count, i64(map.size))
        } else if op == 5 {
            sorted: [MAX_OPS]i32
            count: c.size_t = 0
            for i: c.size_t = 0; i < map.capacity; i += 1 { if map.occupied[i] { sorted[count] = map.keys[i]; count += 1 } }
            for i: c.size_t = 1; i < count; i += 1 {
                value := sorted[i]; j := i
                for j > 0 && sorted[j-1] > value { sorted[j] = sorted[j-1]; j -= 1 }
                sorted[j] = value
            }
            append(&words[0], &word_count, 5); append(&words[0], &word_count, i64(count))
            for i: c.size_t = 0; i < count; i += 1 { append(&words[0], &word_count, i64(sorted[i])) }
        } else { return -1 }
    }
    if pos != length || word_count > MAX_WORDS do return -1
    bytes := word_count * 8
    if output == nil || output_capacity < bytes do return -2
    for i: c.size_t = 0; i < word_count; i += 1 {
        bits := u64(words[i])
        for b: c.size_t = 0; b < 8; b += 1 { output[8*i+b] = u8(bits >> (8*b)) }
    }
    return i64(bytes)
}
