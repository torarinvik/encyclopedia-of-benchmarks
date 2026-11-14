module chan_output_sensitive_hull

// Unverified Chan hull draft; no compiler or benchmark has run.
struct Point {
    x i64
    y i64
}

fn turn(points []Point, a int, b int, c int) i64 {
    return (points[b].x-points[a].x)*(points[c].y-points[a].y) - (points[b].y-points[a].y)*(points[c].x-points[a].x)
}
fn less(points []Point, a int, b int) bool {
    return points[a].x < points[b].x || (points[a].x == points[b].x && points[a].y < points[b].y)
}
fn group_hull(points []Point, begin int, end int) []int {
    count := end-begin
    mut order := []int{len: count}
    mut scratch := []int{len: count}
    for i in 0 .. count { order[i] = begin+i }
    mut width := 1
    for width < count {
        mut block := 0
        for block < count {
            middle := if block+width < count { block+width } else { count }
            finish := if block+2*width < count { block+2*width } else { count }
            mut left := block
            mut right := middle
            mut dest := block
            for left < middle && right < finish {
                if less(points, order[right], order[left]) { scratch[dest] = order[right]; right++ }
                else { scratch[dest] = order[left]; left++ }
                dest++
            }
            for left < middle { scratch[dest] = order[left]; left++; dest++ }
            for right < finish { scratch[dest] = order[right]; right++; dest++ }
            block += 2*width
        }
        for i in 0 .. count { order[i] = scratch[i] }
        width *= 2
    }
    if count == 1 { return order }
    mut chain := []int{cap: 2*count}
    for id in order {
        for chain.len >= 2 && turn(points, chain[chain.len-2], chain[chain.len-1], id) <= 0 { chain.delete_last() }
        chain << id
    }
    lower := chain.len
    mut i := count-1
    for i > 0 {
        i--
        for chain.len > lower && turn(points, chain[chain.len-2], chain[chain.len-1], order[i]) <= 0 { chain.delete_last() }
        chain << order[i]
    }
    chain.delete_last()
    return chain
}
fn tangent(points []Point, hull []int, query int) int {
    n := hull.len
    if n == 1 { return hull[0] }
    if n == 2 { return if turn(points, query, hull[0], hull[1]) > 0 { hull[0] } else { hull[1] } }
    initial_up := turn(points, query, hull[0], hull[1]) > 0
    mut lo := 0
    mut hi := n
    for lo < hi {
        mid := lo + (hi-lo)/2
        before := turn(points, query, hull[mid], hull[(mid+n-1)%n]) > 0
        after := turn(points, query, hull[mid], hull[(mid+1)%n]) > 0
        if before && after { return hull[mid] }
        below := mid != 0 && turn(points, query, hull[mid], hull[0]) > 0
        above := mid != 0 && turn(points, query, hull[0], hull[mid]) > 0
        search_left := if initial_up { after && below } else { after || above }
        if search_left { hi = mid } else { lo = mid+1 }
    }
    return -1
}

@[export: 'chan_output_sensitive_hull']
pub fn chan_output_sensitive_hull(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 7 || length > 66 { return -1 }
    unsafe {
        if input[0] < 3 || input[0] > 32 { return -1 }
        n := int(input[0])
        if length != usize(1+2*n) { return -1 }
        mut points := []Point{cap: n}
        for i in 0 .. n {
            p := Point{input[1+2*i], input[2+2*i]}
            if p.x < -1000 || p.x > 1000 || p.y < -1000 || p.y > 1000 { return -1 }
            for q in points { if p.x == q.x && p.y == q.y { return -1 } }
            points << p
        }
        for i in 0 .. n { for j in i+1 .. n { for k in j+1 .. n {
            if turn(points, i, j, k) == 0 { return -1 }
        } } }
        mut start := 0
        for i in 1 .. n { if less(points, i, start) { start = i } }
        mut guess := if n < 4 { n } else { 4 }
        for {
            mut groups := [][]int{}
            mut group_of := []int{len: n}
            mut position := []int{len: n, init: -1}
            mut begin := 0
            for begin < n {
                end := if begin+guess < n { begin+guess } else { n }
                for i in begin .. end { group_of[i] = groups.len }
                part := group_hull(points, begin, end)
                for index, id in part { position[id] = index }
                groups << part
                begin = end
            }
            mut hull := [start]
            for _ in 0 .. guess {
                current := hull[hull.len-1]
                mut candidate := -1
                for g, part in groups {
                    mut local := -1
                    if g == group_of[current] {
                        if position[current] < 0 { return -1 }
                        if part.len > 1 { local = part[(position[current]+1)%part.len] }
                    } else {
                        local = tangent(points, part, current)
                        if local < 0 { return -1 }
                    }
                    if local >= 0 && (candidate < 0 || turn(points, current, candidate, local) < 0) { candidate = local }
                }
                if candidate < 0 { return -1 }
                if candidate == start {
                    bytes := 16*hull.len
                    if output == nil || capacity < usize(bytes) { return -2 }
                    for i, id in hull {
                        fields := [u64(points[id].x), u64(points[id].y)]
                        for axis in 0 .. 2 { for b in 0 .. 8 { output[16*i+8*axis+b] = u8(fields[axis] >> (8*b)) } }
                    }
                    return i64(bytes)
                }
                if hull.len == n { return -1 }
                hull << candidate
            }
            if guess == n { return -1 }
            guess = if guess*guess < n { guess*guess } else { n }
        }
    }
    return -1
}
