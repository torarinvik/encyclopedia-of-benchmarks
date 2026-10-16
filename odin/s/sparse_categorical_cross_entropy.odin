package sparse_categorical_cross_entropy
import "core:c"
import "core:math"
INVALID :: -1.0e300
SCALE :: 1_000_000.0
@(export)
sparse_categorical_cross_entropy :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length < 2 do return INVALID
    batch, classes := values[0], values[1]
    if batch < 1 || batch > 32 || classes < 1 || classes > 32 do return INVALID
    b, c := int(batch), int(classes)
    if length != 2+b+b*c do return INVALID
    for r := 0; r < b; r += 1 { label := values[2+r]; if label < 0 || label >= classes do return INVALID; sum: i64 = 0; for col := 0; col < c; col += 1 { x := values[2+b+r*c+col]; if x < 0 || x > 1_000_000 do return INVALID; sum += x }; if sum != 1_000_000 do return INVALID }
    total := 0.0
    for r := 0; r < b; r += 1 { idx := 2+b+r*c+int(values[2+r]); p := f64(values[idx])/SCALE; if p < 1e-15 do p=1e-15; total -= math.log_f64(p) }
    return total
}
