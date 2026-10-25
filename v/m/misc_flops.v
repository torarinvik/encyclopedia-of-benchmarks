module main

const invalid_result = -1.0e300
const a1 = -0.1666666666671334
const a2 = 0.833333333809067e-2
const a3 = 0.198412715551283e-3
const a4 = 0.27557589750762e-5
const a5 = 0.2507059876207e-7
const a6 = 0.164105986683e-9
const b1 = -0.4999999999982
const b2 = 0.4166666664651e-1
const b3 = -0.1388888805755e-2
const b4 = 0.24801428034e-4
const b5 = -0.2754213324e-6
const b6 = 0.20189405e-8
const d1 = 0.3999999946405e-1
const d2 = 0.96e-3
const d3 = 0.1233153e-5
const e2 = 0.48e-3
const e3 = 0.411051e-6

fn sin_poly_legacy(w f64) f64 {
    mut value := a6
    value = value*w+a5
    value = value*w+a4
    value = value*w+a3
    value = value*w+a2
    value = value*w+a1
    return value*w+1.0
}

fn sin_poly_alternating(w f64) f64 {
    mut value := a6
    value = value*w-a5
    value = value*w+a4
    value = value*w-a3
    value = value*w+a2
    value = value*w+a1
    return value*w+1.0
}

fn cos_poly(w f64) f64 {
    mut value := b6
    value = value*w+b5
    value = value*w+b4
    value = value*w+b3
    value = value*w+b2
    value = value*w+b1
    return value*w+1.0
}

@[export: 'misc_flops']
pub fn misc_flops(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 2 { return invalid_result }
    module_id := unsafe { values[0] }
    steps := unsafe { values[1] }
    if module_id < 1 || module_id > 8 || steps < 2 || steps > 128 { return invalid_result }
    pi := 3.14159265358979323846
    mut sum := 0.0
    mut result := 0.0
    mut x := 0.0
    mut u := 0.0
    mut w := 0.0
    if module_id == 1 {
        n := 2*steps
        dx := 1.0/f64(n)
        mut v := 0.0
        for i := i64(1); i < n; i++ { v += 1.0; u=v*dx; sum+=(d1+u*(d2+u*d3))/(1.0+u*(d1+u*(e2+u*e3))) }
        endpoint := (d1+d2+d3)/(1.0+d1+e2+e3)
        result = 1.0/(dx*(endpoint+d1+2.0*sum)/2.0)
    } else if module_id == 2 {
        mut sign := -5.0
        mut partial := -1.0
        for _ in 0 .. int(steps) { sign = -sign; partial += sign }
        mut v := 0.0
        mut reciprocal_sum := 0.0
        u = partial
        x = 0.0
        for _ in 0 .. int(steps) { sign = -sign; partial += sign; u += 2.0; x=x+(sign-u); v=v-sign*u; reciprocal_sum=reciprocal_sum+sign/u }
        estimate := 4.0*reciprocal_sum/5.0+5.0/v
        result = estimate-31.25/(v*v*v)
    } else if module_id == 3 {
        dx := pi/(3.0*f64(steps))
        mut v := 0.0
        for _ in 1 .. int(steps) { v += 1.0; u=v*dx; w=u*u; sum+=u*sin_poly_alternating(w) }
        u=pi/3.0; w=u*u
        result=dx*(u*sin_poly_alternating(w)+2.0*sum)/2.0
    } else if module_id == 4 {
        dx := pi/(3.0*f64(steps))
        for i := i64(1); i < steps; i++ { u=f64(i)*dx; w=u*u; sum+=w*(w*(w*(w*(w*(b6*w+b5)+b4)+b3)+b2)+b1)+1.0 }
        u=pi/3.0; w=u*u
        endpoint:=w*(w*(w*(w*(w*(b6*w+b5)+b4)+b3)+b2)+b1)+1.0
        result=dx*(endpoint+1.0+2.0*sum)/2.0
    } else if module_id == 5 {
        dx := pi/(3.0*f64(steps))
        for i := i64(1); i < steps; i++ { u=f64(i)*dx; w=u*u; sum+=(u*sin_poly_legacy(w))/cos_poly(w) }
        u=pi/3.0; w=u*u
        result=dx*(u*sin_poly_legacy(w)/cos_poly(w)+2.0*sum)/2.0
    } else if module_id == 6 {
        dx := pi/(4.0*f64(steps))
        for i := i64(1); i < steps; i++ { u=f64(i)*dx; w=u*u; sum+=(u*sin_poly_legacy(w))*cos_poly(w) }
        u=pi/4.0; w=u*u
        result=dx*((u*sin_poly_legacy(w))*cos_poly(w)+2.0*sum)/2.0
    } else if module_id == 7 {
        finish := 102.3321513995275
        dx := finish/f64(steps)
        for i := i64(1); i < steps; i++ { x=f64(i)*dx; u=x*x; sum=sum-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0) }
        x=finish; u=x*x
        endpoint:=-1.0-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0)
        result=18.0*dx*(endpoint+2.0*sum)
    } else {
        dx := pi/(3.0*f64(steps))
        for i := i64(1); i < steps; i++ { u=f64(i)*dx; w=u*u; cosine:=cos_poly(w); sum+=cosine*cosine*u*sin_poly_legacy(w) }
        u=pi/3.0; w=u*u; cosine:=cos_poly(w)
        result=dx*((u*sin_poly_legacy(w))*cosine*cosine+2.0*sum)/2.0
    }
    return result
}
