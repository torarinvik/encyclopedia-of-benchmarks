// Uncompiled and unexecuted weighted-binary-search draft.
module wqs_path_independent_set
struct State { score i64; count i64 }
fn evaluate(input &i64, n int, penalty i64) State {
    mut two := State{}
    mut one := State{}
    unsafe {
        for i in 0 .. n {
            take := State{score: two.score+input[2+i]-penalty, count: two.count+1}
            mut current := one
            if take.score > one.score || (take.score == one.score && take.count > one.count) { current = take }
            two = one
            one = current
        }
    }
    return one
}
@[export: 'wqs_path_independent_set']
pub fn wqs_path_independent_set(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 130 { return -1000000000 }
        if input[0] < 0 || input[0] > 128 || input[1] < 0 || input[1] > (input[0]+1)/2 { return -1000000000 }
        n := int(input[0])
        if length != usize(n+2) { return -1000000000 }
        for i in 0 .. n { if input[2+i] < -1000 || input[2+i] > 1000 { return -1000000000 } }
        mut low := i64(-256001)
        mut high := i64(256001)
        for low < high {
            middle := low+(high-low+1)/2
            state := evaluate(input, n, middle)
            if state.count >= input[1] { low = middle } else { high = middle-1 }
        }
        return evaluate(input, n, low).score+low*input[1]
    }
}
