module pargeo_bichromatic_closest_pair

const max_points = 8
const max_nodes = 15
const leaf_size = 2
const max_i64 = i64(9223372036854775807)

struct Point { x i64; y i64 }
struct Node { left int; right int; start int; count int; min_x i64; min_y i64; max_x i64; max_y i64 }
struct Tree { mut: points [max_points]Point; order [max_points]int; scratch [max_points]int; nodes [max_nodes]Node; used int }

fn build(mut tree &Tree, start int, count int) int {
    id := tree.used
    tree.used++
    first := tree.points[tree.order[start]]
    mut node := Node{-1, -1, start, count, first.x, first.y, first.x, first.y}
    for i in 1 .. count {
        p := tree.points[tree.order[start + i]]
        if p.x < node.min_x { node.min_x = p.x }
        if p.x > node.max_x { node.max_x = p.x }
        if p.y < node.min_y { node.min_y = p.y }
        if p.y > node.max_y { node.max_y = p.y }
    }
    if count <= leaf_size { tree.nodes[id] = node; return id }
    axis_x := node.max_x - node.min_x > node.max_y - node.min_y
    midpoint_twice := if axis_x { node.min_x + node.max_x } else { node.min_y + node.max_y }
    mut left_count := 0
    for i in 0 .. count {
        p := tree.points[tree.order[start + i]]
        coordinate := if axis_x { p.x } else { p.y }
        if 2 * coordinate < midpoint_twice { left_count++ }
    }
    if left_count == 0 || left_count == count {
        left_count = (count + 1) / 2
        for i in 0 .. count { tree.scratch[i] = tree.order[start + i] }
    } else {
        mut l := 0
        mut r := left_count
        for i in 0 .. count {
            index := tree.order[start + i]
            p := tree.points[index]
            coordinate := if axis_x { p.x } else { p.y }
            if 2 * coordinate < midpoint_twice { tree.scratch[l] = index; l++ }
            else { tree.scratch[r] = index; r++ }
        }
    }
    for i in 0 .. count { tree.order[start + i] = tree.scratch[i] }
    node.left = build(mut tree, start, left_count)
    node.right = build(mut tree, start + left_count, count - left_count)
    node.count = 0
    tree.nodes[id] = node
    return id
}

fn box_distance(a Node, b Node) i64 {
    mut dx := i64(0)
    mut dy := i64(0)
    if a.max_x < b.min_x { dx = b.min_x - a.max_x } else if b.max_x < a.min_x { dx = a.min_x - b.max_x }
    if a.max_y < b.min_y { dy = b.min_y - a.max_y } else if b.max_y < a.min_y { dy = a.min_y - b.max_y }
    return dx * dx + dy * dy
}
fn search(mut a &Tree, mut b &Tree, ai int, bi int, mut best &i64) {
    na := a.nodes[ai]
    nb := b.nodes[bi]
    if box_distance(na, nb) > best { return }
    al := na.left < 0
    bl := nb.left < 0
    if al && bl {
        for i in 0 .. na.count {
            p := a.points[a.order[na.start + i]]
            for j in 0 .. nb.count {
                q := b.points[b.order[nb.start + j]]
                dx := p.x - q.x
                dy := p.y - q.y
                distance := dx * dx + dy * dy
                if distance < best { best = distance }
            }
        }
    } else if al {
        l, r := nb.left, nb.right
        if box_distance(na, b.nodes[l]) < box_distance(na, b.nodes[r]) {
            search(mut a, mut b, ai, l, mut best); search(mut a, mut b, ai, r, mut best)
        } else {
            search(mut a, mut b, ai, r, mut best); search(mut a, mut b, ai, l, mut best)
        }
    } else if bl {
        l, r := na.left, na.right
        if box_distance(nb, a.nodes[l]) < box_distance(nb, a.nodes[r]) {
            search(mut a, mut b, l, bi, mut best); search(mut a, mut b, r, bi, mut best)
        } else {
            search(mut a, mut b, r, bi, mut best); search(mut a, mut b, l, bi, mut best)
        }
    } else {
        mut pairs := [4][2]int{{na.left, nb.left}, {na.left, nb.right}, {na.right, nb.left}, {na.right, nb.right}}
        mut distances := [4]i64{}
        for i in 0 .. 4 { distances[i] = box_distance(a.nodes[pairs[i][0]], b.nodes[pairs[i][1]]) }
        for i in 1 .. 4 {
            p0, p1, d := pairs[i][0], pairs[i][1], distances[i]
            mut j := i
            for j > 0 && d < distances[j - 1] { pairs[j] = pairs[j - 1]; distances[j] = distances[j - 1]; j-- }
            pairs[j] = [2]int{p0, p1}; distances[j] = d
        }
        for i in 0 .. 4 { search(mut a, mut b, pairs[i][0], pairs[i][1], mut best) }
    }
}
fn write_i64_le(mut output &u8, value i64) {
    bits := u64(value)
    unsafe { for i in 0 .. 8 { output[i] = u8(bits >> (i * 8)) } }
}

// Clean-room bounded ParGeo profile; see package LICENSE.txt for the complete MIT notice.
@[export: 'pargeo_bichromatic_closest_pair']
fn pargeo_bichromatic_closest_pair(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 10 || length > 34 { return -1 }
    unsafe {
        if input[0] < 2 || input[0] > max_points || input[1] < 2 || input[1] > max_points { return -1 }
        na, nb := int(input[0]), int(input[1])
        if length != usize(2 + 2 * (na + nb)) { return -1 }
        for i in 2 .. int(length) { if input[i] < -1_000_000 || input[i] > 1_000_000 { return -1 } }
        if output == nil || capacity < 8 { return -2 }
        mut a := Tree{}
        mut b := Tree{}
        for i in 0 .. na { a.points[i] = Point{input[2 + 2 * i], input[3 + 2 * i]}; a.order[i] = i }
        offset := 2 + 2 * na
        for i in 0 .. nb { b.points[i] = Point{input[offset + 2 * i], input[offset + 2 * i + 1]}; b.order[i] = i }
        ra := build(mut a, 0, na)
        rb := build(mut b, 0, nb)
        mut best := max_i64
        search(mut a, mut b, ra, rb, mut best)
        write_i64_le(mut output, best)
        return 8
    }
}
