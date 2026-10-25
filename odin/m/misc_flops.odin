package misc_flops

import "core:c"

INVALID_RESULT :: f64(-1.0e300)
A1 :: f64(-0.1666666666671334); A2 :: f64(0.833333333809067e-2)
A3 :: f64(0.198412715551283e-3); A4 :: f64(0.27557589750762e-5)
A5 :: f64(0.2507059876207e-7); A6 :: f64(0.164105986683e-9)
B1 :: f64(-0.4999999999982); B2 :: f64(0.4166666664651e-1)
B3 :: f64(-0.1388888805755e-2); B4 :: f64(0.24801428034e-4)
B5 :: f64(-0.2754213324e-6); B6 :: f64(0.20189405e-8)
D1 :: f64(0.3999999946405e-1); D2 :: f64(0.96e-3); D3 :: f64(0.1233153e-5)
E2 :: f64(0.48e-3); E3 :: f64(0.411051e-6)

sin_poly_legacy :: proc(w: f64) -> f64 {
    value := A6
    value=value*w+A5; value=value*w+A4; value=value*w+A3
    value=value*w+A2; value=value*w+A1
    return value*w+1.0
}
sin_poly_alternating :: proc(w: f64) -> f64 {
    value := A6
    value=value*w-A5; value=value*w+A4; value=value*w-A3
    value=value*w+A2; value=value*w+A1
    return value*w+1.0
}
cos_poly :: proc(w: f64) -> f64 {
    value := B6
    value=value*w+B5; value=value*w+B4; value=value*w+B3
    value=value*w+B2; value=value*w+B1
    return value*w+1.0
}

@(export)
misc_flops :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 2 do return INVALID_RESULT
    module_id, steps := values[0], values[1]
    if module_id < 1 || module_id > 8 || steps < 2 || steps > 128 do return INVALID_RESULT
    pi := f64(3.14159265358979323846)
    sum, result, x, u, w := f64(0.0), f64(0.0), f64(0.0), f64(0.0), f64(0.0)
    if module_id == 1 {
        n := 2*steps; dx := 1.0/f64(n); v := f64(0.0)
        for i := i64(1); i < n; i += 1 { v+=1.0; u=v*dx; sum+=(D1+u*(D2+u*D3))/(1.0+u*(D1+u*(E2+u*E3))) }
        endpoint := (D1+D2+D3)/(1.0+D1+E2+E3); result=1.0/(dx*(endpoint+D1+2.0*sum)/2.0)
    } else if module_id == 2 {
        sign, partial := f64(-5.0), f64(-1.0)
        for i := i64(0); i < steps; i += 1 { sign=-sign; partial+=sign }
        v, reciprocal_sum := f64(0.0), f64(0.0); u=partial; x=0.0
        for i := i64(0); i < steps; i += 1 { sign=-sign; partial+=sign; u+=2.0; x=x+(sign-u); v=v-sign*u; reciprocal_sum=reciprocal_sum+sign/u }
        estimate := 4.0*reciprocal_sum/5.0+5.0/v; result=estimate-31.25/(v*v*v)
    } else if module_id == 3 {
        dx := pi/(3.0*f64(steps)); v := f64(0.0)
        for i := i64(1); i < steps; i += 1 { v+=1.0; u=v*dx; w=u*u; sum+=u*sin_poly_alternating(w) }
        u=pi/3.0; w=u*u; result=dx*(u*sin_poly_alternating(w)+2.0*sum)/2.0
    } else if module_id == 4 {
        dx := pi/(3.0*f64(steps))
        for i := i64(1); i < steps; i += 1 { u=f64(i)*dx; w=u*u; sum+=w*(w*(w*(w*(w*(B6*w+B5)+B4)+B3)+B2)+B1)+1.0 }
        u=pi/3.0; w=u*u; endpoint:=w*(w*(w*(w*(w*(B6*w+B5)+B4)+B3)+B2)+B1)+1.0; result=dx*(endpoint+1.0+2.0*sum)/2.0
    } else if module_id == 5 {
        dx := pi/(3.0*f64(steps))
        for i := i64(1); i < steps; i += 1 { u=f64(i)*dx; w=u*u; sum+=(u*sin_poly_legacy(w))/cos_poly(w) }
        u=pi/3.0; w=u*u; result=dx*(u*sin_poly_legacy(w)/cos_poly(w)+2.0*sum)/2.0
    } else if module_id == 6 {
        dx := pi/(4.0*f64(steps))
        for i := i64(1); i < steps; i += 1 { u=f64(i)*dx; w=u*u; sum+=(u*sin_poly_legacy(w))*cos_poly(w) }
        u=pi/4.0; w=u*u; result=dx*((u*sin_poly_legacy(w))*cos_poly(w)+2.0*sum)/2.0
    } else if module_id == 7 {
        finish := f64(102.3321513995275); dx := finish/f64(steps)
        for i := i64(1); i < steps; i += 1 { x=f64(i)*dx; u=x*x; sum=sum-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0) }
        x=finish; u=x*x; endpoint:=-1.0-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0); result=18.0*dx*(endpoint+2.0*sum)
    } else {
        dx := pi/(3.0*f64(steps))
        for i := i64(1); i < steps; i += 1 { u=f64(i)*dx; w=u*u; cosine:=cos_poly(w); sum+=cosine*cosine*u*sin_poly_legacy(w) }
        u=pi/3.0; w=u*u; cosine:=cos_poly(w); result=dx*((u*sin_poly_legacy(w))*cosine*cosine+2.0*sum)/2.0
    }
    return result
}
