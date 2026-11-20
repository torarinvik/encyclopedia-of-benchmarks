from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_TARGET = 31
const OUTPUT_BYTES = 24

fn ac_visit(target: Int, limit: Int, inout chain: InlineArray[Int, 32],
        length: Int, prefix_is_brauer: Bool, inout total: Int64,
        inout brauer: Int64) -> None:
    let last = chain[length - 1]
    let steps = length - 1
    if last == target:
        if steps == limit:
            total += 1
            if prefix_is_brauer:
                brauer += 1
        return
    let remaining = limit - steps
    if remaining <= 0 or last * (1 << remaining) < target:
        return

    var generated = InlineArray[Bool, 32](fill=False)
    for left in range(length):
        for right in range(left, length):
            let candidate = chain[left] + chain[right]
            if candidate <= last or candidate > target or generated[candidate]:
                continue
            generated[candidate] = True
            chain[length] = candidate
            var uses_last = False
            for index in range(length):
                if last + chain[index] == candidate:
                    uses_last = True
            ac_visit(target, limit, chain, length + 1,
                     prefix_is_brauer and uses_last, total, brauer)

fn ac_bit_length(value_input: Int) -> Int:
    var value = value_input
    var count = 0
    while value != 0:
        count += 1
        value >>= 1
    return count

fn ac_popcount(value_input: Int) -> Int:
    var value = value_input
    var count = 0
    while value != 0:
        count += value & 1
        value >>= 1
    return count

fn ac_minimum_counts(target: Int, inout result: InlineArray[Int64, 3]) -> None:
    if target == 1:
        result[0] = 0
        result[1] = 1
        result[2] = 0
        return
    let lower = ac_bit_length(target - 1)
    let upper = ac_bit_length(target) - 1 + ac_popcount(target) - 1
    for limit in range(lower, upper + 1):
        var chain = InlineArray[Int, 32](fill=0)
        chain[0] = 1
        var total: Int64 = 0
        var brauer: Int64 = 0
        ac_visit(target, limit, chain, 1, True, total, brauer)
        if total != 0:
            result[0] = Int64(limit)
            result[1] = brauer
            result[2] = total - brauer
            return

fn ac_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
        value: Int64) -> None:
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("addition_chain_enumeration")
fn addition_chain_enumeration(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1
    let target_value = input[0]
    if target_value < 1 or target_value > MAX_TARGET:
        return -1
    var result = InlineArray[Int64, 3](fill=0)
    ac_minimum_counts(Int(target_value), result)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < OUTPUT_BYTES:
        return -2
    for index in range(3):
        ac_store_i64(output, index * 8, result[index])
    return Int64(OUTPUT_BYTES)
