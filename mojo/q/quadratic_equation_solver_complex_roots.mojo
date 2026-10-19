from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("quadratic_equation_solver_complex_roots")
fn quadratic_equation_solver_complex_roots(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>5:return -1.0e300
    let x=a[0];let b=a[1];let c=a[2];let component=a[3]
    if n!=4 or x==0 or x< -1000000 or x>1000000 or b< -1000000 or b>1000000 or c< -1000000 or c>1000000 or component<0 or component>3:return -1.0e300
    let disc=Float64(b*b-4*x*c);let den=2.0*Float64(x)
    if disc>0.0:
        if component>=2:return -1.0e300
        let root=sqrt(disc);return (-Float64(b)+root)/den if component==0 else (-Float64(b)-root)/den
    if disc==0.0:
        return -Float64(b)/den if component==0 else -1.0e300
    let real= -Float64(b)/den;let imag=sqrt(-disc)/abs(den)
    if component==0 or component==1:return real
    return imag if component==2 else -imag
