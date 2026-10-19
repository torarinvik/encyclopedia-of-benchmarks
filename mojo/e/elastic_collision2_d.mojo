from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt, floor

@export("elastic_collision2_d")
fn elastic_collision2_d(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=12:return -1
    for i in [0,1,6,7]:if v[i]< -200000 or v[i]>200000:return -1
    for i in [2,3,8,9]:if v[i]< -5000 or v[i]>5000:return -1
    if v[4]<1000 or v[4]>100000 or v[10]<1000 or v[10]>100000 or v[5]<1 or v[5]>10000 or v[11]<1 or v[11]>10000:return -1
    let dx=Float64(v[6]-v[0]);let dy=Float64(v[7]-v[1]);let distance=sqrt(dx*dx+dy*dy)
    if distance==0.0:return -1
    var ox=Float64(v[2]);var oy=Float64(v[3])
    if not (distance<Float64(v[5]+v[11])):
        let nx=dx/distance;let ny=dy/distance
        let relative=(Float64(v[8]-v[2]))*nx+(Float64(v[9]-v[3]))*ny
        if relative<=0.0:
            let impulse= -2.0*relative/(1.0/Float64(v[4])+1.0/Float64(v[10]))
            ox-=impulse*nx/Float64(v[4]);oy-=impulse*ny/Float64(v[4])
    let qx=Int64(floor(ox+0.5));let qy=Int64(floor(oy+0.5))
    if qx< -32768 or qx>32767 or qy< -32768 or qy>32767:return -1
    return ((qx&65535)<<16)|(qy&65535)
