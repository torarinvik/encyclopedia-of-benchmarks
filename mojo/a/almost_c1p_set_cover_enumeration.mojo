from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn put_word(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for j in range(8):
        output[offset+j] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("almost_c1p_set_cover_enumeration")
fn almost_c1p_set_cover_enumeration(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 21: return -1
    let rv = input[0]
    let cv = input[1]
    if rv < 1 or rv > 8 or cv < 1 or cv > 10: return -1
    let rows = Int(rv)
    let columns = Int(cv)
    if length != c_size_t(2+rows+columns): return -1
    for column in range(columns):
        if input[2+column] < 1 or input[2+column] > 20: return -1
    let state_count = 1 << columns
    for row in range(rows):
        if input[2+columns+row] < 0 or input[2+columns+row] >= Int64(state_count): return -1
    var feasible = List[Bool](capacity=1024)
    for _ in range(state_count): feasible.append(False)
    feasible[0] = True
    for row in range(rows):
        let covers = Int(input[2+columns+row])
        for selected in range(state_count):
            if not feasible[selected] or selected & covers != 0: continue
            feasible[selected] = False
            for column in range(columns):
                let bit = 1 << column
                if covers & bit != 0: feasible[selected|bit] = True
    var best_mask = -1
    var best_cost = Int64(0)
    for selected in range(state_count):
        if not feasible[selected]: continue
        var cost = Int64(0)
        for column in range(columns):
            if selected & (1 << column) != 0: cost += input[2+column]
        if best_mask < 0 or cost < best_cost or (cost == best_cost and selected < best_mask):
            best_mask = selected
            best_cost = cost
    var selected_count = 0
    if best_mask >= 0:
        for column in range(columns):
            if best_mask & (1 << column) != 0: selected_count += 1
    var bytes = 8
    if best_mask >= 0: bytes = 8*(selected_count+2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    if best_mask < 0:
        put_word(output, 0, -1)
    else:
        put_word(output, 0, Int64(selected_count))
        var cursor = 1
        for column in range(columns):
            if best_mask & (1 << column) != 0:
                put_word(output, 8*cursor, Int64(column))
                cursor += 1
        put_word(output, 8*cursor, best_cost)
    return Int64(bytes)
