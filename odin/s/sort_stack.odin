package sort_stack

import "core:c"

MAX_ITEMS :: 64

insert_sorted :: proc(stack: ^[MAX_ITEMS]i32, size: ^int, value: i32) {
    if size^ == 0 || value > stack[size^-1] {
        stack[size^] = value
        size^ += 1
        return
    }
    size^ -= 1
    top := stack[size^]
    insert_sorted(stack, size, value)
    stack[size^] = top
    size^ += 1
}

sort_recursively :: proc(stack: ^[MAX_ITEMS]i32, size: ^int) {
    if size^ == 0 do return
    size^ -= 1
    top := stack[size^]
    sort_recursively(stack, size)
    insert_sorted(stack, size, top)
}

@(export)
sort_stack :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 65 do return -1
    if input[0] < 0 || input[0] > MAX_ITEMS || length != c.size_t(1 + input[0]) do return -1
    count := int(input[0])
    var stack: [MAX_ITEMS]i32
    for i := 0; i < count; i += 1 {
        if input[i+1] < -2_147_483_648 || input[i+1] > 2_147_483_647 do return -1
        stack[i] = i32(input[i+1])
    }
    size := count
    sort_recursively(&stack, &size)
    bytes := size * 4
    if output == nil || output_capacity < c.size_t(bytes) do return -2
    for i := 0; i < size; i += 1 {
        bits := transmute(u32)stack[i]
        for b := 0; b < 4; b += 1 { output[4*i+b] = u8((bits >> u32(8*b)) & 255) }
    }
    return i64(bytes)
}
