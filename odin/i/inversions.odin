package inversions
import "core:c"
@(export)
inversions :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 1024 || (length != 0 && values == nil) do return -1
    for i := 0; i < int(length); i += 1 { if values[i] < i64(-2147483648) || values[i] > i64(2147483647) do return -1 }
    count := i64(0)
    for i := 0; i < int(length); i += 1 { for j := i + 1; j < int(length); j += 1 { if values[i] > values[j] do count += 1 } }
    return count
}
