from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn db_fkm_generate(position: Int, period: Int, order: Int, alphabet: Int,
                   inout work: InlineArray[UInt8, 17],
                   output: UnsafePointer[UInt8, MutAnyOrigin], inout emitted: Int):
    if position > order:
        if order % period == 0:
            for index in range(1, period + 1):
                output[emitted] = UInt8(48 + Int(work[index]))
                emitted += 1
        return
    work[position] = work[position - period]
    db_fkm_generate(position + 1, period, order, alphabet, work, output, emitted)
    for symbol in range(Int(work[position - period]) + 1, alphabet):
        work[position] = UInt8(symbol)
        db_fkm_generate(position + 1, position, order, alphabet, work, output, emitted)

@export("de_bruijn_sequences")
fn de_bruijn_sequences(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let alphabet_value = input[0]
    let order_value = input[1]
    if alphabet_value < 2 or alphabet_value > 10 or order_value < 1 or order_value > 16: return -1
    let alphabet = Int(alphabet_value)
    let order = Int(order_value)
    var cycle_length = 1
    for _ in range(order):
        if cycle_length > 10000 // alphabet: return -1
        cycle_length *= alphabet
    let output_length = cycle_length + order - 1
    if capacity < c_size_t(output_length) or output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var work = InlineArray[UInt8, 17](fill=0)
    var emitted = 0
    db_fkm_generate(1, 1, order, alphabet, work, output, emitted)
    for index in range(order - 1): output[cycle_length + index] = output[index]
    return Int64(output_length)
