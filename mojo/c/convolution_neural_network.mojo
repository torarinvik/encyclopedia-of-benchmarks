from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import exp, floor
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn cnn_sigmoid(value: Float64) -> Float64:
    return 1.0 / (1.0 + exp(-value))

fn cnn_round_three(value: Float64) -> Float64:
    let scaled = value * 1000.0
    let lower = floor(scaled)
    var integer = Int64(lower)
    let fraction = scaled - lower
    if fraction > 0.5 or (fraction == 0.5 and integer % 2 != 0): integer += 1
    return Float64(integer) / 1000.0

@export("convolution_neural_network")
fn convolution_neural_network(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 2048: return -1
    let image_side = values[0]
    let kernel_side = values[1]
    let stride = values[2]
    let filters = values[3]
    let pool_side = values[4]
    let hidden = values[5]
    let outputs = values[6]
    if image_side < 2 or image_side > 8 or kernel_side < 1 or kernel_side > 4 or stride < 1 or stride > 4 or filters < 1 or filters > 3 or pool_side < 1 or pool_side > 2 or hidden < 1 or hidden > 8 or outputs < 1 or outputs > 4 or kernel_side > image_side: return -1
    let conv_side = (image_side - kernel_side) / stride + 1
    if conv_side < pool_side or conv_side % pool_side != 0: return -1
    let pooled_side = conv_side / pool_side
    let feature_count = filters * pooled_side * pooled_side
    let image_count = image_side * image_side
    let kernel_count = filters * kernel_side * kernel_side
    let hidden_weight_count = hidden * feature_count
    let output_weight_count = outputs * hidden
    let expected = 7 + image_count + kernel_count + filters + hidden_weight_count + output_weight_count + hidden + outputs
    if length != expected or feature_count > 192: return -1
    var image = InlineArray[Float64, 64](0.0)
    var kernels = InlineArray[Float64, 48](0.0)
    var conv_bias = InlineArray[Float64, 3](0.0)
    var hidden_weights = InlineArray[Float64, 1536](0.0)
    var output_weights = InlineArray[Float64, 32](0.0)
    var hidden_bias = InlineArray[Float64, 8](0.0)
    var output_bias = InlineArray[Float64, 4](0.0)
    var feature_maps = InlineArray[Float64, 192](0.0)
    var flattened = InlineArray[Float64, 192](0.0)
    var hidden_output = InlineArray[Float64, 8](0.0)
    var result = InlineArray[Float64, 4](0.0)
    var position: Int64 = 7
    for i in range(image_count):
        let raw = values[position]
        position += 1
        if raw < 0 or raw > 1000000: return -1
        image[i] = Float64(raw) / 1000000.0
    for i in range(kernel_count):
        let raw = values[position]
        position += 1
        if raw < -500000 or raw > 500000: return -1
        kernels[i] = Float64(raw) / 1000000.0
    for i in range(filters):
        let raw = values[position]
        position += 1
        if raw < -1000000 or raw > 1000000: return -1
        conv_bias[i] = Float64(raw) / 1000000.0
    for i in range(hidden_weight_count):
        let raw = values[position]
        position += 1
        if raw < -500000 or raw > 500000: return -1
        hidden_weights[i] = Float64(raw) / 1000000.0
    for i in range(output_weight_count):
        let raw = values[position]
        position += 1
        if raw < -500000 or raw > 500000: return -1
        output_weights[i] = Float64(raw) / 1000000.0
    for i in range(hidden):
        let raw = values[position]
        position += 1
        if raw < -1000000 or raw > 1000000: return -1
        hidden_bias[i] = Float64(raw) / 1000000.0
    for i in range(outputs):
        let raw = values[position]
        position += 1
        if raw < -1000000 or raw > 1000000: return -1
        output_bias[i] = Float64(raw) / 1000000.0
    let bytes = outputs * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < bytes: return -2
    for filter in range(filters):
        for top in range(conv_side):
            for left in range(conv_side):
                var total: Float64 = 0.0
                for row in range(kernel_side):
                    for col in range(kernel_side):
                        total += image[(top * stride + row) * image_side + left * stride + col] * kernels[filter * kernel_side * kernel_side + row * kernel_side + col]
                feature_maps[(filter * conv_side + top) * conv_side + left] = cnn_sigmoid(total - conv_bias[filter])
    var feature_index: Int64 = 0
    let pool_area = pool_side * pool_side
    for filter in range(filters):
        var top: Int64 = 0
        while top < conv_side:
            var left: Int64 = 0
            while left < conv_side:
                var total: Float64 = 0.0
                for row in range(pool_side):
                    for col in range(pool_side): total += feature_maps[(filter * conv_side + top + row) * conv_side + left + col]
                flattened[feature_index] = total / Float64(pool_area)
                feature_index += 1
                left += pool_side
            top += pool_side
    for unit in range(hidden):
        var total: Float64 = 0.0
        for i in range(feature_count): total += flattened[i] * hidden_weights[unit * feature_count + i]
        hidden_output[unit] = cnn_sigmoid(total - hidden_bias[unit])
    for unit in range(outputs):
        var total: Float64 = 0.0
        for i in range(hidden): total += hidden_output[i] * output_weights[unit * hidden + i]
        result[unit] = cnn_round_three(cnn_sigmoid(total - output_bias[unit]))
    for unit in range(outputs):
        let bits = bitcast[UInt64](result[unit])
        for b in range(8): output[8 * unit + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
