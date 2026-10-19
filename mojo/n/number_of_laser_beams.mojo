from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("number_of_laser_beams")
fn number_of_laser_beams(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>4098:return -1
    let rows=a[0];let cols=a[1]
    if rows<1 or rows>64 or cols<1 or cols>64 or n!=c_size_t(2+rows*cols):return -1
    var total:Int64=0;var previous:Int64=0
    for r in range(Int(rows)):
        var devices:Int64=0
        for c in range(Int(cols)):
            let x=a[2+r*Int(cols)+c]
            if x==49:devices+=1
            elif x!=48:return -1
        if devices>0:
            total+=previous*devices;previous=devices
    return total
