from std.memory import MutAnyOrigin, UnsafePointer
@export("pascal_triangle_row")
fn pascal_triangle_row(row:Int64,o:UnsafePointer[UInt8,MutAnyOrigin],cap:UInt64) abi("C")->Int64:
    if row<0 or row>33:return -1
    let count=Int(row)+1;let bytes=count*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<UInt64(bytes):return -2
    var a=InlineArray[UInt32,34](fill=1)
    for r in range(2,Int(row)+1):for c in range(r-1,0,-1):a[c]+=a[c-1]
    for i in range(count):for b in range(4):o[i*4+b]=UInt8((a[i]>>(8*b))&255)
    return Int64(bytes)
