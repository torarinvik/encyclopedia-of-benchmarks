from std.math import abs, cos, sqrt

comptime EXT_EPS: Float64 = 1.4901161193847656e-8
comptime EXT_PI: Float64 = 3.141592653589793238462643383279502884
comptime EXT_TWOPI: Float64 = 2.0 * EXT_PI
comptime EXT_THREEPI: Float64 = 3.0 * EXT_PI

fn extrema_objective(x: Float64, id: Float64) -> Float64:
    if id == 0.0: let d = x - 2.0; return d * d
    if id == 0.5: return cos(x)
    return -cos(x)

@export("brent_method_extrema")
fn brent_method_extrema(start: Float64, ending: Float64, objective_id: Float64) abi("C") -> Float64:
    if start != start or ending != ending or (objective_id != 0.0 and objective_id != 0.5 and objective_id != 1.0) or start < -10.0 or start > 10.0 or ending < -10.0 or ending > 10.0: return -1.0
    var a = min(start, ending); var b = max(start, ending)
    if b - a <= EXT_EPS: return -1.0
    if objective_id == 0.0:
        if not (a < 2.0 and 2.0 < b): return -1.0
    elif objective_id == 0.5:
        if not (a >= 0.0 and b <= EXT_TWOPI and a < EXT_PI and EXT_PI < b): return -1.0
    else:
        if not (a >= EXT_PI and b <= EXT_THREEPI and a < 2.0 * EXT_PI and 2.0 * EXT_PI < b): return -1.0
    let golden = (3.0 - sqrt(5.0)) / 2.0
    var v = a + golden * (b - a); var w = v; var x = v
    var fv = extrema_objective(v, objective_id); var fw = fv; var fx = fv
    var p: Float64 = 0.0; var q: Float64 = 0.0; var r: Float64 = 0.0; var d: Float64 = 0.0; var e: Float64 = 0.0
    for _ in range(256):
        let midpoint = (a + b) / 2.0; let tol = EXT_EPS * abs(x); let tol2 = 2.0 * tol
        if abs(e) > tol2:
            r = (x - w) * (fx - fv); q = (x - v) * (fx - fw); p = (x - v) * q - (x - w) * r; q = 2.0 * (q - r)
            if q > 0.0: p = -p
            else: q = -q
            r = e; e = d
        if abs(p) < abs(0.5 * q * r) and p < q * (b - x):
            d = p / q; let u = x + d
            if u - a < tol2 or b - u < tol2: d = tol if x < midpoint else -tol
        else:
            e = (b if x < midpoint else a) - x; d = golden * e
        var u = d
        if abs(d) < tol: u = tol if d > 0.0 else -tol
        u += x; let fu = extrema_objective(u, objective_id)
        if fu <= fx:
            if u < x: b = x
            else: a = x
            v = w; fv = fw; w = x; fw = fx; x = u; fx = fu
        else:
            if u < x: a = u
            else: b = u
            if fu <= fw or x == w: v = w; fv = fw; w = u; fw = fu
            elif fu <= fv or v == x or v == w: v = u; fv = fu
        if not (abs(x - midpoint) > tol - (b - a) / 2.0): return x
    return x
