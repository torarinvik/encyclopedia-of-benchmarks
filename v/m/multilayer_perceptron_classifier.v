import math

const max_output = 26

@[export: 'multilayer_perceptron_classifier']
pub fn multilayer_perceptron_classifier(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
 unsafe {
  if input == nil || input_length != 15 { return -1 }
  for i in 0 .. 15 { if !input[i].is_finite() { return -1 } }
  if math.floor(input[0]) != input[0] || input[0] < 1 || input[0] > 12 { return -1 }
  if input[1] != 0.05 && input[1] != 0.1 && input[1] != 0.2 { return -1 }
  if input[2] != 0.5 && input[2] != 0.75 && input[2] != 1.0 { return -1 }
  epochs := int(input[0])
  for i in 0 .. 8 { value := input[3 + i]; if value < -2 || value > 2 || value * 4 != math.floor(value * 4) { return -1 } }
  mut labels := [4]int{}
  for i in 0 .. 4 { value := input[11 + i]; if math.floor(value) != value || value < 0 || value > 2 { return -1 }; labels[i] = int(value) }
  mut w1 := [6]f64{0.30471707975443135, -1.0399841062404955, 0.7504511958064572, 0.9405647163912139, -1.9510351886538364, -1.302179506862318}
  mut w2 := [6]f64{0.12784040316728537, -0.3162425923435822, -0.016801157504288795, -0.85304392757358, 0.8793979748628286, 0.7777919354289483}
  mut accuracies := [12]f64{}
  mut losses := [12]f64{}
  mut rate := input[1]
  for epoch in 0 .. epochs {
   for row_index in 0 .. 3 {
    row := [3]f64{input[3 + row_index * 2], input[4 + row_index * 2], 1.0}
    mut z1 := [2]f64{}
    for j in 0 .. 2 { mut total := f64(0); for i in 0 .. 3 { total += row[i] * w1[i * 2 + j] }; z1[j] = total }
    mut hidden := [2]f64{}
    for j in 0 .. 2 { hidden[j] = math.max(0, z1[j]) }
    mut z2 := [3]f64{}
    for k in 0 .. 3 { mut total := f64(0); for j in 0 .. 2 { total += hidden[j] * w2[j * 3 + k] }; z2[k] = total }
    mut delta_out := [3]f64{}
    for k in 0 .. 3 { delta_out[k] = z2[k]; if labels[row_index] == k { delta_out[k] -= 0.99 } }
    mut delta_hidden := [2]f64{}
    for j in 0 .. 2 { mut total := f64(0); for k in 0 .. 3 { total += delta_out[k] * w2[j * 3 + k] }; delta_hidden[j] = if z1[j] > 0 { total } else { 0 } }
    mut grad_w2 := [6]f64{}
    for j in 0 .. 2 { for k in 0 .. 3 { grad_w2[j * 3 + k] = hidden[j] * delta_out[k] } }
    mut grad_w1 := [6]f64{}
    for i in 0 .. 3 { for j in 0 .. 2 { grad_w1[i * 2 + j] = row[i] * delta_hidden[j] } }
    for i in 0 .. 3 { for j in 0 .. 2 { w1[i * 2 + j] -= rate * grad_w1[i * 2 + j] } }
    for j in 0 .. 2 { for k in 0 .. 3 { w2[j * 3 + k] -= rate * grad_w2[j * 3 + k] } }
   }
   row := [3]f64{input[9], input[10], 1.0}
   mut z1 := [2]f64{}
   for j in 0 .. 2 { mut total := f64(0); for i in 0 .. 3 { total += row[i] * w1[i * 2 + j] }; z1[j] = total }
   mut hidden := [2]f64{}
   for j in 0 .. 2 { hidden[j] = math.max(0, z1[j]) }
   mut predicted := [3]f64{}
   for k in 0 .. 3 { mut total := f64(0); for j in 0 .. 2 { total += hidden[j] * w2[j * 3 + k] }; predicted[k] = total }
   mut best := 0
   for k in 1 .. 3 { if predicted[k] > predicted[best] { best = k } }
   accuracies[epoch] = if best == labels[3] { 1 } else { 0 }
   mut loss := f64(0)
   for k in 0 .. 3 { mut difference := predicted[k]; if labels[3] == k { difference -= 0.99 }; loss += difference * difference }
   losses[epoch] = loss / 2.0
   rate *= input[2]
  }
  mut staged := [max_output]f64{}
  staged[0] = f64(epochs)
  mut mean := f64(0)
  for epoch in 0 .. epochs { staged[1 + epoch] = accuracies[epoch]; staged[1 + epochs + epoch] = losses[epoch]; mean += accuracies[epoch] }
  mean /= f64(epochs)
  staged[1 + 2 * epochs] = mean
  output_size := 2 + 2 * epochs
  if output == nil || capacity < usize(output_size) { return -2 }
  for i in 0 .. output_size { output[i] = staged[i] }
  return i64(output_size)
 }
}
