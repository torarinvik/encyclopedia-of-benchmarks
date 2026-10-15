const EPSILON: f64 = 1.4901161193847656e-8;
const PI: f64 = 3.141592653589793238462643383279502884;
const TWO_PI: f64 = 2.0 * PI;
const THREE_PI: f64 = 3.0 * PI;

fn objective_value(x: f64, objective_id: f64) -> f64 {
    if objective_id == 0.0 {
        let offset = x - 2.0;
        return offset * offset;
    }
    if objective_id == 0.5 { x.cos() } else { -x.cos() }
}

fn has_valid_bracket(low: f64, high: f64, objective_id: f64) -> bool {
    if objective_id == 0.0 { return low < 2.0 && 2.0 < high; }
    if objective_id == 0.5 { return low >= 0.0 && high <= TWO_PI && low < PI && PI < high; }
    objective_id == 1.0 && low >= PI && high <= THREE_PI && low < TWO_PI && TWO_PI < high
}

#[no_mangle]
pub extern "C" fn brent_method_extrema(start: f64, ending: f64, objective_id: f64) -> f64 {
    if !start.is_finite() || !ending.is_finite() || !objective_id.is_finite() ||
        start < -10.0 || start > 10.0 || ending < -10.0 || ending > 10.0 { return -1.0; }
    let mut a = start;
    let mut b = ending;
    if a > b { std::mem::swap(&mut a, &mut b); }
    if b - a <= EPSILON ||
        (objective_id != 0.0 && objective_id != 0.5 && objective_id != 1.0) ||
        !has_valid_bracket(a, b, objective_id) { return -1.0; }

    let golden_ratio = (3.0 - 5.0f64.sqrt()) / 2.0;
    let mut v = a + golden_ratio * (b - a);
    let mut w = v;
    let mut x = v;
    let mut fv = objective_value(v, objective_id);
    let mut fw = fv;
    let mut fx = fv;
    let mut p = 0.0;
    let mut q = 0.0;
    let mut r = 0.0;
    let mut d = 0.0;
    let mut e = 0.0;

    for _ in 0..256 {
        let midpoint = (a + b) / 2.0;
        let tolerance = EPSILON * x.abs();
        let tolerance2 = 2.0 * tolerance;
        if e.abs() > tolerance2 {
            r = (x - w) * (fx - fv);
            q = (x - v) * (fx - fw);
            p = (x - v) * q - (x - w) * r;
            q = 2.0 * (q - r);
            if q > 0.0 { p = -p; } else { q = -q; }
            r = e;
            e = d;
        }
        if p.abs() < (0.5 * q * r).abs() && p < q * (b - x) {
            d = p / q;
            let u = x + d;
            if u - a < tolerance2 || b - u < tolerance2 {
                d = if x < midpoint { tolerance } else { -tolerance };
            }
        } else {
            e = (if x < midpoint { b } else { a }) - x;
            d = golden_ratio * e;
        }
        let mut u = d;
        if d.abs() < tolerance { u = if d > 0.0 { tolerance } else { -tolerance }; }
        u += x;
        let fu = objective_value(u, objective_id);
        if fu <= fx {
            if u < x { b = x; } else { a = x; }
            v = w; fv = fw;
            w = x; fw = fx;
            x = u; fx = fu;
        } else {
            if u < x { a = u; } else { b = u; }
            if fu <= fw || x == w {
                v = w; fv = fw;
                w = u; fw = fu;
            } else if fu <= fv || v == x || v == w {
                v = u; fv = fu;
            }
        }
        if !((x - midpoint).abs() > tolerance - (b - a) / 2.0) { return x; }
    }
    x
}
