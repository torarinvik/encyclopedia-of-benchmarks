package tower_of_hanoi

import "core:c"

emit_hanoi :: proc "contextless" (disks: c.size_t, source, destination, auxiliary: u8,
        output: [^]u8, position: c.size_t) -> c.size_t {
    if disks == 0 do return position
    after_first := emit_hanoi(disks - 1, source, auxiliary, destination, output, position)
    output[after_first] = source
    output[after_first + 1] = destination
    return emit_hanoi(disks - 1, auxiliary, destination, source, output, after_first + 2)
}

@(export)
tower_of_hanoi :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length != 4 || values[0] < 0 || values[0] > 12 do return -1
    for index: c.size_t = 1; index < 4; index += 1 {
        if values[index] < 0 || values[index] > 2 do return -1
    }
    if values[1] == values[2] || values[1] == values[3] || values[2] == values[3] do return -1
    disks := c.size_t(values[0])
    move_count := (c.size_t(1) << disks) - 1
    required := move_count * 2
    if output_capacity < required || (required != 0 && output == nil) do return -2
    _ = emit_hanoi(disks, u8(values[1]), u8(values[2]), u8(values[3]), output, 0)
    return i64(move_count)
}
