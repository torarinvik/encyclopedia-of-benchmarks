package perceptron_java
import "core:c"
import "core:math"

MODE :: 0
MAX_OUTPUT :: 25

@(export)
perceptron_java :: proc "c" (input: [^]f64, input_length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length < 9 || input_length > 62 do return -1
    for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
    epochs_value: f64
    rate: f64
    if MODE == 3 {
        epochs_value, rate = input[0], input[1]
        if epochs_value < 0 || epochs_value > 12 || math.trunc(epochs_value) != epochs_value do return -1
    } else {
        rate, epochs_value = input[0], input[1]
        if epochs_value < 1 || epochs_value > 12 || math.trunc(epochs_value) != epochs_value do return -1
    }
    if rate != 0.25 && rate != 0.5 && rate != 0.75 && rate != 1.0 do return -1
    if math.trunc(input[2]) != input[2] || input[2] < 2 || input[2] > 8 || math.trunc(input[3]) != input[3] || input[3] < 1 || input[3] > 4 do return -1
    epochs, samples, features := int(epochs_value), int(input[2]), int(input[3])
    feature_start := 4
    labels_start := feature_start + samples*features
    q_index := labels_start + samples
    if int(input_length) <= q_index || math.trunc(input[q_index]) != input[q_index] || input[q_index] < 1 || input[q_index] > 4 do return -1
    queries := int(input[q_index]); query_start := q_index + 1
    if int(input_length) != query_start + queries*features || input_length > 61 do return -1
    for i in 0..<samples*features { x := input[feature_start+i]; if math.trunc(x) != x || x < -2 || x > 2 do return -1 }
    for i in 0..<queries*features { x := input[query_start+i]; if math.trunc(x) != x || x < -2 || x > 2 do return -1 }
    labels: [8]int
    classes: [3]int
    class_count := 0
    for i in 0..<samples {
        x := input[labels_start+i]
        if math.trunc(x) != x do return -1
        if MODE == 0 && x != 0 && x != 1 do return -1
        if (MODE == 1 || MODE == 3) && x != -1 && x != 1 do return -1
        if MODE == 2 && (x < -2 || x > 2) do return -1
        labels[i] = int(x)
        if MODE == 2 {
            found := false
            for c in 0..<class_count { if classes[c] == int(x) { found = true } }
            if !found { if class_count >= 3 do return -1; classes[class_count] = int(x); class_count += 1 }
        }
    }
    if MODE == 2 {
        if class_count < 2 do return -1
        for i in 0..<class_count { for j in i+1..<class_count { if classes[j] < classes[i] { classes[i], classes[j] = classes[j], classes[i] } } }
    } else { class_count = 2 }
    weights: [15]f64
    epochs_run := 0
    converged := false
    if MODE == 1 {
        weights[0] = -1
        seeded := [4]f64{0.8444218515250481, 0.7579544029403025, 0.420571580830845, 0.25891675029296335}
        for j in 0..<features { weights[j+1] = seeded[j] }
    }
    if MODE == 0 || MODE == 1 {
        for epoch in 0..<epochs {
            updated := false
            for row in 0..<samples {
                score: f64 = 0
                if MODE == 0 { score = weights[features] }
                if MODE == 1 { score += weights[0]*-1 }
                for col in 0..<features {
                    x := input[feature_start+row*features+col]
                    if MODE == 1 { score += weights[col+1]*x } else { score += weights[col]*x }
                }
                pred := 0
                if MODE == 0 { if score >= 0 { pred = 1 } } else { if score >= 0 { pred = 1 } else { pred = -1 } }
                error := labels[row]-pred
                if error != 0 {
                    if MODE == 0 {
                        for col in 0..<features { weights[col] += rate*f64(error)*input[feature_start+row*features+col] }
                        weights[features] += rate*f64(error)
                    } else {
                        weights[0] += rate*f64(error)*-1
                        for col in 0..<features { weights[col+1] += rate*f64(error)*input[feature_start+row*features+col] }
                    }
                    updated = true
                }
            }
            epochs_run = epoch+1
            if MODE == 0 && !updated { converged = true; break }
            if MODE == 1 && !updated { break }
        }
    } else if MODE == 3 {
        for _ in 0..<epochs {
            misses := 0
            for row in 0..<samples {
                score: f64 = 0
                for col in 0..<features { score += weights[col]*input[feature_start+row*features+col] }
                score += weights[features]
                pred := -1
                if score >= 0 { pred = 1 }
                if pred != labels[row] {
                    misses += 1
                    for col in 0..<features { weights[col] += rate*f64(labels[row])*input[feature_start+row*features+col] }
                    weights[features] += rate*f64(labels[row])
                }
            }
            if misses == 0 { break }
        }
    } else {
        stride := features+1
        for _ in 0..<epochs {
            for row in 0..<samples {
                if class_count == 2 {
                    label := 1
                    if labels[row] == classes[0] { label = -1 }
                    score := weights[0]
                    for col in 0..<features { score += weights[col+1]*input[feature_start+row*features+col] }
                    if f64(label)*score <= 0 {
                        weights[0] += rate*f64(label)
                        for col in 0..<features { weights[col+1] += rate*f64(label)*input[feature_start+row*features+col] }
                    }
                } else {
                    predicted := 0; best: f64 = 0
                    for c in 0..<class_count {
                        score := weights[c*stride]
                        for col in 0..<features { score += weights[c*stride+col+1]*input[feature_start+row*features+col] }
                        if c == 0 || score > best { best, predicted = score, c }
                    }
                    target := 0
                    for c in 0..<class_count { if classes[c] == labels[row] { target = c } }
                    if predicted != target {
                        weights[target*stride] += rate; weights[predicted*stride] -= rate
                        for col in 0..<features { x := input[feature_start+row*features+col]; weights[target*stride+col+1] += rate*x; weights[predicted*stride+col+1] -= rate*x }
                    }
                }
            }
        }
    }
    staged: [MAX_OUTPUT]f64
    out_n := 0
    if MODE == 0 {
        staged[0] = f64(features)
        for col in 0..<features { staged[1+col] = weights[col] }
        staged[1+features], staged[2+features], staged[3+features], staged[4+features] = weights[features], f64(epochs_run), f64(converged), f64(queries)
        out_n = 5+features
    } else if MODE == 1 {
        staged[0], staged[1] = f64(epochs_run), f64(features+1)
        for j in 0..<features+1 { staged[2+j] = weights[j] }
        staged[3+features] = f64(queries); out_n = 4+features
    } else if MODE == 3 {
        staged[0] = f64(features)
        for col in 0..<features { staged[1+col] = weights[col] }
        staged[1+features], staged[2+features] = weights[features], f64(queries); out_n = 3+features
    } else {
        staged[0] = f64(class_count)
        for c in 0..<class_count { staged[1+c] = f64(classes[c]) }
        stride := features+1; param_n := stride
        if class_count == 3 { param_n = class_count*stride }
        staged[1+class_count] = f64(param_n)
        for j in 0..<param_n { staged[2+class_count+j] = weights[j] }
        staged[2+class_count+param_n] = f64(queries); out_n = 3+class_count+param_n
    }
    for q in 0..<queries {
        pred: f64 = 0
        if MODE == 0 {
            score := weights[features]
            for col in 0..<features { score += weights[col]*input[query_start+q*features+col] }
            if score >= 0 { pred = 1 }
        } else if MODE == 1 {
            score := weights[0]*-1
            for col in 0..<features { score += weights[col+1]*input[query_start+q*features+col] }
            pred = -1; if score >= 0 { pred = 1 }
        } else if MODE == 3 {
            score: f64 = 0
            for col in 0..<features { score += weights[col]*input[query_start+q*features+col] }
            score += weights[features]; pred = -1; if score >= 0 { pred = 1 }
        } else if class_count == 2 {
            score := weights[0]
            for col in 0..<features { score += weights[col+1]*input[query_start+q*features+col] }
            pred = f64(classes[0]); if score >= 0 { pred = f64(classes[1]) }
        } else {
            best: f64 = 0; chosen := 0; stride := features+1
            for c in 0..<class_count { score := weights[c*stride]; for col in 0..<features { score += weights[c*stride+col+1]*input[query_start+q*features+col] }; if c == 0 || score > best { best, chosen = score, c } }
            pred = f64(classes[chosen])
        }
        staged[out_n] = pred; out_n += 1
    }
    if output == nil || capacity < c.size_t(out_n) do return -2
    for i in 0..<out_n { output[i] = staged[i] }
    return i64(out_n)
}
