package longest_square_streak

import "core:c"

MAX_INPUT_LENGTH :: 100_000
MAX_VALUE :: 100_000
REQUIRED_WORKSPACE :: 4 * (MAX_VALUE + 1)

read_state :: proc "contextless" (workspace: [^]u8, value: int) -> i64 {
    position := 4 * value
    return i64(workspace[position]) | (i64(workspace[position + 1]) << 8) |
        (i64(workspace[position + 2]) << 16) | (i64(workspace[position + 3]) << 24)
}

write_state :: proc "contextless" (workspace: [^]u8, value: int, state: i64) {
    encoded := state
    if encoded < 0 do encoded += 4_294_967_296
    position := 4 * value
    workspace[position] = u8(encoded & 255)
    workspace[position + 1] = u8((encoded >> 8) & 255)
    workspace[position + 2] = u8((encoded >> 16) & 255)
    workspace[position + 3] = u8((encoded >> 24) & 255)
}

streak_from :: proc "contextless" (workspace: [^]u8, value: int) -> i64 {
    state := read_state(workspace, value)
    if state > 1 do return state - 1
    chain_length: i64 = 1
    square := i64(value) * i64(value)
    if square <= MAX_VALUE && read_state(workspace, int(square)) != 0 {
        chain_length += streak_from(workspace, int(square))
    }
    write_state(workspace, value, chain_length + 1)
    return chain_length
}

@(export)
longest_square_streak :: proc "c" (values: [^]i64, length: c.size_t,
        workspace: [^]u8, workspace_capacity: c.size_t) -> i64 {
    if values == nil || length < 3 || length > MAX_INPUT_LENGTH + 1 ||
        values[0] < 2 || values[0] > MAX_INPUT_LENGTH {
        return -1
    }
    count := int(values[0])
    if length != c.size_t(count + 1) do return -1
    for index := 0; index < count; index += 1 {
        if values[index + 1] < 2 || values[index + 1] > MAX_VALUE do return -1
    }
    if workspace == nil || workspace_capacity < REQUIRED_WORKSPACE do return -2
    for byte_index := 0; byte_index < REQUIRED_WORKSPACE; byte_index += 1 do workspace[byte_index] = 0
    for index := 0; index < count; index += 1 do write_state(workspace, int(values[index + 1]), 1)
    longest: i64 = 1
    for index := 0; index < count; index += 1 {
        found := streak_from(workspace, int(values[index + 1]))
        if found > longest do longest = found
    }
    if longest >= 2 do return longest
    return -1
}
