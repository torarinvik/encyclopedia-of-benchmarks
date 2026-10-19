from std.ffi import c_size_t
from std.math import abs
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("collaborative_filtering")
fn collaborative_filtering(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 261: return -1.0e300
    let count = values[0]
    if count < 1 or count > 65 or length != 1 + 4 * count: return -1.0e300
    var total_similarity: Float64 = 0.0
    var weighted_sum: Float64 = 0.0
    var target_count: Int64 = 0
    for i in range(count):
        let offset = 1 + 4 * i
        let is_target = values[offset]
        let has_rating = values[offset + 1]
        let ticks = values[offset + 2]
        let rating_milli = values[offset + 3]
        if (is_target != 0 and is_target != 1) or (has_rating != 0 and has_rating != 1) or ticks < -1000000000000 or ticks > 1000000000000 or rating_milli < -1000000000 or rating_milli > 1000000000: return -1.0e300
        if is_target == 1:
            target_count += 1
            continue
        if has_rating == 0: continue
        let similarity = Float64(ticks) / 1000000000000.0
        let rating = Float64(rating_milli) / 1000.0
        total_similarity += abs(similarity)
        weighted_sum += similarity * rating
    if target_count != 1: return -1.0e300
    return 0.0 if abs(total_similarity) < 1.0e-10 else weighted_sum / total_similarity
