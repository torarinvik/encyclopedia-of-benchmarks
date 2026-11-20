package blelloch_parallel_prefix_scan
import "core:c"

MAX_ITEMS :: 64
MAX_INPUT_WORDS :: 66

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
blelloch_parallel_prefix_scan :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_WORDS do return -1
    n64 := input[0]
    if n64 < 1 || n64 > MAX_ITEMS do return -1
    n := int(n64)
    if int(length) != n + 1 do return -1

    tree: [MAX_ITEMS]i64
    padded := 1
    for padded < n { padded <<= 1 }
    for i := 0; i < n; i += 1 {
        value := input[i + 1]
        if value < -1000000 || value > 1000000 do return -1
        tree[i] = value
    }
    if output == nil || int(output_capacity) < n*8 do return -2

    stride := 2
    for stride <= padded {
        half := stride >> 1
        for right := stride - 1; right < padded; right += stride {
            tree[right] += tree[right-half]
        }
        stride <<= 1
    }
    tree[padded-1] = 0
    stride = padded
    for stride >= 2 {
        half := stride >> 1
        for right := stride - 1; right < padded; right += stride {
            left := right - half
            partial := tree[left]
            tree[left] = tree[right]
            tree[right] += partial
        }
        stride >>= 1
    }
    for i := 0; i < n; i += 1 { store_i64_le(output, i*8, tree[i]) }
    return i64(n * 8)
}
