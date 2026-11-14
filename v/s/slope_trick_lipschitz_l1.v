// Uncompiled and unexecuted two-heap slope-trick draft.
module slope_trick_lipschitz_l1

fn st_push(mut heap [128]i64, mut count int, value i64) {
    mut i := count
    count++
    for i > 0 {
        parent := (i-1)/2
        if heap[parent] >= value { break }
        heap[i] = heap[parent]
        i = parent
    }
    heap[i] = value
}
fn st_replace(mut heap [128]i64, count int, value i64) {
    mut i := 0
    for 2*i+1 < count {
        mut child := 2*i+1
        if child+1 < count && heap[child+1] > heap[child] { child++ }
        if heap[child] <= value { break }
        heap[i] = heap[child]
        i = child
    }
    heap[i] = value
}
@[export: 'slope_trick_lipschitz_l1']
pub fn slope_trick_lipschitz_l1(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 130 { return -1 }
        if input[0] < 0 || input[0] > 128 || input[1] < 0 || input[1] > 100 { return -1 }
        n := int(input[0])
        if length != usize(n+2) { return -1 }
        for i in 0 .. n { if input[2+i] < 0 || input[2+i] > 100 { return -1 } }
        mut left := [128]i64{}
        mut right := [128]i64{}
        mut ln := 0
        mut rn := 0
        mut shift_l := i64(0)
        mut shift_r := i64(0)
        mut answer := i64(0)
        for i in 0 .. n {
            shift_l -= input[1]; shift_r += input[1]
            st_push(mut left, mut ln, input[2+i]-shift_l)
            st_push(mut right, mut rn, shift_r-input[2+i])
            l := left[0]+shift_l
            r := shift_r-right[0]
            if l > r {
                answer += l-r
                st_replace(mut left, ln, r-shift_l)
                st_replace(mut right, rn, shift_r-l)
            }
        }
        return answer
    }
}
