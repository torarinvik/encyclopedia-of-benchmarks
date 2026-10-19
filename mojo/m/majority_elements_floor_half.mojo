from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn majority_floor_put(out: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int32):
    let bits = UInt32(value)
    for b in range(4): out[pos+b] = UInt8((bits >> UInt32(8*b)) & 255)

@export("majority_elements_floor_half")
fn majority_elements_floor_half(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if n > 256 or (n > 0 and v == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var keys = InlineArray[Int32, 512](fill=0)
    var counts = InlineArray[Int, 512](fill=0)
    var used = InlineArray[Bool, 512](fill=False)
    var order = InlineArray[Int, 256](fill=0)
    var unique_count = 0
    for i in range(Int(n)):
        if v[i] < -2147483648 or v[i] > 2147483647: return -1
        let key = Int32(v[i])
        var slot = Int(v[i] % 512)
        if slot < 0: slot += 512
        while used[slot] and keys[slot] != key: slot = (slot + 1) & 511
        if not used[slot]:
            used[slot] = True; keys[slot] = key; counts[slot] = 1; order[unique_count] = slot; unique_count += 1
        else: counts[slot] += 1
    var result = InlineArray[Int32, 256](fill=0)
    var result_count = 0
    for i in range(unique_count):
        let slot = order[i]
        if counts[slot] >= Int(n) / 2:
            result[result_count] = keys[slot]; result_count += 1
    for i in range(1, result_count):
        let value = result[i]; var j = i
        while j > 0 and result[j-1] > value:
            result[j] = result[j-1]; j -= 1
        result[j] = value
    let required = result_count * 4
    if cap < c_size_t(required) or (required > 0 and out == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for i in range(result_count): majority_floor_put(out, i*4, result[i])
    return Int64(result_count)
