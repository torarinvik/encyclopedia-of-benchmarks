from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import log

@export("categorical_cross_entropy")
fn categorical_cross_entropy(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 2050: return -1.0e300
    let batch = values[0]
    let classes = values[1]
    if batch < 1 or batch > 64 or classes < 2 or classes > 16: return -1.0e300
    let cells = batch * classes
    if length != 2 + 2 * cells: return -1.0e300
    let probabilities_start = 2 + cells
    for row in range(batch):
        var label_sum: Int64 = 0
        var probability_sum: Int64 = 0
        for col in range(classes):
            let index = row * classes + col
            let label = values[2 + index]
            let probability = values[probabilities_start + index]
            if label != 0 and label != 1: return -1.0e300
            if probability < 0 or probability > 1000000: return -1.0e300
            label_sum += label
            probability_sum += probability
        if label_sum != 1 or probability_sum != 1000000: return -1.0e300
    var total: Float64 = 0.0
    for row in range(batch):
        var row_loss: Float64 = 0.0
        for col in range(classes):
            let index = row * classes + col
            let label = Float64(values[2 + index])
            var probability = Float64(values[probabilities_start + index]) / 1000000.0
            if probability < 1.0e-15: probability = 1.0e-15
            if probability > 1.0: probability = 1.0
            row_loss -= label * log(probability)
        total += row_loss
    return total
