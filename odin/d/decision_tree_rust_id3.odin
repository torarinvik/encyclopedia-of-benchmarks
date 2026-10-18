package decision_tree_rust_id3

import "core:c"
import "core:math"

MAX_ROWS :: 8
MAX_FEATURES :: 4
MAX_NODES :: 31
MAX_INPUT :: 62

Tree_Node :: struct {
    feature: int,
    threshold: f64,
    label: int,
    left: int,
    right: int,
    leaf: bool,
}

entropy :: proc(rows: [MAX_ROWS]int, start, count: int, labels: [MAX_ROWS]int) -> f64 {
    if count == 0 do return 0
    classes: [3]int
    counts: [3]int
    class_count := 0
    for i in start..<start+count {
        label := labels[rows[i]]
        found := -1
        for c in 0..<class_count { if classes[c] == label { found = c } }
        if found < 0 { found = class_count; classes[class_count] = label; class_count += 1 }
        counts[found] += 1
    }
    result: f64 = 0
    for c in 0..<class_count {
        probability := f64(counts[c])/f64(count)
        result += probability*math.log2_f64(probability)
    }
    return -result
}

build_tree :: proc(rows: [MAX_ROWS]int, row_count, feature_count, max_depth, min_samples, depth: int,
    data: [MAX_ROWS*MAX_FEATURES]f64, labels: [MAX_ROWS]int,
    nodes: ^[MAX_NODES]Tree_Node, node_count: ^int) -> int {
    node_index := node_count^
    node_count^ += 1
    node := Tree_Node{feature=-1,left=-1,right=-1,leaf=true}
    classes: [3]int
    counts: [3]int
    class_count := 0
    for i in 0..<row_count {
        label := labels[rows[i]]
        found := -1
        for c in 0..<class_count { if classes[c] == label { found = c } }
        if found < 0 { found = class_count; classes[class_count] = label; class_count += 1 }
        counts[found] += 1
    }
    best_class := 0
    for c in 1..<class_count { if counts[c] > counts[best_class] { best_class = c } }
    node.label = classes[best_class]
    nodes[node_index] = node
    if class_count == 1 || row_count < min_samples || depth >= max_depth || feature_count == 0 { return node_index }

    parent_entropy := entropy(rows, 0, row_count, labels)
    best_gain: f64 = 0
    best_feature := -1
    best_threshold: f64 = 0
    for feature in 0..<feature_count {
        sorted_rows := rows
        for i in 1..<row_count {
            row := sorted_rows[i]
            j := i
            for j > 0 && data[sorted_rows[j-1]*MAX_FEATURES+feature] > data[row*MAX_FEATURES+feature] {
                sorted_rows[j] = sorted_rows[j-1]
                j -= 1
            }
            sorted_rows[j] = row
        }
        for index in 1..<row_count {
            left_value := data[sorted_rows[index-1]*MAX_FEATURES+feature]
            right_value := data[sorted_rows[index]*MAX_FEATURES+feature]
            if left_value == right_value { continue }
            gain := parent_entropy - f64(index)/f64(row_count)*entropy(sorted_rows,0,index,labels) -
                f64(row_count-index)/f64(row_count)*entropy(sorted_rows,index,row_count-index,labels)
            if gain > best_gain { best_gain = gain; best_feature = feature; best_threshold = (left_value+right_value)/2 }
        }
    }
    if best_feature < 0 { return node_index }
    left_rows: [MAX_ROWS]int
    right_rows: [MAX_ROWS]int
    left_count, right_count := 0, 0
    for i in 0..<row_count {
        row := rows[i]
        if data[row*MAX_FEATURES+best_feature] < best_threshold { left_rows[left_count] = row; left_count += 1 }
        else { right_rows[right_count] = row; right_count += 1 }
    }
    if left_count == 0 || right_count == 0 { return node_index }
    nodes[node_index].feature = best_feature
    nodes[node_index].threshold = best_threshold
    nodes[node_index].leaf = false
    nodes[node_index].left = build_tree(left_rows,left_count,feature_count,max_depth,min_samples,depth+1,data,labels,nodes,node_count)
    nodes[node_index].right = build_tree(right_rows,right_count,feature_count,max_depth,min_samples,depth+1,data,labels,nodes,node_count)
    return node_index
}

@(export)
decision_tree_rust_id3 :: proc "c" (input: [^]f64, input_length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length < 10 || input_length > MAX_INPUT do return -1
    for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
    for i in 0..<4 { if math.trunc(input[i]) != input[i] do return -1 }
    if input[0] < 0 || input[0] > 6 || input[1] < 2 || input[1] > 8 || input[2] < 2 || input[2] > 8 || input[3] < 1 || input[3] > 4 do return -1
    max_depth, min_samples, sample_count, feature_count := int(input[0]),int(input[1]),int(input[2]),int(input[3])
    row_width := feature_count+1
    query_count_index := 4+sample_count*row_width
    if int(input_length)<=query_count_index || math.trunc(input[query_count_index]) != input[query_count_index] || input[query_count_index]<1 || input[query_count_index]>4 do return -1
    query_count := int(input[query_count_index]); query_start := query_count_index+1
    if int(input_length)!=query_start+query_count*feature_count || input_length>61 do return -1
    data: [MAX_ROWS*MAX_FEATURES]f64
    labels: [MAX_ROWS]int
    for row in 0..<sample_count {
        for feature in 0..<feature_count {
            value := input[4+row*row_width+feature]
            if value < -4 || value > 4 || value*4 != math.trunc(value*4) do return -1
            data[row*MAX_FEATURES+feature] = value
        }
        label := input[4+row*row_width+feature_count]
        if math.trunc(label)!=label || label<0 || label>2 do return -1
        labels[row] = int(label)
    }
    for i in 0..<query_count*feature_count { value:=input[query_start+i]; if value < -4 || value > 4 || value*4 != math.trunc(value*4) do return -1 }
    rows: [MAX_ROWS]int
    for i in 0..<sample_count { rows[i]=i }
    nodes: [MAX_NODES]Tree_Node
    node_count := 0
    root := build_tree(rows,sample_count,feature_count,max_depth,min_samples,0,data,labels,&nodes,&node_count)
    staged: [5]f64
    staged[0] = f64(query_count)
    for q in 0..<query_count {
        node_index := root
        for !nodes[node_index].leaf {
            feature := nodes[node_index].feature
            if input[query_start+q*feature_count+feature] < nodes[node_index].threshold { node_index=nodes[node_index].left }
            else { node_index=nodes[node_index].right }
        }
        staged[q+1] = f64(nodes[node_index].label)
    }
    if output == nil || capacity < c.size_t(query_count+1) do return -2
    for i in 0..<query_count+1 { output[i]=staged[i] }
    return i64(query_count+1)
}
