from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_MODULUS = 64
const MAX_INPUT = 2

fn pisano_period_impl(input: view[Int64]) -> Int64:
    if input.len() != 1 or input[0] < 1 or input[0] > MAX_MODULUS: return -1
    let modulus = input[0]
    let initial_next = Int64(1) % modulus
    var previous: Int64 = 0
    var current = initial_next
    for period in range(1, 6 * Int(modulus) + 1):
        let next = (previous + current) % modulus
        previous = current
        current = next
        if previous == 0 and current == initial_next: return Int64(period)
    -1

@export("pisano_period")
fn pisano_period(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT:
        return -1
    var input_copy = InlineArray[Int64, MAX_INPUT]()
    for index in range(Int(length)):
        input_copy[index] <- input[index]
    pisano_period_impl(input_copy[0:Int(length)])
