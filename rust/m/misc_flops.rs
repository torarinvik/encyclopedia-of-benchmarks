const INVALID_RESULT: f64 = -1.0e300;
const A1:f64=-0.1666666666671334; const A2:f64=0.833333333809067e-2;
const A3:f64=0.198412715551283e-3; const A4:f64=0.27557589750762e-5;
const A5:f64=0.2507059876207e-7; const A6:f64=0.164105986683e-9;
const B1:f64=-0.4999999999982; const B2:f64=0.4166666664651e-1;
const B3:f64=-0.1388888805755e-2; const B4:f64=0.24801428034e-4;
const B5:f64=-0.2754213324e-6; const B6:f64=0.20189405e-8;
const D1:f64=0.3999999946405e-1; const D2:f64=0.96e-3; const D3:f64=0.1233153e-5;
const E2:f64=0.48e-3; const E3:f64=0.411051e-6;

fn sin_poly_legacy(w:f64)->f64 { let mut value=A6; value=value*w+A5; value=value*w+A4; value=value*w+A3; value=value*w+A2; value=value*w+A1; value*w+1.0 }
fn sin_poly_alternating(w:f64)->f64 { let mut value=A6; value=value*w-A5; value=value*w+A4; value=value*w-A3; value=value*w+A2; value=value*w+A1; value*w+1.0 }
fn cos_poly(w:f64)->f64 { let mut value=B6; value=value*w+B5; value=value*w+B4; value=value*w+B3; value=value*w+B2; value=value*w+B1; value*w+1.0 }

#[no_mangle]
pub unsafe extern "C" fn misc_flops(values:*const i64,length:usize)->f64 {
    if values.is_null() || length!=2 { return INVALID_RESULT; }
    let module_id=*values; let steps=*values.add(1);
    if !(1..=8).contains(&module_id) || !(2..=128).contains(&steps) { return INVALID_RESULT; }
    let mut sum=0.0; let mut result=0.0; let mut x=0.0; let mut u=0.0; let mut w=0.0;
    let pi=3.14159265358979323846_f64;
    if module_id==1 {
        let n=2*steps; let dx=1.0/n as f64; let mut v=0.0;
        for _ in 1..n { v+=1.0; u=v*dx; sum+=(D1+u*(D2+u*D3))/(1.0+u*(D1+u*(E2+u*E3))); }
        let endpoint=(D1+D2+D3)/(1.0+D1+E2+E3); result=1.0/(dx*(endpoint+D1+2.0*sum)/2.0);
    } else if module_id==2 {
        let mut sign=-5.0; let mut partial=-1.0;
        for _ in 0..steps { sign=-sign; partial+=sign; }
        let mut v=0.0; let mut reciprocal_sum=0.0; u=partial; x=0.0;
        for _ in 0..steps { sign=-sign; partial+=sign; u+=2.0; x=x+(sign-u); v=v-sign*u; reciprocal_sum=reciprocal_sum+sign/u; }
        let estimate=4.0*reciprocal_sum/5.0+5.0/v; result=estimate-31.25/(v*v*v);
    } else if module_id==3 {
        let dx=pi/(3.0*steps as f64); let mut v=0.0;
        for _ in 1..steps { v+=1.0; u=v*dx; w=u*u; sum+=u*sin_poly_alternating(w); }
        u=pi/3.0; w=u*u; result=dx*(u*sin_poly_alternating(w)+2.0*sum)/2.0;
    } else if module_id==4 {
        let dx=pi/(3.0*steps as f64);
        for i in 1..steps { u=i as f64*dx; w=u*u; sum+=w*(w*(w*(w*(w*(B6*w+B5)+B4)+B3)+B2)+B1)+1.0; }
        u=pi/3.0; w=u*u; let endpoint=w*(w*(w*(w*(w*(B6*w+B5)+B4)+B3)+B2)+B1)+1.0; result=dx*(endpoint+1.0+2.0*sum)/2.0;
    } else if module_id==5 {
        let dx=pi/(3.0*steps as f64);
        for i in 1..steps { u=i as f64*dx; w=u*u; sum+=(u*sin_poly_legacy(w))/cos_poly(w); }
        u=pi/3.0; w=u*u; result=dx*(u*sin_poly_legacy(w)/cos_poly(w)+2.0*sum)/2.0;
    } else if module_id==6 {
        let dx=pi/(4.0*steps as f64);
        for i in 1..steps { u=i as f64*dx; w=u*u; sum+=(u*sin_poly_legacy(w))*cos_poly(w); }
        u=pi/4.0; w=u*u; result=dx*((u*sin_poly_legacy(w))*cos_poly(w)+2.0*sum)/2.0;
    } else if module_id==7 {
        let end=102.3321513995275; let dx=end/steps as f64;
        for i in 1..steps { x=i as f64*dx; u=x*x; sum=sum-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0); }
        x=end; u=x*x; let endpoint=-1.0-1.0/(x+1.0)-x/(u+1.0)-u/(x*u+1.0); result=18.0*dx*(endpoint+2.0*sum);
    } else {
        let dx=pi/(3.0*steps as f64);
        for i in 1..steps { u=i as f64*dx; w=u*u; let c=cos_poly(w); sum+=c*c*u*sin_poly_legacy(w); }
        u=pi/3.0; w=u*u; let c=cos_poly(w); result=dx*((u*sin_poly_legacy(w))*c*c+2.0*sum)/2.0;
    }
    if result.is_finite() { result } else { INVALID_RESULT }
}
