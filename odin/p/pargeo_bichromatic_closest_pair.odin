package pargeo_bichromatic_closest_pair

import "core:c"

MAX_POINTS :: 8
MAX_NODES :: 15
LEAF_SIZE :: 2
MAX_I64 :: i64(9223372036854775807)

Point :: struct { x, y: i64 }
Node :: struct { left, right, start, count: int, min_x, min_y, max_x, max_y: i64 }
Tree :: struct {
    points: [MAX_POINTS]Point,
    order, scratch: [MAX_POINTS]int,
    nodes: [MAX_NODES]Node,
    used: int,
}

build :: proc(tree: ^Tree, start, count: int) -> int {
    id := tree.used
    tree.used += 1
    first := tree.points[tree.order[start]]
    node := Node{-1, -1, start, count, first.x, first.y, first.x, first.y}
    for i := 1; i < count; i += 1 {
        p := tree.points[tree.order[start+i]]
        if p.x < node.min_x do node.min_x = p.x
        if p.x > node.max_x do node.max_x = p.x
        if p.y < node.min_y do node.min_y = p.y
        if p.y > node.max_y do node.max_y = p.y
    }
    if count <= LEAF_SIZE { tree.nodes[id] = node; return id }
    axis_x := (node.max_x-node.min_x) > (node.max_y-node.min_y)
    midpoint_twice := if axis_x { node.min_x+node.max_x } else { node.min_y+node.max_y }
    left_count := 0
    for i := 0; i < count; i += 1 {
        p := tree.points[tree.order[start+i]]
        coordinate := if axis_x { p.x } else { p.y }
        if 2*coordinate < midpoint_twice do left_count += 1
    }
    if left_count == 0 || left_count == count {
        left_count = (count+1)/2
        for i := 0; i < count; i += 1 { tree.scratch[i] = tree.order[start+i] }
    } else {
        l, r := 0, left_count
        for i := 0; i < count; i += 1 {
            index := tree.order[start+i]; p := tree.points[index]
            coordinate := if axis_x { p.x } else { p.y }
            if 2*coordinate < midpoint_twice { tree.scratch[l] = index; l += 1 }
            else { tree.scratch[r] = index; r += 1 }
        }
    }
    for i := 0; i < count; i += 1 { tree.order[start+i] = tree.scratch[i] }
    left := build(tree, start, left_count)
    right := build(tree, start+left_count, count-left_count)
    node.left = left; node.right = right; node.count = 0; tree.nodes[id] = node
    return id
}

box_distance :: proc(a, b: Node) -> i64 {
    dx, dy: i64 = 0, 0
    if a.max_x < b.min_x { dx = b.min_x-a.max_x } else if b.max_x < a.min_x { dx = a.min_x-b.max_x }
    if a.max_y < b.min_y { dy = b.min_y-a.max_y } else if b.max_y < a.min_y { dy = a.min_y-b.max_y }
    return dx*dx+dy*dy
}
search :: proc(a, b: ^Tree, ai, bi: int, best: ^i64) {
    na, nb := a.nodes[ai], b.nodes[bi]
    if box_distance(na,nb) > best^ do return
    al, bl := na.left < 0, nb.left < 0
    if al && bl {
        for i := 0; i < na.count; i += 1 {
            p := a.points[a.order[na.start+i]]
            for j := 0; j < nb.count; j += 1 {
                q := b.points[b.order[nb.start+j]]
                dx, dy := p.x-q.x, p.y-q.y
                d := dx*dx+dy*dy
                if d < best^ do best^ = d
            }
        }
    } else if al {
        l, r := nb.left, nb.right
        if box_distance(na,b.nodes[l]) < box_distance(na,b.nodes[r]) { search(a,b,ai,l,best); search(a,b,ai,r,best) }
        else { search(a,b,ai,r,best); search(a,b,ai,l,best) }
    } else if bl {
        l, r := na.left, na.right
        if box_distance(nb,a.nodes[l]) < box_distance(nb,a.nodes[r]) { search(a,b,l,bi,best); search(a,b,r,bi,best) }
        else { search(a,b,r,bi,best); search(a,b,l,bi,best) }
    } else {
        pairs := [4][2]int{{na.left,nb.left},{na.left,nb.right},{na.right,nb.left},{na.right,nb.right}}
        distances: [4]i64
        for i := 0; i < 4; i += 1 { distances[i] = box_distance(a.nodes[pairs[i][0]],b.nodes[pairs[i][1]]) }
        for i := 1; i < 4; i += 1 {
            p0,p1,d := pairs[i][0],pairs[i][1],distances[i]
            j := i
            for j > 0 && d < distances[j-1] { pairs[j] = pairs[j-1]; distances[j] = distances[j-1]; j -= 1 }
            pairs[j] = [2]int{p0,p1}; distances[j] = d
        }
        for i := 0; i < 4; i += 1 { search(a,b,pairs[i][0],pairs[i][1],best) }
    }
}
write_i64_le :: proc(output: [^]u8, value: i64) {
    bits := u64(value)
    for i := 0; i < 8; i += 1 { output[i] = u8(bits >> u64(8*i)) }
}

// Clean-room bounded ParGeo profile; see package LICENSE.txt for the complete MIT notice.
@(export)
pargeo_bichromatic_closest_pair :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 10 || length > 34 do return -1
    if input[0] < 2 || input[0] > MAX_POINTS || input[1] < 2 || input[1] > MAX_POINTS do return -1
    na, nb := int(input[0]), int(input[1])
    if length != c.size_t(2+2*(na+nb)) do return -1
    for i := 2; i < int(length); i += 1 { if input[i] < -1_000_000 || input[i] > 1_000_000 do return -1 }
    if output == nil || capacity < 8 do return -2
    a, b: Tree
    for i := 0; i < na; i += 1 { a.points[i] = Point{input[2+2*i],input[3+2*i]}; a.order[i] = i }
    offset := 2+2*na
    for i := 0; i < nb; i += 1 { b.points[i] = Point{input[offset+2*i],input[offset+2*i+1]}; b.order[i] = i }
    ra, rb := build(&a,0,na), build(&b,0,nb)
    best := MAX_I64
    search(&a,&b,ra,rb,&best)
    write_i64_le(output,best)
    return 8
}
