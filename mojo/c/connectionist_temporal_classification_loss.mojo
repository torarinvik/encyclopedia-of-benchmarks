from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import exp, log, log1p
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ctc_logadd(left: Float64, right: Float64) -> Float64:
    let negative_inf = -1.0e300
    if left <= negative_inf / 2.0: return right
    if right <= negative_inf / 2.0: return left
    let larger = left if left > right else right
    let smaller = right if left > right else left
    return larger + log1p(exp(smaller - larger))

@export("connectionist_temporal_classification_loss")
fn connectionist_temporal_classification_loss(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 531: return -1.0e300
    let time = values[0]
    let classes = values[1]
    let target_len = values[2]
    if time < 1 or time > 32 or classes < 2 or classes > 16 or target_len < 1 or target_len > 16 or length != 3 + target_len + time * classes: return -1.0e300
    var repeated: Int64 = 0
    for i in range(target_len):
        let target = values[3 + i]
        if target < 1 or target >= classes: return -1.0e300
        if i > 0 and target == values[3 + i - 1]: repeated += 1
    if time < target_len + repeated: return -1.0e300
    let base = 3 + target_len
    for t in range(time):
        var sum: Int64 = 0
        for c in range(classes):
            let probability = values[base + t * classes + c]
            if probability < 1 or probability > 1000000: return -1.0e300
            sum += probability
        if sum != 1000000: return -1.0e300
    let states = 2 * target_len + 1
    var extended = InlineArray[Int64, 33](0)
    var previous = InlineArray[Float64, 33](-1.0e300)
    var current = InlineArray[Float64, 33](0.0)
    for s in range(states): extended[s] = 0 if s % 2 == 0 else values[3 + s / 2]
    previous[0] = log(Float64(values[base]) / 1000000.0)
    previous[1] = log(Float64(values[base + extended[1]]) / 1000000.0)
    for t in range(1, time):
        for s in range(states):
            var incoming = previous[s]
            if s > 0: incoming = ctc_logadd(incoming, previous[s - 1])
            if s > 1 and extended[s] != extended[s - 2]: incoming = ctc_logadd(incoming, previous[s - 2])
            let probability = Float64(values[base + t * classes + extended[s]]) / 1000000.0
            current[s] = incoming + log(probability)
        for s in range(states): previous[s] = current[s]
    return -ctc_logadd(previous[states - 1], previous[states - 2])
