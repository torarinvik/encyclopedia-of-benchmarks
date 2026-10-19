from std.math import abs

comptime BRENT_INVALID: Float64 = -1.0e300
comptime BRENT_TOL: Float64 = 1.0e-8

fn brent_function(id: Int, x: Float64) -> Float64:
    if id == 0: return x * x * x - x - 2.0
    if id == 1: return x * x + 1.0
    return x * x - 4.0 * x + 3.0

@export("brent_method")
fn brent_method(function_id: Float64, input_left: Float64, input_right: Float64) abi("C") -> Float64:
    if (function_id != 0.0 and function_id != 1.0 and function_id != 2.0) or input_left != input_left or input_right != input_right or input_left < -4.0 or input_left > 4.0 or input_right < -4.0 or input_right > 4.0 or input_left >= input_right: return BRENT_INVALID
    let id = Int(function_id); var left = input_left; var right = input_right
    var fl = brent_function(id, left); var fr = brent_function(id, right)
    if fl * fr >= 0.0: return BRENT_INVALID
    if abs(fl) < abs(fr):
        let tl = left; left = right; right = tl
        let tf = fl; fl = fr; fr = tf
    var c = left; var fc = fl; var d = right - left
    for iteration in range(100):
        if fr == 0.0: return right
        var candidate: Float64 = 0.0
        if fc != fl and fc != fr:
            candidate = left * fr * fc / ((fl - fr) * (fl - fc)) + right * fl * fc / ((fr - fl) * (fr - fc)) + c * fl * fr / ((fc - fl) * (fc - fr))
        else: candidate = right - fr * (right - left) / (fr - fl)
        let quarter = (3.0 * left + right) / 4.0
        let outside = if right > left: not (quarter < candidate and candidate < right) else: not (right < candidate and candidate < quarter)
        let bisect = outside or (iteration > 1 and abs(candidate - right) >= abs(right - c) / 2.0) or (iteration <= 1 and abs(candidate - right) >= abs(c - d) / 2.0) or (iteration > 1 and abs(right - c) < BRENT_TOL) or (iteration <= 1 and abs(c - d) < BRENT_TOL)
        if bisect: candidate = (left + right) / 2.0; d = right - left
        let fcan = brent_function(id, candidate)
        d = c; c = right; fc = fr
        if fl * fcan < 0.0: right = candidate; fr = fcan
        else: left = candidate; fl = fcan
        if abs(fl) < abs(fr):
            let tl = left; left = right; right = tl
            let tf = fl; fl = fr; fr = tf
        if abs(right - left) < BRENT_TOL: return right
    return right
