from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("gaussian_legendre")
fn gaussian_legendre(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=7:return -1.0e300
    let order=Int(v[0]);if order<1 or order>5 or v[1]< -5000 or v[1]>5000 or v[2]< -5000 or v[2]>5000:return -1.0e300
    for i in range(3,7):if v[i]< -10000 or v[i]>10000:return -1.0e300
    var nodes=InlineArray[Float64,5](fill=0.0);var weights=InlineArray[Float64,5](fill=0.0)
    if order==1:nodes[0]=0.0;weights[0]=2.0
    elif order==2:
        nodes[0]= -0.5773502692;nodes[1]=0.5773502692;weights[0]=1.0;weights[1]=1.0
    elif order==3:
        nodes[0]= -0.7745966692;nodes[1]=0.0;nodes[2]=0.7745966692;weights[0]=0.5555555556;weights[1]=0.8888888889;weights[2]=0.5555555556
    elif order==4:
        nodes[0]= -0.8611363116;nodes[1]= -0.3399810436;nodes[2]=0.3399810436;nodes[3]=0.8611363116
        weights[0]=0.3478548451;weights[1]=0.6521451549;weights[2]=0.6521451549;weights[3]=0.3478548451
    else:
        nodes[0]= -0.9061798459;nodes[1]= -0.5384693101;nodes[2]=0.0;nodes[3]=0.5384693101;nodes[4]=0.9061798459
        weights[0]=0.2369268851;weights[1]=0.4786286705;weights[2]=0.5688888889;weights[3]=0.4786286705;weights[4]=0.2369268851
    let a=Float64(v[1])/1000.0;let b=Float64(v[2])/1000.0
    let c0=Float64(v[3])/1000.0;let c1=Float64(v[4])/1000.0;let c2=Float64(v[5])/1000.0;let c3=Float64(v[6])/1000.0
    var sum=0.0
    for i in range(order):
        let x=(b+a)/2.0+(b-a)*nodes[i]/2.0;let x2=x*x;let x3=x2*x
        let f=c0+c1*x+c2*x2+c3*x3;sum+=weights[i]*f
    return sum*(b-a)/2.0
