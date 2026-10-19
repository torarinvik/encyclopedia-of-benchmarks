from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List
from std.math import exp

comptime SCALE = 1000000.0

fn quantize(value: Float64) -> Int64:
    let scaled = value * SCALE
    return Int64(scaled + 0.5) if scaled >= 0.0 else Int64(scaled - 0.5)

fn append_i64_le(mut bytes: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8):
        bytes.append(UInt8(bits & 255))
        bits >>= 8

@export("back_propagation_neural_network")
fn back_propagation_neural_network(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 7:
        return -1
    for i in range(2):
        if input[i] < -1000000 or input[i] > 1000000:
            return -1
    for i in range(2, 6):
        if input[i] < -2000000 or input[i] > 2000000:
            return -1
    if input[6] < 1 or input[6] > 300000:
        return -1
    let x = Float64(input[0]) / SCALE
    let target = Float64(input[1]) / SCALE
    let hidden_weight = Float64(input[2]) / SCALE
    let hidden_bias = Float64(input[3]) / SCALE
    let output_weight = Float64(input[4]) / SCALE
    let output_bias = Float64(input[5]) / SCALE
    let learning_rate = Float64(input[6]) / SCALE
    let hidden_net = hidden_weight * x - hidden_bias
    let hidden = 1.0 / (1.0 + exp(-hidden_net))
    let output_net = output_weight * hidden - output_bias
    let prediction = 1.0 / (1.0 + exp(-output_net))
    let difference = target - prediction
    let loss = difference * difference
    let loss_gradient = 2.0 * (prediction - target)
    let output_delta = loss_gradient * prediction * (1.0 - prediction)
    let output_weight_gradient = output_delta * hidden
    let output_bias_gradient = -output_delta
    let hidden_gradient = output_delta * output_weight
    let hidden_delta = hidden_gradient * hidden * (1.0 - hidden)
    let hidden_weight_gradient = hidden_delta * x
    let hidden_bias_gradient = -hidden_delta
    let updated_hidden_weight = hidden_weight - learning_rate * hidden_weight_gradient
    let updated_hidden_bias = hidden_bias - learning_rate * hidden_bias_gradient
    let updated_output_weight = output_weight - learning_rate * output_weight_gradient
    let updated_output_bias = output_bias - learning_rate * output_bias_gradient
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 56:
        return -2
    var staged = List[UInt8](capacity=56)
    append_i64_le(staged, quantize(loss))
    append_i64_le(staged, quantize(hidden))
    append_i64_le(staged, quantize(prediction))
    append_i64_le(staged, quantize(updated_hidden_weight))
    append_i64_le(staged, quantize(updated_hidden_bias))
    append_i64_le(staged, quantize(updated_output_weight))
    append_i64_le(staged, quantize(updated_output_bias))
    for i in range(56):
        output[i] = staged[i]
    return 56
