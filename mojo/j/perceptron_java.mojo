from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import isfinite
from std.collections import InlineArray


@export("perceptron_java")
fn perceptron_java(
    input: UnsafePointer[Float64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 10 or length > 62:
        return -1
    for i in range(Int(length)):
        if not isfinite(input[i]):
            return -1

    let learning_rate = input[0]
    let epochs_value = input[1]
    let samples_value = input[2]
    let features_value = input[3]
    if learning_rate != 0.25 and learning_rate != 0.5 and learning_rate != 0.75 and learning_rate != 1.0:
        return -1
    if epochs_value < 1.0 or epochs_value > 12.0 or Float64(Int(epochs_value)) != epochs_value:
        return -1
    if samples_value < 2.0 or samples_value > 8.0 or Float64(Int(samples_value)) != samples_value:
        return -1
    if features_value < 1.0 or features_value > 4.0 or Float64(Int(features_value)) != features_value:
        return -1

    let max_epochs = Int(epochs_value)
    let sample_count = Int(samples_value)
    let feature_count = Int(features_value)
    let features_start = 4
    let labels_start = features_start + sample_count * feature_count
    let query_count_index = labels_start + sample_count
    if Int(length) <= query_count_index:
        return -1
    let query_count_value = input[query_count_index]
    if query_count_value < 1.0 or query_count_value > 4.0 or Float64(Int(query_count_value)) != query_count_value:
        return -1
    let query_count = Int(query_count_value)
    let query_start = query_count_index + 1
    if Int(length) != query_start + query_count * feature_count or length > 61:
        return -1

    for row in range(sample_count):
        for feature in range(feature_count):
            let value = input[features_start + row * feature_count + feature]
            if value < -2.0 or value > 2.0 or Float64(Int(value)) != value:
                return -1
    for row in range(sample_count):
        let label = input[labels_start + row]
        if label != 0.0 and label != 1.0:
            return -1
    for row in range(query_count):
        for feature in range(feature_count):
            let value = input[query_start + row * feature_count + feature]
            if value < -2.0 or value > 2.0 or Float64(Int(value)) != value:
                return -1

    var weights = InlineArray[Float64, 4](fill=0.0)
    var bias: Float64 = 0.0
    var epochs_run = 0
    var converged = 0
    for epoch in range(max_epochs):
        var updated = False
        for row in range(sample_count):
            var weighted_sum = bias
            for feature in range(feature_count):
                weighted_sum += weights[feature] * input[features_start + row * feature_count + feature]
            let prediction = 1 if weighted_sum >= 0.0 else 0
            let label = Int(input[labels_start + row])
            let error = label - prediction
            if error != 0:
                for feature in range(feature_count):
                    weights[feature] += learning_rate * Float64(error) * input[features_start + row * feature_count + feature]
                bias += learning_rate * Float64(error)
                updated = True
        epochs_run = epoch + 1
        if not updated:
            converged = 1
            break

    let result_length = feature_count + 5 + query_count
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(result_length):
        return -2
    var staged = InlineArray[Float64, 13](fill=0.0)
    var pos = 0
    staged[pos] = Float64(feature_count)
    pos += 1
    for feature in range(feature_count):
        staged[pos] = weights[feature]
        pos += 1
    staged[pos] = bias
    pos += 1
    staged[pos] = Float64(epochs_run)
    pos += 1
    staged[pos] = Float64(converged)
    pos += 1
    staged[pos] = Float64(query_count)
    pos += 1
    for row in range(query_count):
        var weighted_sum = bias
        for feature in range(feature_count):
            weighted_sum += weights[feature] * input[query_start + row * feature_count + feature]
        staged[pos] = 1.0 if weighted_sum >= 0.0 else 0.0
        pos += 1
    for i in range(result_length):
        output[i] = staged[i]
    return Int64(result_length)
