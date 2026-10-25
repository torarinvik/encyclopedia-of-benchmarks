package olden_tsp

import "core:c"
import "core:math"

MAX_CITIES :: 7
CONQUER_THRESHOLD :: 3
SCALE :: 1000.0

city_distance :: proc "contextless" (x, y: [MAX_CITIES]i64, a, b: int) -> f64 {
    dx := f64(x[a]-x[b]); dy := f64(y[a]-y[b])
    return math.sqrt(dx*dx + dy*dy)
}
subtree_size :: proc "contextless" (node, count: int) -> int {
    if node >= count do return 0
    return 1 + subtree_size(2*node+1, count) + subtree_size(2*node+2, count)
}
collect_postorder :: proc "contextless" (node, count: int, order: ^[MAX_CITIES]int, length: ^int) {
    if node >= count do return
    collect_postorder(2*node+1, count, order, length)
    collect_postorder(2*node+2, count, order, length)
    order[length^] = node
    length^ += 1
}
reverse_cycle :: proc "contextless" (start, size: int, next, prev: ^[MAX_CITIES]int) {
    current := start
    for _ in 0..<size {
        old_next, old_prev := next[current], prev[current]
        next[current] = old_prev; prev[current] = old_next; current = old_next
    }
}
conquer :: proc "contextless" (order: [MAX_CITIES]int, count: int, x, y: [MAX_CITIES]i64,
                                next, prev: ^[MAX_CITIES]int) -> int {
    cycle := order[0]
    next[cycle] = cycle; prev[cycle] = cycle
    for index in 1..<count {
        point := order[index]
        min := cycle
        mindist := city_distance(x, y, point, cycle)
        for tmp := next[cycle]; tmp != cycle; tmp = next[tmp] {
            test := city_distance(x, y, tmp, point)
            if test < mindist { mindist = test; min = tmp }
        }
        next_city, prev_city := next[min], prev[min]
        min_to_next := city_distance(x, y, min, next_city)
        min_to_prev := city_distance(x, y, min, prev_city)
        point_to_next := city_distance(x, y, point, next_city)
        point_to_prev := city_distance(x, y, point, prev_city)
        if point_to_prev-min_to_prev < point_to_next-min_to_next {
            next[prev_city] = point; prev[point] = prev_city
            next[point] = min; prev[min] = point
        } else {
            prev[next_city] = point; next[point] = next_city
            next[min] = point; prev[point] = min
        }
    }
    return cycle
}
merge_cycles :: proc "contextless" (a, b, point, size_a, size_b: int, x, y: [MAX_CITIES]i64,
                                     next, prev: ^[MAX_CITIES]int) -> int {
    min := a
    mindist := city_distance(x, y, point, a)
    for tmp := next[a]; tmp != a; tmp = next[tmp] {
        test := city_distance(x, y, point, tmp)
        if test < mindist { mindist = test; min = tmp }
    }
    next_city, prev_city := next[min], prev[min]
    min_to_next := city_distance(x, y, min, next_city)
    min_to_prev := city_distance(x, y, min, prev_city)
    point_to_next := city_distance(x, y, point, next_city)
    point_to_prev := city_distance(x, y, point, prev_city)
    n1, p1: int
    tton1, ttop1: f64
    if point_to_prev-min_to_prev < point_to_next-min_to_next {
        p1 = prev_city; n1 = min; tton1 = mindist; ttop1 = point_to_prev
    } else {
        p1 = min; n1 = next_city; ttop1 = mindist; tton1 = point_to_next
    }
    min = b; mindist = city_distance(x, y, point, b)
    for tmp := next[b]; tmp != b; tmp = next[tmp] {
        test := city_distance(x, y, point, tmp)
        if test < mindist { mindist = test; min = tmp }
    }
    next_city, prev_city = next[min], prev[min]
    min_to_next = city_distance(x, y, min, next_city); min_to_prev = city_distance(x, y, min, prev_city)
    point_to_next = city_distance(x, y, point, next_city); point_to_prev = city_distance(x, y, point, prev_city)
    n2, p2: int
    tton2, ttop2: f64
    if point_to_prev-min_to_prev < point_to_next-min_to_next {
        p2 = prev_city; n2 = min; tton2 = mindist; ttop2 = point_to_prev
    } else {
        p2 = min; n2 = next_city; ttop2 = mindist; tton2 = point_to_next
    }
    n1_to_n2 := city_distance(x, y, n1, n2); n1_to_p2 := city_distance(x, y, n1, p2)
    p1_to_n2 := city_distance(x, y, p1, n2); p1_to_p2 := city_distance(x, y, p1, p2)
    best := ttop1+ttop2+n1_to_n2; choice := 1
    test := ttop1+tton2+n1_to_p2
    if test < best { choice = 2; best = test }
    test = tton1+ttop2+p1_to_n2
    if test < best { choice = 3; best = test }
    test = tton1+tton2+p1_to_p2
    if test < best { choice = 4 }
    if choice == 1 {
        reverse_cycle(n2, size_b, next, prev)
        next[p1] = point; prev[point] = p1; next[point] = p2; prev[p2] = point
        next[n2] = n1; prev[n1] = n2
    } else if choice == 2 {
        next[p1] = point; prev[point] = p1; next[point] = n2; prev[n2] = point
        next[p2] = n1; prev[n1] = p2
    } else if choice == 3 {
        next[p2] = point; prev[point] = p2; next[point] = n1; prev[n1] = point
        next[p1] = n2; prev[n2] = p1
    } else {
        reverse_cycle(n1, size_a, next, prev)
        next[n1] = point; prev[point] = n1; next[point] = n2; prev[n2] = point
        next[p2] = p1; prev[p1] = p2
    }
    return point
}
solve_subtree :: proc "contextless" (node, count: int, x, y: [MAX_CITIES]i64,
                                      next, prev: ^[MAX_CITIES]int) -> int {
    size := subtree_size(node, count)
    if size <= CONQUER_THRESHOLD {
        order: [MAX_CITIES]int
        order_count := 0
        collect_postorder(node, count, &order, &order_count)
        return conquer(order, order_count, x, y, next, prev)
    }
    left, right := 2*node+1, 2*node+2
    left_cycle := solve_subtree(left, count, x, y, next, prev)
    right_cycle := solve_subtree(right, count, x, y, next, prev)
    return merge_cycles(left_cycle, right_cycle, node, subtree_size(left, count), subtree_size(right, count), x, y, next, prev)
}

@(export)
olden_tsp :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || (length != 7 && length != 15) do return -1
    count_value := input[0]
    if count_value != 3 && count_value != 7 do return -1
    count := int(count_value)
    if length != c.size_t(1+2*count) do return -1
    x, y: [MAX_CITIES]i64
    next, prev: [MAX_CITIES]int
    for city in 0..<count {
        x[city] = input[1+2*city]; y[city] = input[2+2*city]
        if x[city] < -8 || x[city] > 8 || y[city] < -8 || y[city] > 8 do return -1
    }
    _ = solve_subtree(0, count, x, y, &next, &prev)
    tour_length: f64 = 0.0
    city := 0
    for _ in 0..<count {
        following := next[city]
        tour_length += city_distance(x, y, city, following)
        city = following
    }
    return i64(math.floor(tour_length*SCALE + 0.5))
}
