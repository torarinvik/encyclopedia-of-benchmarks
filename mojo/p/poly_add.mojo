from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("poly_add")
fn poly_add(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>67:return -1
    let na=v[0]
    if na<1 or na>16:return -1
    let bi=Int(1+2*na)
    if n<=c_size_t(bi):return -1
    let nb=v[bi]
    if nb<1 or nb>16 or n!=c_size_t(2+2*(na+nb)):return -1
    let sa=1;let sb=bi+1
    for q in range(Int(na+nb)):
        let base=if q<Int(na):sa+2*q else:sb+2*(q-Int(na))
        let cnt=if q<Int(na):Int(na) else:Int(nb)
        let local=if q<Int(na):q else:q-Int(na)
        let coef=v[base];let deg=v[base+1]
        if coef < -1000000 or coef > 1000000 or deg<0 or deg>63:return -1
        if local>0 and deg>=v[base-2]:return -1
    var co=InlineArray[Int64,32](fill=0);var de=InlineArray[Int64,32](fill=0);var i=0;var j=0;var t=0
    while i<Int(na) and j<Int(nb):
        let da=v[sa+2*i+1];let db=v[sb+2*j+1]
        if da>db:co[t]=v[sa+2*i];de[t]=da;t+=1;i+=1
        elif da<db:co[t]=v[sb+2*j];de[t]=db;t+=1;j+=1
        else:co[t]=v[sa+2*i]+v[sb+2*j];de[t]=da;t+=1;i+=1;j+=1
    while i<Int(na):co[t]=v[sa+2*i];de[t]=v[sa+2*i+1];t+=1;i+=1
    while j<Int(nb):co[t]=v[sb+2*j];de[t]=v[sb+2*j+1];t+=1;j+=1
    let bytes=t*16
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for k in range(t):
        let a=UInt64(co[k]);let b=UInt64(de[k])
        for z in range(8):out[k*16+z]=UInt8((a>>(z*8))&255);out[k*16+8+z]=UInt8((b>>(z*8))&255)
    return Int64(bytes)
