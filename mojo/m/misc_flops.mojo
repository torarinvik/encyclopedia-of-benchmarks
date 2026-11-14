from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn flops_sine(w: Float64, alternating: Bool) -> Float64:
    var x = Float64(0.164105986683e-9)
    x = x*w + (-0.2507059876207e-7 if alternating else 0.2507059876207e-7)
    x = x*w + 0.27557589750762e-5
    x = x*w + (-0.198412715551283e-3 if alternating else 0.198412715551283e-3)
    x = x*w + 0.833333333809067e-2
    x = x*w - 0.1666666666671334
    return x*w + 1.0

fn flops_cosine(w: Float64) -> Float64:
    var x = Float64(0.20189405e-8)
    x = x*w - 0.2754213324e-6
    x = x*w + 0.24801428034e-4
    x = x*w - 0.1388888805755e-2
    x = x*w + 0.4166666664651e-1
    x = x*w - 0.4999999999982
    return x*w + 1.0

@export("misc_flops")
fn misc_flops(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    let invalid = Float64(-1.0e300)
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return invalid
    let module_id = values[0]; let steps_value = values[1]
    if module_id < 1 or module_id > 8 or steps_value < 2 or steps_value > 128: return invalid
    let steps = Int(steps_value)
    let pi = Float64(3.14159265358979323846)
    var sum = Float64(0.0)
    if module_id == 1:
        let n = 2*steps
        let dx = Float64(1.0)/Float64(n)
        for i in range(1,n):
            let u = Float64(i)*dx
            sum += (0.3999999946405e-1+u*(0.96e-3+u*0.1233153e-5))/(1.0+u*(0.3999999946405e-1+u*(0.48e-3+u*0.411051e-6)))
        let endpoint = (0.3999999946405e-1+0.96e-3+0.1233153e-5)/(1.0+0.3999999946405e-1+0.48e-3+0.411051e-6)
        return 1.0/(dx*(endpoint+0.3999999946405e-1+2.0*sum)/2.0)
    if module_id == 2:
        var sign = Float64(-5.0); var partial = Float64(-1.0)
        for _ in range(steps): sign = -sign; partial += sign
        var v = Float64(0.0); var reciprocal_sum = Float64(0.0); var u = partial; var x = Float64(0.0)
        for _ in range(steps):
            sign = -sign; partial += sign; u += 2.0
            x = x+(sign-u); v = v-sign*u; reciprocal_sum = reciprocal_sum+sign/u
        let estimate = 4.0*reciprocal_sum/5.0+5.0/v
        return estimate-31.25/(v*v*v)
    if module_id == 7:
        let end = Float64(102.3321513995275); let dx = end/Float64(steps)
        for i in range(1,steps):
            let x = Float64(i)*dx; let u = x*x
            sum = sum-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0)
        let u = end*end
        let endpoint = -1.0-1.0/(end+1.0)-end/(u+1.0)-u/(end*u+1.0)
        return 18.0*dx*(endpoint+2.0*sum)
    let divisor = Float64(4.0 if module_id == 6 else 3.0)
    let end = pi / divisor
    let dx = pi / (divisor * Float64(steps))
    for i in range(1,steps):
        let u = Float64(i)*dx; let w = u*u
        if module_id == 3: sum += u*flops_sine(w, True)
        elif module_id == 4: sum += flops_cosine(w)
        elif module_id == 5: sum += u*flops_sine(w, False)/flops_cosine(w)
        elif module_id == 6: sum += u*flops_sine(w, False)*flops_cosine(w)
        else:
            let cosine = flops_cosine(w)
            sum += cosine*cosine*u*flops_sine(w, False)
    let w = end*end
    var endpoint = Float64(0.0)
    if module_id == 3: endpoint = end*flops_sine(w, True)
    elif module_id == 4: endpoint = flops_cosine(w)+1.0
    elif module_id == 5: endpoint = end*flops_sine(w, False)/flops_cosine(w)
    elif module_id == 6: endpoint = end*flops_sine(w, False)*flops_cosine(w)
    else:
        let cosine = flops_cosine(w)
        endpoint = end*flops_sine(w, False)*cosine*cosine
    return dx*(endpoint+2.0*sum)/2.0
