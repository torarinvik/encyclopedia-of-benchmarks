module melkman_simple_polyline_hull

fn turn(x [32]i64, y [32]i64, a int, b int, c int) i64 {
    return (x[b]-x[a])*(y[c]-y[a])-(y[b]-y[a])*(x[c]-x[a])
}

@[export: 'melkman_simple_polyline_hull']
pub fn melkman_simple_polyline_hull(input &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 7 || length > 66 { return -1 }
        raw := input[0]
        if raw < 3 || raw > 32 { return -1 }
        n := int(raw)
        if length != usize(1+2*n) { return -1 }
        mut x := [32]i64{}
        mut y := [32]i64{}
        for i in 0 .. n {
            x[i] = input[1+2*i]
            y[i] = input[2+2*i]
            if x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000 { return -1 }
        }
        initial := turn(x,y,0,1,2)
        if initial == 0 { return -1 }
        mut deque := [68]int{}
        mut first := 32
        mut last := 35
        deque[32] = 2
        deque[35] = 2
        deque[33] = if initial > 0 { 0 } else { 1 }
        deque[34] = if initial > 0 { 1 } else { 0 }
        for i in 3 .. n {
            if turn(x,y,deque[first],deque[first+1],i) > 0 && turn(x,y,deque[last-1],deque[last],i) > 0 { continue }
            for last > first && turn(x,y,deque[first],deque[first+1],i) <= 0 { first++ }
            if last <= first || first == 0 { return -1 }
            first--
            deque[first] = i
            for last > first && turn(x,y,deque[last-1],deque[last],i) <= 0 { last-- }
            if last <= first || last+1 >= 68 { return -1 }
            last++
            deque[last] = i
        }
        count := last-first
        mut start := 0
        for i in 1 .. count {
            a := deque[first+i]
            b := deque[first+start]
            if x[a] < x[b] || (x[a] == x[b] && y[a] < y[b]) { start = i }
        }
        bytes := 8*count
        if output == nil || capacity < usize(bytes) { return -2 }
        mut staged := [256]u8{}
        for i in 0 .. count {
            index := u64(deque[first+(start+i)%count])
            for b in 0 .. 8 { staged[8*i+b] = u8((index >> (8*b)) & 255) }
        }
        for i in 0 .. bytes { output[i] = staged[i] }
        return i64(bytes)
    }
}
