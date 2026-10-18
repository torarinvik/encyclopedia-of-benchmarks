import math

const max_rows = 8
const max_features = 4
const max_nodes = 31
const max_input = 62

struct Id3Node {
 feature int
 threshold f64
 label int
 left int
 right int
 leaf bool
}

fn id3_entropy(rows [max_rows]int, start int, count int, labels [max_rows]int) f64 {
 if count == 0 { return 0 }
 mut classes := [3]int{}
 mut counts := [3]int{}
 mut class_count := 0
 for i := start .. start + count {
  label := labels[rows[i]]
  mut found := -1
  for c in 0 .. class_count { if classes[c] == label { found = c } }
  if found < 0 { found = class_count; classes[class_count] = label; class_count++ }
  counts[found]++
 }
 mut result := f64(0)
 for c in 0 .. class_count { p := f64(counts[c]) / f64(count); result += p * math.log2(p) }
 return -result
}

fn id3_build_tree(rows [max_rows]int, row_count int, feature_count int, max_depth int,
 min_samples int, depth int, data [max_rows * max_features]f64, labels [max_rows]int,
 mut nodes [max_nodes]Id3Node, mut node_count int) int {
 node_index := node_count
 node_count++
 mut node := Id3Node{feature: -1, left: -1, right: -1, leaf: true}
 mut classes := [3]int{}
 mut counts := [3]int{}
 mut class_count := 0
 for i in 0 .. row_count {
  label := labels[rows[i]]
  mut found := -1
  for c in 0 .. class_count { if classes[c] == label { found = c } }
  if found < 0 { found = class_count; classes[class_count] = label; class_count++ }
  counts[found]++
 }
 mut best_class := 0
 for c in 1 .. class_count { if counts[c] > counts[best_class] { best_class = c } }
 node.label = classes[best_class]
 nodes[node_index] = node
 if class_count == 1 || row_count < min_samples || depth >= max_depth || feature_count == 0 { return node_index }
 parent_entropy := id3_entropy(rows, 0, row_count, labels)
 mut best_gain := f64(0)
 mut best_feature := -1
 mut best_threshold := f64(0)
 for feature in 0 .. feature_count {
  mut sorted_rows := rows
  for i in 1 .. row_count {
   row := sorted_rows[i]
   mut j := i
   for j > 0 && data[sorted_rows[j - 1] * max_features + feature] > data[row * max_features + feature] {
    sorted_rows[j] = sorted_rows[j - 1]
    j--
   }
   sorted_rows[j] = row
  }
  for index in 1 .. row_count {
   left_value := data[sorted_rows[index - 1] * max_features + feature]
   right_value := data[sorted_rows[index] * max_features + feature]
   if left_value == right_value { continue }
   gain := parent_entropy - f64(index) / f64(row_count) * id3_entropy(sorted_rows, 0, index, labels) -
    f64(row_count - index) / f64(row_count) * id3_entropy(sorted_rows, index, row_count - index, labels)
   if gain > best_gain { best_gain = gain; best_feature = feature; best_threshold = (left_value + right_value) / 2.0 }
  }
 }
 if best_feature < 0 { return node_index }
 mut left_rows := [max_rows]int{}
 mut right_rows := [max_rows]int{}
 mut left_count := 0
 mut right_count := 0
 for i in 0 .. row_count {
  row := rows[i]
  if data[row * max_features + best_feature] < best_threshold { left_rows[left_count] = row; left_count++ }
  else { right_rows[right_count] = row; right_count++ }
 }
 if left_count == 0 || right_count == 0 { return node_index }
 nodes[node_index].feature = best_feature
 nodes[node_index].threshold = best_threshold
 nodes[node_index].leaf = false
 nodes[node_index].left = id3_build_tree(left_rows, left_count, feature_count, max_depth, min_samples, depth + 1, data, labels, mut nodes, mut node_count)
 nodes[node_index].right = id3_build_tree(right_rows, right_count, feature_count, max_depth, min_samples, depth + 1, data, labels, mut nodes, mut node_count)
 return node_index
}

@[export: 'decision_tree_rust_id3']
pub fn decision_tree_rust_id3(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
 unsafe {
  if input == nil || input_length < 10 || input_length > max_input { return -1 }
  for i in 0 .. input_length { if !input[i].is_finite() { return -1 } }
  for i in 0 .. 4 { if math.floor(input[i]) != input[i] { return -1 } }
  if input[0] < 0 || input[0] > 6 || input[1] < 2 || input[1] > 8 || input[2] < 2 || input[2] > 8 || input[3] < 1 || input[3] > 4 { return -1 }
  max_depth := int(input[0]); min_samples := int(input[1]); sample_count := int(input[2]); feature_count := int(input[3])
  row_width := feature_count + 1
  query_count_index := 4 + sample_count * row_width
  if input_length <= usize(query_count_index) || math.floor(input[query_count_index]) != input[query_count_index] || input[query_count_index] < 1 || input[query_count_index] > 4 { return -1 }
  query_count := int(input[query_count_index]); query_start := query_count_index + 1
  if input_length != usize(query_start + query_count * feature_count) || input_length > 61 { return -1 }
  mut data := [max_rows * max_features]f64{}
  mut labels := [max_rows]int{}
  for row in 0 .. sample_count {
   for feature in 0 .. feature_count {
    value := input[4 + row * row_width + feature]
    if value < -4 || value > 4 || value * 4 != math.floor(value * 4) { return -1 }
    data[row * max_features + feature] = value
   }
   label := input[4 + row * row_width + feature_count]
   if math.floor(label) != label || label < 0 || label > 2 { return -1 }
   labels[row] = int(label)
  }
  for i in 0 .. query_count * feature_count { value := input[query_start + i]; if value < -4 || value > 4 || value * 4 != math.floor(value * 4) { return -1 } }
  mut rows := [max_rows]int{}
  for i in 0 .. sample_count { rows[i] = i }
  mut nodes := [max_nodes]Id3Node{}
  mut node_count := 0
  root := id3_build_tree(rows, sample_count, feature_count, max_depth, min_samples, 0, data, labels, mut nodes, mut node_count)
  mut staged := [5]f64{}
  staged[0] = f64(query_count)
  for q in 0 .. query_count {
   mut current := root
   for !nodes[current].leaf {
    feature := nodes[current].feature
    if input[query_start + q * feature_count + feature] < nodes[current].threshold { current = nodes[current].left }
    else { current = nodes[current].right }
   }
   staged[q + 1] = f64(nodes[current].label)
  }
  if output == nil || capacity < usize(query_count + 1) { return -2 }
  for i in 0 .. query_count + 1 { output[i] = staged[i] }
  return i64(query_count + 1)
 }
}
