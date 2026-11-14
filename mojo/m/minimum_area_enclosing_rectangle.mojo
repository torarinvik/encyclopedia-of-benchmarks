from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn maer_projection(input: UnsafePointer[Int64, ImmutAnyOrigin], index: Int, dx: Int64, dy: Int64, axis: Int) -> Int64:
    let x=input[1+2*index]
    let y=input[2+2*index]
    return dx*y-dy*x if axis==2 else dx*x+dy*y

@export("minimum_area_enclosing_rectangle")
fn minimum_area_enclosing_rectangle(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64, ImmutAnyOrigin]() or length<7 or length>34: return -1
    if input[0]<3 or input[0]>16: return -1
    let n=Int(input[0])
    if length!=c_size_t(1+2*n): return -1
    for i in range(1,Int(length)):
        if input[i]< -100 or input[i]>100: return -1
    for i in range(n):
        let next=(i+1)%n
        let ax=input[1+2*i]
        let ay=input[2+2*i]
        let dx=input[1+2*next]-ax
        let dy=input[2+2*next]-ay
        for j in range(n):
            if j!=i and j!=next and dx*(input[2+2*j]-ay)-dy*(input[1+2*j]-ax)<=0: return -1
    let first_dx=input[3]-input[1]
    let first_dy=input[4]-input[2]
    var supports=InlineArray[Int,3](fill=0)
    for i in range(1,n):
        for axis in range(3):
            let current=maer_projection(input,supports[axis],first_dx,first_dy,axis)
            let candidate=maer_projection(input,i,first_dx,first_dy,axis)
            if (axis==1 and candidate<current) or (axis!=1 and candidate>current): supports[axis]=i
    var best_num: Int64=0
    var best_den: Int64=1
    for i in range(n):
        let next=(i+1)%n
        let ax=input[1+2*i]
        let ay=input[2+2*i]
        let dx=input[1+2*next]-ax
        let dy=input[2+2*next]-ay
        for axis in range(3):
            for _ in range(n):
                let following=(supports[axis]+1)%n
                let current=maer_projection(input,supports[axis],dx,dy,axis)
                let candidate=maer_projection(input,following,dx,dy,axis)
                if (axis==1 and candidate<=current) or (axis!=1 and candidate>=current): supports[axis]=following
                else: break
        let span=maer_projection(input,supports[0],dx,dy,0)-maer_projection(input,supports[1],dx,dy,1)
        let thickness=maer_projection(input,supports[2],dx,dy,2)-(dx*ay-dy*ax)
        let numerator=span*thickness
        let denominator=dx*dx+dy*dy
        if i==0 or numerator*best_den<best_num*denominator:
            best_num=numerator
            best_den=denominator
    var a=best_num
    var b=best_den
    while b!=0:
        let remainder=a%b
        a=b
        b=remainder
    var words=InlineArray[Int64,2](fill=0)
    words[0]=best_num//a
    words[1]=best_den//a
    if output==UnsafePointer[UInt8, MutAnyOrigin]() or capacity<16: return -2
    for i in range(2):
        var bits=bitcast[UInt64](words[i])
        for j in range(8):
            output[8*i+j]=UInt8(bits & 255)
            bits>>=8
    return 16
