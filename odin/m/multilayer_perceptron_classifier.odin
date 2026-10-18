package multilayer_perceptron_classifier

import "core:c"
import "core:math"

MAX_OUTPUT :: 26

@(export)
multilayer_perceptron_classifier :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length != 15 do return -1
    for i in 0..<15 { if !math.is_finite(input[i]) do return -1 }
    if math.trunc(input[0]) != input[0] || input[0] < 1 || input[0] > 12 do return -1
    if input[1] != 0.05 && input[1] != 0.1 && input[1] != 0.2 do return -1
    if input[2] != 0.5 && input[2] != 0.75 && input[2] != 1.0 do return -1
    epochs := int(input[0])
    for i in 0..<8 { value := input[3+i]; if value < -2 || value > 2 || value*4 != math.trunc(value*4) do return -1 }
    labels: [4]int
    for i in 0..<4 { value := input[11+i]; if math.trunc(value) != value || value < 0 || value > 2 do return -1; labels[i] = int(value) }
    w1 := [6]f64{0.30471707975443135, -1.0399841062404955, 0.7504511958064572, 0.9405647163912139, -1.9510351886538364, -1.302179506862318}
    w2 := [6]f64{0.12784040316728537, -0.3162425923435822, -0.016801157504288795, -0.85304392757358, 0.8793979748628286, 0.7777919354289483}
    accuracies: [12]f64
    losses: [12]f64
    rate := input[1]
    for epoch in 0..<epochs {
        for row_index in 0..<3 {
            row := [3]f64{input[3+row_index*2], input[4+row_index*2], 1.0}
            z1: [2]f64
            for j in 0..<2 { total: f64 = 0; for i in 0..<3 { total += row[i]*w1[i*2+j] }; z1[j] = total }
            hidden: [2]f64
            for j in 0..<2 { hidden[j] = math.max(0, z1[j]) }
            z2: [3]f64
            for k in 0..<3 { total: f64 = 0; for j in 0..<2 { total += hidden[j]*w2[j*3+k] }; z2[k] = total }
            delta_out: [3]f64
            for k in 0..<3 { delta_out[k] = z2[k]; if labels[row_index] == k { delta_out[k] -= 0.99 } }
            delta_hidden: [2]f64
            for j in 0..<2 { total: f64 = 0; for k in 0..<3 { total += delta_out[k]*w2[j*3+k] }; if z1[j] > 0 { delta_hidden[j] = total } else { delta_hidden[j] = 0 } }
            grad_w2: [6]f64
            for j in 0..<2 { for k in 0..<3 { grad_w2[j*3+k] = hidden[j]*delta_out[k] } }
            grad_w1: [6]f64
            for i in 0..<3 { for j in 0..<2 { grad_w1[i*2+j] = row[i]*delta_hidden[j] } }
            for i in 0..<3 { for j in 0..<2 { w1[i*2+j] -= rate*grad_w1[i*2+j] } }
            for j in 0..<2 { for k in 0..<3 { w2[j*3+k] -= rate*grad_w2[j*3+k] } }
        }
        row := [3]f64{input[9], input[10], 1.0}
        z1: [2]f64
        for j in 0..<2 { total: f64 = 0; for i in 0..<3 { total += row[i]*w1[i*2+j] }; z1[j] = total }
        hidden: [2]f64
        for j in 0..<2 { hidden[j] = math.max(0, z1[j]) }
        predicted: [3]f64
        for k in 0..<3 { total: f64 = 0; for j in 0..<2 { total += hidden[j]*w2[j*3+k] }; predicted[k] = total }
        best := 0
        for k in 1..<3 { if predicted[k] > predicted[best] { best = k } }
        if best == labels[3] { accuracies[epoch] = 1 } else { accuracies[epoch] = 0 }
        loss: f64 = 0
        for k in 0..<3 { difference := predicted[k]; if labels[3] == k { difference -= 0.99 }; loss += difference*difference }
        losses[epoch] = loss/2
        rate *= input[2]
    }
    staged: [MAX_OUTPUT]f64
    staged[0] = f64(epochs)
    mean: f64 = 0
    for epoch in 0..<epochs { staged[1+epoch] = accuracies[epoch]; staged[1+epochs+epoch] = losses[epoch]; mean += accuracies[epoch] }
    mean /= f64(epochs)
    staged[1+2*epochs] = mean
    output_size := 2+2*epochs
    if output == nil || capacity < c.size_t(output_size) do return -2
    for i in 0..<output_size { output[i] = staged[i] }
    return i64(output_size)
}
