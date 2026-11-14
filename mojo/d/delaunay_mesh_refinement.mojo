# Bounded circumcenter refinement; see package LICENSE.md.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sin, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dmr_round(numerator: Int64, denominator: Int64) -> Int64:
    let magnitude = -numerator if numerator < 0 else numerator
    let rounded = (magnitude + denominator//2)//denominator
    return -rounded if numerator < 0 else rounded

@export("delaunay_mesh_refinement")
fn delaunay_mesh_refinement(values: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=7 or values[0]!=3: return -1
    var x=InlineArray[Int64,3](fill=0)
    var y=InlineArray[Int64,3](fill=0)
    for i in range(3):
        x[i]=values[1+2*i]; y[i]=values[2+2*i]
        if x[i] < -100 or x[i]>100 or y[i] < -100 or y[i]>100: return -1
        for j in range(i):
            if x[i]==x[j] and y[i]==y[j]: return -1
    let area=(x[1]-x[0])*(y[2]-y[0])-(y[1]-y[0])*(x[2]-x[0])
    if area<=0: return -1
    for i in range(3):
        let j=(i+1)%3; let k=(i+2)%3
        if (x[j]-x[i])*(x[k]-x[i])+(y[j]-y[i])*(y[k]-y[i])<=0: return -1
    var sides=InlineArray[Float64,3](fill=0)
    for i in range(3):
        let j=(i+1)%3
        let dx=x[j]-x[i]; let dy=y[j]-y[i]
        sides[i]=sqrt(Float64(dx*dx+dy*dy))
    let shortest=min(sides[0],min(sides[1],sides[2]))
    let ratio=sides[0]*sides[1]*sides[2]/(2.0*Float64(area)*shortest)
    let refine=ratio>(1.0/(2.0*sin(3.14159265358979323846/9.0)))*(1.0+1.0e-12)
    let needed=152 if refine else 88
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed): return -2
    var words=InlineArray[Int64,19](fill=0)
    words[0]=4 if refine else 3
    for i in range(3):
        words[1+2*i]=x[i]*1000000
        words[2+2*i]=y[i]*1000000
    if refine:
        let bx=x[1]-x[0]; let by=y[1]-y[0]
        let cx=x[2]-x[0]; let cy=y[2]-y[0]
        let denominator=2*(bx*cy-by*cx)
        let b2=bx*bx+by*by; let c2=cx*cx+cy*cy
        words[7]=dmr_round((x[0]*denominator+cy*b2-by*c2)*1000000,denominator)
        words[8]=dmr_round((y[0]*denominator+bx*c2-cx*b2)*1000000,denominator)
        words[9]=3
        words[10]=0; words[11]=1; words[12]=3
        words[13]=1; words[14]=2; words[15]=3
        words[16]=2; words[17]=0; words[18]=3
    else:
        words[7]=1; words[8]=0; words[9]=1; words[10]=2
    for i in range(needed//8):
        let bits=bitcast[UInt64](words[i])
        for byte in range(8): output[8*i+byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return Int64(needed)
