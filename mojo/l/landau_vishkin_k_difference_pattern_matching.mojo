from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime LV_PATTERN = 16
comptime LV_TEXT = 32
comptime LV_ERRORS = 2
comptime LV_VALID_INPUT = 3 + LV_PATTERN + LV_TEXT
comptime LV_PARSEABLE_INPUT = LV_VALID_INPUT + 1
comptime LV_DIAGONALS = LV_TEXT + LV_ERRORS + 3
comptime LV_COSTS = LV_ERRORS + 2
comptime LV_FRONTIER = LV_DIAGONALS * LV_COSTS

fn lv_slot(diagonal: Int) -> Int:
    diagonal + LV_ERRORS + 1

fn lv_impl(input: view[i64], length: Int, output: mutable view[u8],
           capacity: Int, output_is_null: Bool) -> i64:
    if length < 3 or length > LV_PARSEABLE_INPUT: return -1
    let raw_m = input[0]
    let raw_n = input[1]
    let raw_k = input[2]
    if raw_m < 1 or raw_m > LV_PATTERN.i64() or raw_n < 0 or raw_n > LV_TEXT.i64(): return -1
    if raw_k < 0 or raw_k > LV_ERRORS.i64() or raw_k >= raw_m: return -1
    let m = raw_m.Int()
    let n = raw_n.Int()
    let k = raw_k.Int()
    if length != 3 + m + n: return -1
    for index in range(m + n):
        let symbol = input[3 + index]
        if symbol < 0 or symbol > 3: return -1
    if output_is_null or capacity < n: return -2

    var frontier = InlineArray[i64, LV_FRONTIER](fill=-1)
    for diagonal in range(-(k + 1), 0):
        let magnitude = -diagonal
        let base = lv_slot(diagonal) * LV_COSTS
        frontier[base + magnitude] = (magnitude - 1).i64()
        frontier[base + magnitude - 1] = (magnitude - 2).i64()
    var staged = InlineArray[u8, LV_TEXT](fill=0)
    for errors in range(k + 1):
        for diagonal in range(-errors, n + 1):
            let base = lv_slot(diagonal) * LV_COSTS
            var row = max(frontier[base + errors] + 1,
                          max(frontier[base - LV_COSTS + errors],
                              frontier[base + LV_COSTS + errors] + 1))
            row = min(row, raw_m)
            while row < raw_m:
                let text_index = row + diagonal.i64()
                if text_index < 0 or text_index >= raw_n or
                   input[3 + m + text_index.Int()] != input[3 + row.Int()]:
                    break
                row += 1
            frontier[base + errors + 1] = row
            if row == raw_m:
                let endpoint = diagonal.i64() + raw_m
                if endpoint >= 1 and endpoint <= raw_n:
                    staged[(endpoint - 1).Int()] = 1
    for index in range(n):
        output[index] <- staged[index]
    n.i64()

@export("landau_vishkin_k_difference_pattern_matching")
fn landau_vishkin_k_difference_pattern_matching(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(LV_PARSEABLE_INPUT):
        return -1
    let input_view: view[i64] = input[0:length.Int()]
    if output == UnsafePointer[UInt8, MutAnyOrigin]():
        var scratch = InlineArray[u8, 1](fill=0)
        return lv_impl(input_view, length.Int(), scratch[0:0], capacity.Int(), True)
    let safe_capacity = min(capacity.Int(), LV_TEXT)
    var output_view: mutable view[u8] = output[0:safe_capacity]
    lv_impl(input_view, length.Int(), output_view, capacity.Int(), False)
