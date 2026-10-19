from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sin
@export("simple_pendulum_rk4")
fn simple_pendulum_rk4(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=5:return -1
    let mins=InlineArray[Float64,5](10000,100000,-3141593,-100000000,1);let maxs=InlineArray[Float64,5](100000000,20000000,3141593,100000000,100000)
    for i in range(5):let x=a[i];if x!=x or x<Float64(Int64(x)) or x>Float64(Int64(x)) or x<mins[i] or x>maxs[i]:return -1
    let l=a[0]/1e6;let g=a[1]/1e6;let th=a[2]/1e6;let om=a[3]/1e6;let dt=a[4]/1e6;let scale=g/l
    let k1t=om;let k1o= -scale*sin(th);let k2t=om+0.5*dt*k1o;let k2o= -scale*sin(th+0.5*dt*k1t);let k3t=om+0.5*dt*k2o;let k3o= -scale*sin(th+0.5*dt*k2t);let k4t=om+dt*k3o;let k4o= -scale*sin(th+dt*k3t)
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<2:return -2
    o[0]=th+dt/6.0*(k1t+2*k2t+2*k3t+k4t);o[1]=om+dt/6.0*(k1o+2*k2o+2*k3o+k4o);return 2
