const EPSILON: f64 = 1.4901161193847656e-8;
const PI: f64 = 3.141592653589793238462643383279502884;
const TWO_PI: f64 = 2.0 * PI;
const THREE_PI: f64 = 3.0 * PI;

fn objectiveValue(x: f64, objective_id: f64) f64 {
    if (objective_id == 0.0) {
        const offset = x - 2.0;
        return offset * offset;
    }
    return if (objective_id == 0.5) @cos(x) else -@cos(x);
}

fn hasValidBracket(low: f64, high: f64, objective_id: f64) bool {
    if (objective_id == 0.0) return low < 2.0 and 2.0 < high;
    if (objective_id == 0.5) return low >= 0.0 and high <= TWO_PI and low < PI and PI < high;
    return objective_id == 1.0 and low >= PI and high <= THREE_PI and low < TWO_PI and TWO_PI < high;
}

export fn brent_method_extrema(start: f64, ending: f64, objective_id: f64) f64 {
    if (start != start or ending != ending or objective_id != objective_id or
        start < -10.0 or start > 10.0 or ending < -10.0 or ending > 10.0) return -1.0;
    var a = start;
    var b = ending;
    if (a > b) {
        const swap = a;
        a = b;
        b = swap;
    }
    if (b - a <= EPSILON or
        (objective_id != 0.0 and objective_id != 0.5 and objective_id != 1.0) or
        !hasValidBracket(a, b, objective_id)) return -1.0;

    const golden_ratio = (3.0 - @sqrt(5.0)) / 2.0;
    var v = a + golden_ratio * (b - a);
    var w = v;
    var x = v;
    var fv = objectiveValue(v, objective_id);
    var fw = fv;
    var fx = fv;
    var p: f64 = 0.0;
    var q: f64 = 0.0;
    var r: f64 = 0.0;
    var d: f64 = 0.0;
    var e: f64 = 0.0;

    var iteration: usize = 0;
    while (iteration < 256) : (iteration += 1) {
        const midpoint = (a + b) / 2.0;
        const tolerance = EPSILON * @abs(x);
        const tolerance2 = 2.0 * tolerance;
        if (@abs(e) > tolerance2) {
            r = (x - w) * (fx - fv);
            q = (x - v) * (fx - fw);
            p = (x - v) * q - (x - w) * r;
            q = 2.0 * (q - r);
            if (q > 0.0) p = -p else q = -q;
            r = e;
            e = d;
        }
        if (@abs(p) < @abs(0.5 * q * r) and p < q * (b - x)) {
            d = p / q;
            const u = x + d;
            if (u - a < tolerance2 or b - u < tolerance2) {
                d = if (x < midpoint) tolerance else -tolerance;
            }
        } else {
            e = (if (x < midpoint) b else a) - x;
            d = golden_ratio * e;
        }
        var u = d;
        if (@abs(d) < tolerance) u = if (d > 0.0) tolerance else -tolerance;
        u += x;
        const fu = objectiveValue(u, objective_id);
        if (fu <= fx) {
            if (u < x) b = x else a = x;
            v = w;
            fv = fw;
            w = x;
            fw = fx;
            x = u;
            fx = fu;
        } else {
            if (u < x) a = u else b = u;
            if (fu <= fw or x == w) {
                v = w;
                fv = fw;
                w = u;
                fw = fu;
            } else if (fu <= fv or v == x or v == w) {
                v = u;
                fv = fu;
            }
        }
        if (!(@abs(x - midpoint) > tolerance - (b - a) / 2.0)) return x;
    }
    return x;
}
