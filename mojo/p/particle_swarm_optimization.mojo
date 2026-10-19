from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pso_rand(mut state:UInt64)->Float64:
    var x=state;x^=x<<13;x^=x>>7;x^=x<<17;state=x
    return Float64(x>>11)*1.1102230246251565e-16
fn pso_write(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Float64):
    let u=bitcast[UInt64](x)
    for b in range(8):o[p+b]=UInt8((u>>(8*b))&255)
@export("particle_swarm_optimization")
fn particle_swarm_optimization(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<=0:return -1
    let bytes=1006*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var state=UInt64(v[0]);var pos=InlineArray[Float64,250](fill=0.0);var vel=InlineArray[Float64,250](fill=0.0);var personal=InlineArray[Float64,250](fill=0.0);var pcost=InlineArray[Float64,50](fill=0.0);var global=InlineArray[Float64,5](fill=0.0);var history=InlineArray[Float64,1000](fill=0.0);var best=1.7976931348623157e308
    for p in range(50):
        var cost=0.0
        for d in range(5):let x=-10.0+20.0*pso_rand(mut state);pos[p*5+d]=x;personal[p*5+d]=x;cost+=x*x
        pcost[p]=cost
        if cost<best:best=cost;for d in range(5):global[d]=personal[p*5+d]
    var inertia=1.0
    for it in range(1000):
        for p in range(50):
            var pr=InlineArray[Float64,5](fill=0.0);var sr=InlineArray[Float64,5](fill=0.0)
            for d in range(5):pr[d]=pso_rand(mut state)
            for d in range(5):sr[d]=pso_rand(mut state)
            var cost=0.0
            for d in range(5):
                let ix=p*5+d;let cog=2.0*pr[d]*(personal[ix]-pos[ix]);let soc=2.0*sr[d]*(global[d]-pos[ix]);vel[ix]=inertia*vel[ix]+cog+soc;pos[ix]+=vel[ix];cost+=pos[ix]*pos[ix]
            if cost<pcost[p]:
                pcost[p]=cost
                for d in range(5):personal[p*5+d]=pos[p*5+d]
                if cost<best:best=cost;for d in range(5):global[d]=personal[p*5+d]
        history[it]=best;inertia*=0.99
    pso_write(o,0,best)
    for d in range(5):pso_write(o,8+8*d,global[d])
    for i in range(1000):pso_write(o,48+8*i,history[i])
    return Int64(bytes)
