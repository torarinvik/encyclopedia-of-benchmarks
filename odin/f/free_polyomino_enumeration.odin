package free_polyomino_enumeration

import "core:c"

FP_MAX_N :: 8
FP_MAX_SHAPES :: 512
FP_LAYER_WORDS :: FP_MAX_SHAPES * FP_MAX_N

fp_canonical :: proc(xs, ys: [FP_MAX_N]i64, size: int) -> [FP_MAX_N]i64 {
    best: [FP_MAX_N]i64 = {}
    have_best := false
    for mode := 0; mode < 8; mode += 1 {
        tx, ty, codes: [FP_MAX_N]i64 = {}, {}, {}
        min_x, min_y: i64 = 1000, 1000
        for i := 0; i < size; i += 1 {
            a := if mode >= 4 { ys[i] } else { xs[i] }
            b := if mode >= 4 { xs[i] } else { ys[i] }
            if (mode & 1) != 0 { a = -a }
            if (mode & 2) != 0 { b = -b }
            tx[i], ty[i] = a, b
            if a < min_x { min_x = a }
            if b < min_y { min_y = b }
        }
        for i := 0; i < size; i += 1 {
            codes[i] = (tx[i] - min_x) * 8 + ty[i] - min_y
            for j := i; j > 0 && codes[j] < codes[j - 1]; j -= 1 {
                codes[j], codes[j - 1] = codes[j - 1], codes[j]
            }
        }
        less := !have_best
        if have_best {
            for i := 0; i < size; i += 1 {
                if codes[i] != best[i] { less = codes[i] < best[i]; break }
            }
        }
        if less { for i := 0; i < size; i += 1 { best[i] = codes[i] }; have_best = true }
    }
    return best
}

@(export)
free_polyomino_enumeration :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 1 do return -1
    if input[0] < 1 || input[0] > FP_MAX_N do return -1
    n := int(input[0])
    shapes: [2 * FP_LAYER_WORDS]i64 = {}
    current, shape_count := 0, 1
    dx := [4]int{1, -1, 0, 0}
    dy := [4]int{0, 0, 1, -1}
    for size := 1; size < n; size += 1 {
        next, next_count := 1 - current, 0
        for s := 0; s < shape_count; s += 1 {
            for cell := 0; cell < size; cell += 1 {
                code := shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + cell]
                x, y := int(code / 8), int(code % 8)
                for direction := 0; direction < 4; direction += 1 {
                    nx, ny := x + dx[direction], y + dy[direction]
                    occupied := false
                    if nx >= 0 && nx < 8 && ny >= 0 && ny < 8 {
                        neighbor := i64(nx * 8 + ny)
                        for i := 0; i < size; i += 1 {
                            if shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + i] == neighbor { occupied = true }
                        }
                    }
                    if occupied { continue }
                    xs, ys: [FP_MAX_N]i64 = {}, {}
                    for i := 0; i < size; i += 1 {
                        previous := shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + i]
                        xs[i], ys[i] = previous / 8, previous % 8
                    }
                    xs[size], ys[size] = i64(nx), i64(ny)
                    candidate := fp_canonical(xs, ys, size + 1)
                    duplicate := false
                    for old := 0; old < next_count && !duplicate; old += 1 {
                        same := true
                        for i := 0; i <= size; i += 1 {
                            if shapes[next * FP_LAYER_WORDS + old * FP_MAX_N + i] != candidate[i] { same = false }
                        }
                        if same { duplicate = true }
                    }
                    if !duplicate {
                        if next_count >= FP_MAX_SHAPES { return -1 }
                        for i := 0; i <= size; i += 1 { shapes[next * FP_LAYER_WORDS + next_count * FP_MAX_N + i] = candidate[i] }
                        next_count += 1
                    }
                }
            }
        }
        current, shape_count = next, next_count
    }
    return i64(shape_count)
}
