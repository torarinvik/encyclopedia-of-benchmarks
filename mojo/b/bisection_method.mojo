from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn bisection_eval(equation: Int64, x: Float64) -> Float64:
    if equation == 0: return x * x * x + 2.0 * x - 10.0
    return x * x * x - 4.0 * x - 9.0

fn rounded_micro(x: Float64) -> Int64:
    let adjusted = x * 1_000_000.0
    return Int64(adjusted + 0.5) if adjusted >= 0.0 else Int64(adjusted - 0.5)

@export("bisection_method")
fn bisection_method(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1
    let equation = input[0]; let lm = input[1]; let rm = input[2]; let tm = input[3]
    if equation < 0 or equation > 1 or lm < -100000 or lm > 100000 or rm < -100000 or rm > 100000 or lm >= rm or tm < 1 or tm > 1000000: return -1
    var left = Float64(lm) / 1000.0; var right = Float64(rm) / 1000.0
    var fl = bisection_eval(equation, left); let fr = bisection_eval(equation, right)
    if fl == 0.0: return rounded_micro(left)
    if fr == 0.0: return rounded_micro(right)
    if (fl < 0.0) == (fr < 0.0): return -2
    let tolerance = Float64(tm) / 1_000_000.0
    for _ in range(64):
        let middle = left + (right - left) * 0.5; let fm = bisection_eval(equation, middle)
        if fm == 0.0: return rounded_micro(middle)
        if (fl < 0.0) != (fm < 0.0): right = middle
        else: left = middle; fl = fm
        if right - left <= tolerance: return rounded_micro(left + (right - left) * 0.5)
    return -2
