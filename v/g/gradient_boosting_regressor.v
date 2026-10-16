module gradient_boosting_regressor
const invalid_result = -1.0e300
const max_samples = 16
@[export: 'gradient_boosting_regressor']
fn gradient_boosting_regressor(values &i64, length usize) f64 {
    if isnil(values) || length < 8 || length > 36 { return invalid_result }
    unsafe {
    n64, rounds, rate_i, query := values[0], values[1], values[2], values[3]
    if n64 < 2 || n64 > max_samples || rounds < 1 || rounds > 12 || rate_i < 1 || rate_i > 1000000 || length != usize(4 + 2*n64) { return invalid_result }
    n := int(n64)
    mut x := []f64{len: max_samples}
    mut y := []f64{len: max_samples}
    mut pred := []f64{len: max_samples}
    mut residual := []f64{len: max_samples}
    for i in 0 .. n {
        xi, yi := values[4+i], values[4+n+i]
        if xi < -1000 || xi > 1000 || yi < -1000000 || yi > 1000000 || (i > 0 && values[3+i] >= xi) { return invalid_result }
        x[i] = f64(xi); y[i] = f64(yi)/1000.0
    }
    if query < -1000 || query > 1000 { return invalid_result }
    mut mean := 0.0
    for i in 0 .. n { mean += y[i] }
    mean /= f64(n)
    for i in 0 .. n { pred[i] = mean }
    mut qpred := mean
    rate := f64(rate_i)/1000000.0
    for _ in 0 .. int(rounds) {
        mut sum := 0.0
        for i in 0 .. n { residual[i] = y[i]-pred[i]; sum += residual[i] }
        mut constant := true
        for i in 1 .. n { if residual[i] != residual[0] { constant = false } }
        mut best := 1.0e300
        mut split := n
        mut left := 0.0
        mut right := 0.0
        if !constant {
            for s in 0 .. n-1 {
                nl := s+1; nr := n-nl
                mut sl := 0.0; mut sr := 0.0
                for i in 0 .. nl { sl += residual[i] }
                for i in nl .. n { sr += residual[i] }
                lm := sl/f64(nl); rm := sr/f64(nr)
                mut err := 0.0
                for i in 0 .. nl { d := residual[i]-lm; err += d*d }
                for i in nl .. n { d := residual[i]-rm; err += d*d }
                if err < best { best=err; split=s; left=lm; right=rm }
            }
        }
        if split == n {
            leaf := sum/f64(n)
            for i in 0 .. n { pred[i] += rate*leaf }
            qpred += rate*leaf
        } else {
            threshold := (x[split]+x[split+1])/2.0
            for i in 0 .. n { pred[i] += rate*(if x[i] <= threshold { left } else { right }) }
            qpred += rate*(if f64(query) <= threshold { left } else { right })
        }
    }
    return qpred
    }
}
