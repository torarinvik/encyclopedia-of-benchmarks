package tsvc_s331_last_negative_index
import "core:c"

@(export)
tsvc_s331_last_negative_index :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 257 { return -1 }
    n := input[0]
    if n < 1 || n > 256 || length != c.size_t(1+n) { return -1 }
    result: i64 = 0
    for i in 0..<int(n) {
        value := input[1+i]
        if value < -1_000_000 || value > 1_000_000 { return -1 }
        if value < 0 { result = i64(i+1) }
    }
    return result
}
