from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
@export("geohash")
fn geohash(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]< -90000000 or v[0]>90000000 or v[1]< -180000000 or v[1]>180000000:return -1
    let alphabet="0123456789bcdefghjkmnpqrstuvwxyz"
    let lat=Float64(v[0])/1000000.0;let lon=Float64(v[1])/1000000.0
    var latlo= -90.0;var lathi=90.0;var lonlo= -180.0;var lonhi=180.0;var buf=InlineArray[UInt8,12](fill=0)
    var bit=0;var value=0;var lonturn=True;var p=0
    while p<12:
        if lonturn:
            let mid=(lonlo+lonhi)/2.0
            if lon>mid:value|=1<<(4-bit);lonlo=mid
            else:lonhi=mid
        else:
            let mid=(latlo+lathi)/2.0
            if lat>mid:value|=1<<(4-bit);latlo=mid
            else:lathi=mid
        lonturn=not lonturn
        if bit<4:bit+=1
        else:buf[p]=UInt8(alphabet[value]);p+=1;bit=0;value=0
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<12:return -2
    for i in range(12):out[i]=buf[i]
    return 12
