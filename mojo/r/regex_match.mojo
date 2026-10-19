from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn regex_rec(v:UnsafePointer[Int64,ImmutAnyOrigin],textlen:Int,poff:Int,plen:Int,ti:Int,pi:Int)->Bool:
    if pi==plen:return ti==textlen
    let atom=v[poff+pi]
    if pi+1<plen and v[poff+pi+1]==42:
        if regex_rec(v,textlen,poff,plen,ti,pi+2):return True
        return ti<textlen and (atom==46 or atom==v[2+ti]) and regex_rec(v,textlen,poff,plen,ti+1,pi)
    return ti<textlen and (atom==46 or atom==v[2+ti]) and regex_rec(v,textlen,poff,plen,ti+1,pi+1)
@export("regex_match")
fn regex_match(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<0 or v[0]>12 or v[1]<0 or v[1]>20:return -1
    let tl=Int(v[0]);let pl=Int(v[1]);if n!=c_size_t(2+tl+pl):return -1
    for i in range(tl):if v[2+i]<97 or v[2+i]>122:return -1
    let start=2+tl
    for i in range(pl):
        let c=v[start+i]
        if not ((c>=97 and c<=122) or c==46 or c==42) or (c==42 and (i==0 or v[start+i-1]==42)):return -1
    return Int64(regex_rec(v,tl,start,pl,0,0))
