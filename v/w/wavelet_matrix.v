module wavelet_matrix

struct Matrix {
    mut:
    prefix [715]int
    zeros [11]int
}

fn (matrix &Matrix) less(first int, last int, key int) int {
    mut left := first
    mut right := last
    mut result := 0
    for level in 0 .. 11 {
        zl := matrix.prefix[level*65+left]
        zr := matrix.prefix[level*65+right]
        if key & (1 << (10-level)) != 0 {
            result += zr-zl
            left = matrix.zeros[level]+left-zl
            right = matrix.zeros[level]+right-zr
        } else { left = zl; right = zr }
    }
    return result
}

fn (matrix &Matrix) quantile(first int, last int, rank int) int {
    mut left := first
    mut right := last
    mut k := rank
    mut key := 0
    for level in 0 .. 11 {
        zl := matrix.prefix[level*65+left]
        zr := matrix.prefix[level*65+right]
        if k < zr-zl { left = zl; right = zr }
        else {
            k -= zr-zl
            key |= 1 << (10-level)
            left = matrix.zeros[level]+left-zl
            right = matrix.zeros[level]+right-zr
        }
    }
    return key-1000
}

@[export: 'wavelet_matrix']
pub fn wavelet_matrix(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 706 { return -1 }
    nv := unsafe { input[0] }
    if nv < 1 || nv > 64 { return -1 }
    n := int(nv)
    if length < usize(n+2) { return -1 }
    for i in 0 .. n {
        x := unsafe { input[1+i] }
        if x < -1000 || x > 1000 { return -1 }
    }
    qv := unsafe { input[n+1] }
    if qv < 0 || qv > 128 || length != usize(n+2+5*int(qv)) { return -1 }
    mut matrix := Matrix{}
    mut current := [64]int{}
    mut scratch := [64]int{}
    for i in 0 .. n { current[i] = int(unsafe { input[1+i] })+1000 }
    for level in 0 .. 11 {
        bit := 10-level
        for i in 0 .. n {
            mut count := matrix.prefix[level*65+i]
            if current[i] & (1 << bit) == 0 { count++ }
            matrix.prefix[level*65+i+1] = count
        }
        mut z := 0
        mut o := matrix.prefix[level*65+n]
        matrix.zeros[level] = o
        for i in 0 .. n {
            if current[i] & (1 << bit) == 0 { scratch[z] = current[i]; z++ }
            else { scratch[o] = current[i]; o++ }
        }
        for i in 0 .. n { current[i] = scratch[i] }
    }
    mut total := i64(0)
    for j in 0 .. int(qv) {
        at := n+2+5*j
        op := unsafe { input[at] }
        a := unsafe { input[at+1] }
        b := unsafe { input[at+2] }
        c := unsafe { input[at+3] }
        d := unsafe { input[at+4] }
        mut answer := 0
        if op == 0 {
            if a < -1000 || a > 1000 || b < -1 || b >= i64(n) { return -1 }
            answer = matrix.less(0, int(b)+1, int(a)+1001)-matrix.less(0, int(b)+1, int(a)+1000)
        } else if op == 1 {
            if a < 0 || a > b || b >= i64(n) || c < 0 || c > b-a { return -1 }
            answer = matrix.quantile(int(a), int(b)+1, int(c))
        } else if op == 2 {
            if a < 0 || a > b || b >= i64(n) || c < -1000 || c > d || d > 1000 { return -1 }
            answer = matrix.less(int(a), int(b)+1, int(d)+1001)-matrix.less(int(a), int(b)+1, int(c)+1000)
        } else { return -1 }
        total += i64(j+1)*i64(answer+1000001)
    }
    return total
}
