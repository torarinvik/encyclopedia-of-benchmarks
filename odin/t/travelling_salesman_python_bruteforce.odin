package travelling_salesman_python_bruteforce

import "core:c"
import "core:math"

MAX_CITIES :: 8
COORDINATE_LIMIT :: 16.0

@(export)
travelling_salesman_python_bruteforce :: proc "c" (input: [^]f64, input_len: c.size_t,
                                                     output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_len < 3 || input_len > 17 do return -1
    raw_count := input[0]
    if raw_count != raw_count || raw_count < 2.0 || raw_count > 8.0 || raw_count != math.floor_f64(raw_count) do return -1
    city_count := int(raw_count)
    if int(input_len) != 1 + 2 * city_count do return -1

    x: [MAX_CITIES]f64
    y: [MAX_CITIES]f64
    for city in 0..<city_count {
        x[city] = input[1 + 2 * city]
        y[city] = input[2 + 2 * city]
        if x[city] != x[city] || y[city] != y[city] ||
            x[city] < -COORDINATE_LIMIT || x[city] > COORDINATE_LIMIT ||
            y[city] < -COORDINATE_LIMIT || y[city] > COORDINATE_LIMIT ||
            x[city] != math.floor_f64(x[city]) || y[city] != math.floor_f64(y[city]) do return -1
    }

    permutation_len := city_count - 1
    order: [MAX_CITIES - 1]int
    best_order: [MAX_CITIES - 1]int
    for i in 0..<permutation_len { order[i] = i + 1 }
    best_distance := 1.0e300
    for {
        total := 0.0
        previous := 0
        for i in 0..<(permutation_len + 1) {
            next := 0
            if i != permutation_len { next = order[i] }
            dx := x[next] - x[previous]
            dy := y[next] - y[previous]
            total += math.sqrt(dx * dx + dy * dy)
            previous = next
        }
        if total < best_distance {
            best_distance = total
            for i in 0..<permutation_len { best_order[i] = order[i] }
        }

        i := permutation_len
        for i > 1 && order[i - 2] >= order[i - 1] { i -= 1 }
        if i <= 1 { break }
        pivot := i - 2
        j := permutation_len - 1
        for order[j] <= order[pivot] { j -= 1 }
        order[pivot], order[j] = order[j], order[pivot]
        left := i - 1
        right := permutation_len - 1
        for left < right {
            order[left], order[right] = order[right], order[left]
            left += 1
            right -= 1
        }
    }

    result: [11]f64
    path_len := city_count + 1
    result[0] = f64(path_len)
    result[1] = 0.0
    for i in 0..<permutation_len { result[2 + i] = f64(best_order[i]) }
    result[path_len] = 0.0
    result[path_len + 1] = best_distance
    required := city_count + 3
    if output == nil || output_capacity < c.size_t(required) do return -2
    for i in 0..<required { output[i] = result[i] }
    return i64(required)
}
