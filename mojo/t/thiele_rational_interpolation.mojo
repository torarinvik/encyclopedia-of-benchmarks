from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite, trunc
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_N = 6
const MAX_INPUT = 15
const GRID_DENOMINATOR: Float64 = 18014398509481984.0
const MIN_NODE_SEPARATION: Float64 = 0.0625
const LOW_MAGNITUDE: Float64 = 0.03125000023283064365386963
const MAGNITUDE_CAP: Float64 = 63.99999999976716935634613037

fn grid_value(value: Float64) -> Bool:
    if not isfinite(value) or value < -8.0 or value > 8.0:
        return False
    let scaled = value * GRID_DENOMINATOR
    return trunc(scaled) == scaled

fn guarded_magnitude(value: Float64) -> Bool:
    return (value > LOW_MAGNITUDE and value < MAGNITUDE_CAP) or (value < -LOW_MAGNITUDE and value > -MAGNITUDE_CAP)

fn below_cap(value: Float64) -> Bool:
    return isfinite(value) and value > -MAGNITUDE_CAP and value < MAGNITUDE_CAP

@export("thiele_rational_interpolation")
fn thiele_rational_interpolation(
        input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 4 or input_length > MAX_INPUT:
        return -1
    let n_value = input[0]
    if not grid_value(n_value) or trunc(n_value) != n_value or n_value < 1.0 or n_value > 6.0:
        return -1
    let n = Int(n_value)
    if input_length != c_size_t(2 + 2 * n):
        return -1

    var x = InlineArray[Float64, MAX_N](fill=0.0)
    var y = InlineArray[Float64, MAX_N](fill=0.0)
    var difference = InlineArray[Float64, MAX_N * MAX_N](fill=0.0)
    for i in range(n):
        x[i] = input[1 + 2 * i]
        y[i] = input[2 + 2 * i]
        if not grid_value(x[i]) or not grid_value(y[i]):
            return -1
        for j in range(i):
            if x[i] == x[j] or (x[i] - x[j] < MIN_NODE_SEPARATION and x[i] - x[j] > -MIN_NODE_SEPARATION):
                return -1
        difference[i] = y[i]
    let query = input[Int(input_length) - 1]
    if not grid_value(query):
        return -1

    for order in range(1, n):
        for endpoint in range(order, n):
            let denominator = difference[(order - 1) * MAX_N + order - 1] - difference[(order - 1) * MAX_N + endpoint]
            if not isfinite(denominator) or not guarded_magnitude(denominator):
                return -1
            let value = (x[order - 1] - x[endpoint]) / denominator
            if not below_cap(value):
                return -1
            difference[order * MAX_N + endpoint] = value
        if not guarded_magnitude(difference[order * MAX_N + order]):
            return -1

    var result: Float64 = 0.0
    var at_node = False
    for i in range(n):
        if query == x[i]:
            result = y[i]
            at_node = True
            break
    if not at_node and n == 1:
        result = y[0]
    if not at_node and n > 1:
        var tail = difference[(n - 1) * MAX_N + n - 1]
        for offset in range(n - 2):
            let order = n - 2 - offset
            if not guarded_magnitude(tail):
                return -1
            tail = difference[order * MAX_N + order] + (query - x[order]) / tail
            if not below_cap(tail):
                return -1
        if not guarded_magnitude(tail):
            return -1
        result = y[0] + (query - x[0]) / tail
    if not below_cap(result):
        return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 1:
        return -2
    output[0] = result
    return 1
