from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("monte_carlo_simulation")
fn monte_carlo_simulation(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<7 or n>520:return -1
    for i in range(Int(n)):if not is_finite(v[i]):return -1
    let s0=v[0];let strike=v[1];let rate=v[2];let vol=v[3];let t=v[4];let steps=Int(v[5]);let sims=Int(v[6])
    if s0<1.0 or s0>1000.0 or strike<0.0 or strike>2000.0 or rate < -0.25 or rate>0.25 or vol<0.0 or vol>0.5:return -1
    if (t!=0.25 and t!=0.5 and t!=1.0 and t!=2.0) or (steps!=1 and steps!=2 and steps!=4 and steps!=8 and steps!=16) or v[5]!=Float64(steps) or sims<1 or sims>32 or v[6]!=Float64(sims) or Int(n)!=7+steps*sims:return -1
    for i in range(7,Int(n)):if v[i] < -3.0 or v[i]>3.0:return -1
    let sq= sqrt(t/Float64(steps));let drift=(rate-0.5*vol*vol)*t;var pay=InlineArray[Float64,32](fill=0.0);var total=0.0
    for sim in range(sims):
        var w=0.0
        for j in range(steps):w+=sq*v[7+sim*steps+j]
        let terminal=s0*exp(drift+vol*w);let d=terminal-strike;pay[sim]=if d>0.0:d else:0.0
    for sim in range(sims):total+=pay[sim]
    let price=(total/Float64(sims))*exp(-rate*t)
    if not is_finite(price):return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    o[0]=price
    return 1
