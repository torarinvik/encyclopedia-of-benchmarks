from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn poly_gcd(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:let t=b;b=a%b;a=t
    return a
@export("polygon_points")
fn polygon_points(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66 or v[0]<3 or v[0]>32 or n!=c_size_t(1+2*v[0]):return -1
    let count=Int(v[0])
    for i in range(2*count):if v[1+i]<-1000 or v[1+i]>1000:return -1
    let ox=v[1];let oy=v[2];var area=Int64(0)
    for i in range(2,count):
        let x1=v[1+2*i]-ox;let y1=v[2+2*i]-oy;let x2=v[1+2*(i-1)]-ox;let y2=v[2+2*(i-1)]-oy
        area+=x1*y2-x2*y1
    area=area/2;if area<0:area=-area
    var boundary=Int64(count)
    for i in range(count):
        let j=(i+1)%count;var dx=v[1+2*i]-v[1+2*j];var dy=v[2+2*i]-v[2+2*j]
        if dx<0:dx=-dx
        if dy<0:dy=-dy
        boundary+=poly_gcd(dx,dy)-1
    return area+1-boundary/2
