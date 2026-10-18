import math

const max_input = 7
const max_output = 6

@[export: 'pseudo_inverse']
pub fn pseudo_inverse(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
 unsafe {
  if input == nil || input_length < 3 || input_length > max_input { return -1 }
  for i in 0 .. input_length { if !input[i].is_finite() { return -1 } }
  if math.floor(input[0]) != input[0] || input[0] < 1 || input[0] > 4 || input[1] != 1 { return -1 }
  rows := int(input[0])
  if input_length != usize(2 + rows) { return -1 }
  mut column := [4]f64{}
  mut squared_norm := f64(0)
  for i in 0 .. rows {
   value := input[2 + i]
   if math.floor(value) != value || value < -4 || value > 4 { return -1 }
   column[i] = value
   squared_norm += value * value
  }
  mut staged := [max_output]f64{}
  staged[0] = 1
  staged[1] = f64(rows)
  if math.sqrt(squared_norm) < 1e-4 {
   for i in 0 .. rows { staged[2 + i] = 0 }
  } else {
   for i in 0 .. rows { staged[2 + i] = column[i] / squared_norm }
  }
  output_size := rows + 2
  if output == nil || capacity < usize(output_size) { return -2 }
  for i in 0 .. output_size { output[i] = staged[i] }
  return i64(output_size)
 }
}
