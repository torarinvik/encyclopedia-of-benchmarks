module sparse_categorical_cross_entropy
import math
const invalid = -1.0e300
const scale = 1_000_000.0
@[export: 'sparse_categorical_cross_entropy']
pub fn sparse_categorical_cross_entropy(values &i64, length usize) f64 {
    if values == nil || length < 2 { return invalid }
    batch, classes := values[0], values[1]
    if batch < 1 || batch > 32 || classes < 1 || classes > 32 { return invalid }
    b, c := int(batch), int(classes)
    if length != 2+b+b*c { return invalid }
    for r in 0 .. b { label := values[2+r]; if label < 0 || label >= classes { return invalid }; mut sum := i64(0); for col in 0 .. c { x := values[2+b+r*c+col]; if x < 0 || x > 1_000_000 { return invalid }; sum += x }; if sum != 1_000_000 { return invalid } }
    mut total := 0.0
    for r in 0 .. b { idx := 2+b+r*c+int(values[2+r]); mut p := f64(values[idx])/scale; if p < 1e-15 { p=1e-15 }; total -= math.log(p) }
    return total
}
