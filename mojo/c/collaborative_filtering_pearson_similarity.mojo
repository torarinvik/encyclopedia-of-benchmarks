from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import abs, sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("collaborative_filtering_pearson_similarity")
fn collaborative_filtering_pearson_similarity(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130: return -2.0
    let n1 = values[0]
    if n1 < 0 or n1 > 32: return -2.0
    let pos2 = 1 + 2 * n1
    if pos2 >= length: return -2.0
    let n2 = values[pos2]
    if n2 < 0 or n2 > 32 or length != pos2 + 1 + 2 * n2: return -2.0
    var ids1 = InlineArray[Int64, 32](0)
    var ids2 = InlineArray[Int64, 32](0)
    var ratings1 = InlineArray[Float64, 32](0.0)
    var ratings2 = InlineArray[Float64, 32](0.0)
    for i in range(n1):
        let id = values[1 + 2 * i]
        let milli = values[2 + 2 * i]
        if id < 0 or id > 127 or milli < -1000000000 or milli > 1000000000: return -2.0
        for j in range(i):
            if ids1[j] == id: return -2.0
        ids1[i] = id
        ratings1[i] = Float64(milli) / 1000.0
    for i in range(n2):
        let id = values[pos2 + 1 + 2 * i]
        let milli = values[pos2 + 2 + 2 * i]
        if id < 0 or id > 127 or milli < -1000000000 or milli > 1000000000: return -2.0
        for j in range(i):
            if ids2[j] == id: return -2.0
        ids2[i] = id
        ratings2[i] = Float64(milli) / 1000.0
    var common1 = InlineArray[Float64, 32](0.0)
    var common2 = InlineArray[Float64, 32](0.0)
    var common_count: Int64 = 0
    for i in range(n1):
        for j in range(n2):
            if ids1[i] == ids2[j]:
                common1[common_count] = ratings1[i]
                common2[common_count] = ratings2[j]
                common_count += 1
                break
    if common_count == 0: return 0.0
    var avg1: Float64 = 0.0
    var avg2: Float64 = 0.0
    for i in range(common_count):
        avg1 += common1[i]
        avg2 += common2[i]
    avg1 /= Float64(common_count)
    avg2 /= Float64(common_count)
    var numerator: Float64 = 0.0
    var sq1: Float64 = 0.0
    var sq2: Float64 = 0.0
    for i in range(common_count):
        let d1 = common1[i] - avg1
        let d2 = common2[i] - avg2
        numerator += d1 * d2
        sq1 += d1 * d1
        sq2 += d2 * d2
    let denominator = sqrt(sq1 * sq2)
    return 0.0 if abs(denominator) < 1.0e-10 else numerator / denominator
