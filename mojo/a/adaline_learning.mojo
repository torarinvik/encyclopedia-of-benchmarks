from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn adaline_store_i32(output: UnsafePointer[UInt8, MutAnyOrigin], position: Int, value: Int64):
    let bits = UInt32(value)
    for b in range(4):
        output[position + b] = UInt8((bits >> (8 * b)) & 255)

@export("adaline_learning")
fn adaline_learning(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5:
        return -1
    let sample_count = input[0]
    let feature_count = input[1]
    let eta_num = input[2]
    let eta_shift = input[3]
    let max_iter = input[4]
    if sample_count < 1 or sample_count > 32 or feature_count < 1 or feature_count > 8 or eta_num < 1 or eta_shift < 1 or eta_shift > 12 or max_iter < 1 or max_iter > 500:
        return -1
    let scale = Int64(1) << eta_shift
    if eta_num >= scale or length != c_size_t(5 + sample_count * (feature_count + 1)):
        return -1
    for s in range(sample_count):
        let row = 5 + s * (feature_count + 1)
        for f in range(feature_count):
            if input[row + f] < -16 or input[row + f] > 16:
                return -1
        let label = input[row + feature_count]
        if label != -1 and label != 1:
            return -1
    let output_bytes = 4 * (1 + feature_count + 1 + sample_count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    var weights = List[Int64](length=Int(feature_count), fill=scale)
    var bias = scale
    var completed: Int64 = 0
    for epoch in range(max_iter):
        var mistakes = 0
        for s in range(sample_count):
            let row = 5 + s * (feature_count + 1)
            var score = bias
            for f in range(feature_count):
                score += input[row + f] * weights[f]
            var prediction: Int64 = -1
            if score > 0:
                prediction = 1
            let error = input[row + feature_count] - prediction
            if error != 0:
                mistakes += 1
                let correction = eta_num * error
                for f in range(feature_count):
                    weights[f] += correction * input[row + f]
                bias += correction
        completed += 1
        if mistakes == 0:
            break
    var pos = 0
    adaline_store_i32(output, pos, completed); pos += 4
    for f in range(feature_count):
        adaline_store_i32(output, pos, weights[f]); pos += 4
    adaline_store_i32(output, pos, bias); pos += 4
    for s in range(sample_count):
        let row = 5 + s * (feature_count + 1)
        var score = bias
        for f in range(feature_count):
            score += input[row + f] * weights[f]
        if score > 0:
            adaline_store_i32(output, pos, 1)
        else:
            adaline_store_i32(output, pos, -1)
        pos += 4
    return Int64(output_bytes)
