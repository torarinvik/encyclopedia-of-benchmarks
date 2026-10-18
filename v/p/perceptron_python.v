import math

const mode = 1
const max_output = 25

@[export: 'perceptron_python']
pub fn perceptron(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
 unsafe {
  if input == nil || input_length < 9 || input_length > 62 { return -1 }
  for i in 0 .. input_length { if !input[i].is_finite() { return -1 } }
  mut rate := f64(0); mut epochs := 0
  if mode == 3 {
   if input[0] != math.floor(input[0]) || input[0] < 0 || input[0] > 12 { return -1 }
   epochs = int(input[0]); rate = input[1]
  } else {
   rate = input[0]
   if input[1] != math.floor(input[1]) || input[1] < 1 || input[1] > 12 { return -1 }
   epochs = int(input[1])
  }
  if rate != 0.25 && rate != 0.5 && rate != 0.75 && rate != 1.0 { return -1 }
  if input[2] != math.floor(input[2]) || input[2] < 2 || input[2] > 8 || input[3] != math.floor(input[3]) || input[3] < 1 || input[3] > 4 { return -1 }
  samples := int(input[2]); features := int(input[3]); feature_start := 4
  labels_start := feature_start + samples * features; q_index := labels_start + samples
  if input_length <= usize(q_index) || input[q_index] != math.floor(input[q_index]) || input[q_index] < 1 || input[q_index] > 4 { return -1 }
  queries := int(input[q_index]); query_start := q_index + 1
  if input_length != usize(query_start + queries * features) || input_length > 61 { return -1 }
  for i in 0 .. samples * features { x := input[feature_start + i]; if x != math.floor(x) || x < -2 || x > 2 { return -1 } }
  for i in 0 .. queries * features { x := input[query_start + i]; if x != math.floor(x) || x < -2 || x > 2 { return -1 } }
  mut labels := [8]int{}
  mut classes := [3]int{}
  mut class_count := 0
  for i in 0 .. samples {
   x := input[labels_start + i]
   if x != math.floor(x) { return -1 }
   if mode == 0 && x != 0 && x != 1 { return -1 }
   if (mode == 1 || mode == 3) && x != -1 && x != 1 { return -1 }
   if mode == 2 && (x < -2 || x > 2) { return -1 }
   labels[i] = int(x)
   if mode == 2 {
    mut found := false
    for c in 0 .. class_count { if classes[c] == int(x) { found = true } }
    if !found { if class_count >= 3 { return -1 }; classes[class_count] = int(x); class_count++ }
   }
  }
  if mode == 2 {
   if class_count < 2 { return -1 }
   for i in 0 .. class_count { for j in i + 1 .. class_count { if classes[j] < classes[i] { t := classes[i]; classes[i] = classes[j]; classes[j] = t } } }
  } else { class_count = 2 }
  mut weights := [15]f64{}
  mut epochs_run := 0; mut converged := false
  if mode == 1 {
   weights[0] = -1
   seeded := [4]f64{0.8444218515250481, 0.7579544029403025, 0.420571580830845, 0.25891675029296335}
   for j in 0 .. features { weights[j + 1] = seeded[j] }
  }
  if mode == 0 || mode == 1 {
   for epoch in 0 .. epochs {
    mut updated := false
    for row in 0 .. samples {
     mut score := f64(0)
     if mode == 0 { score = weights[features] }
     if mode == 1 { score += weights[0] * -1 }
     for col in 0 .. features {
      x := input[feature_start + row * features + col]
      if mode == 1 { score += weights[col + 1] * x } else { score += weights[col] * x }
     }
     pred := if mode == 0 { if score >= 0 { 1 } else { 0 } } else { if score >= 0 { 1 } else { -1 } }
     error := labels[row] - pred
     if error != 0 {
      if mode == 0 {
       for col in 0 .. features { weights[col] += rate * f64(error) * input[feature_start + row * features + col] }
       weights[features] += rate * f64(error)
      } else {
       weights[0] += rate * f64(error) * -1
       for col in 0 .. features { weights[col + 1] += rate * f64(error) * input[feature_start + row * features + col] }
      }
      updated = true
     }
    }
    epochs_run = epoch + 1
    if mode == 0 && !updated { converged = true; break }
    if mode == 1 && !updated { break }
   }
  } else if mode == 3 {
   for _ in 0 .. epochs {
    mut misses := 0
    for row in 0 .. samples {
     mut score := f64(0)
     for col in 0 .. features { score += weights[col] * input[feature_start + row * features + col] }
     score += weights[features]
     pred := if score >= 0 { 1 } else { -1 }
     if pred != labels[row] {
      misses++
      for col in 0 .. features { weights[col] += rate * f64(labels[row]) * input[feature_start + row * features + col] }
      weights[features] += rate * f64(labels[row])
     }
    }
    if misses == 0 { break }
   }
  } else {
   stride := features + 1
   for _ in 0 .. epochs {
    for row in 0 .. samples {
     if class_count == 2 {
      label := if labels[row] == classes[0] { -1 } else { 1 }
      mut score := weights[0]
      for col in 0 .. features { score += weights[col + 1] * input[feature_start + row * features + col] }
      if f64(label) * score <= 0 {
       weights[0] += rate * f64(label)
       for col in 0 .. features { weights[col + 1] += rate * f64(label) * input[feature_start + row * features + col] }
      }
     } else {
      mut predicted := 0; mut best := f64(0)
      for c in 0 .. class_count {
       mut score := weights[c * stride]
       for col in 0 .. features { score += weights[c * stride + col + 1] * input[feature_start + row * features + col] }
       if c == 0 || score > best { best = score; predicted = c }
      }
      mut target := 0
      for c in 0 .. class_count { if classes[c] == labels[row] { target = c } }
      if predicted != target {
       weights[target * stride] += rate; weights[predicted * stride] -= rate
       for col in 0 .. features { x := input[feature_start + row * features + col]; weights[target * stride + col + 1] += rate * x; weights[predicted * stride + col + 1] -= rate * x }
      }
     }
    }
   }
  }
  mut staged := [max_output]f64{}; mut out_n := 0
  if mode == 0 {
   staged[0] = f64(features); for col in 0 .. features { staged[1 + col] = weights[col] }; staged[1 + features] = weights[features]; staged[2 + features] = f64(epochs_run); staged[3 + features] = if converged { 1 } else { 0 }; staged[4 + features] = f64(queries); out_n = 5 + features
  } else if mode == 1 {
   staged[0] = f64(epochs_run); staged[1] = f64(features + 1); for j in 0 .. features + 1 { staged[2 + j] = weights[j] }; staged[3 + features] = f64(queries); out_n = 4 + features
  } else if mode == 3 {
   staged[0] = f64(features); for col in 0 .. features { staged[1 + col] = weights[col] }; staged[1 + features] = weights[features]; staged[2 + features] = f64(queries); out_n = 3 + features
  } else {
   staged[0] = f64(class_count); for c in 0 .. class_count { staged[1 + c] = f64(classes[c]) }; stride := features + 1; param_n := if class_count == 2 { stride } else { class_count * stride }; staged[1 + class_count] = f64(param_n); for j in 0 .. param_n { staged[2 + class_count + j] = weights[j] }; staged[2 + class_count + param_n] = f64(queries); out_n = 3 + class_count + param_n
  }
  for q in 0 .. queries {
   mut pred := f64(0)
   if mode == 0 {
    mut score := weights[features]
    for col in 0 .. features { score += weights[col] * input[query_start + q * features + col] }
    pred = if score >= 0 { 1 } else { 0 }
   } else if mode == 1 {
    mut score := weights[0] * -1
    for col in 0 .. features { score += weights[col + 1] * input[query_start + q * features + col] }
    pred = if score >= 0 { 1 } else { -1 }
   } else if mode == 3 {
    mut score := f64(0)
    for col in 0 .. features { score += weights[col] * input[query_start + q * features + col] }
    score += weights[features]; pred = if score >= 0 { 1 } else { -1 }
   } else if class_count == 2 {
    mut score := weights[0]
    for col in 0 .. features { score += weights[col + 1] * input[query_start + q * features + col] }
    pred = f64(if score >= 0 { classes[1] } else { classes[0] })
   } else {
    mut best := f64(0); mut chosen := 0; stride := features + 1
    for c in 0 .. class_count { mut score := weights[c * stride]; for col in 0 .. features { score += weights[c * stride + col + 1] * input[query_start + q * features + col] }; if c == 0 || score > best { best = score; chosen = c } }
    pred = f64(classes[chosen])
   }
   staged[out_n] = pred; out_n++
  }
  if output == nil || capacity < usize(out_n) { return -2 }
  for i in 0 .. out_n { output[i] = staged[i] }
  return i64(out_n)
 }
}
