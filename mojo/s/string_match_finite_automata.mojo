from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn finite_next(p:UnsafePointer[Int64,ImmutAnyOrigin],plen:Int,state:Int,sym:Int64)->Int:
    if state<plen and sym==p[state]:return state+1
    var cand=state
    while cand>0:
        if p[cand-1]==sym:
            var matches=True
            for i in range(cand-1):if p[i]!=p[state-cand+i+1]:matches=False;break
            if matches:return cand
        cand-=1
    return 0
@export("string_match_finite_automata")
fn string_match_finite_automata(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>291:return -1
    let tv=v[0];let pv=v[1]
    if tv<0 or tv>256 or pv<1 or pv>32 or n!=c_size_t(2+tv+pv):return -1
    for i in range(2,Int(n)):if v[i]<0 or v[i]>127:return -1
    let tlen=Int(tv);let plen=Int(pv);let ps=2+tlen;var trans=InlineArray[Int16,33*128](fill=0)
    for state in range(plen+1):
        for sym in range(128):trans[state*128+sym]=Int16(finite_next(v.unsafe_ptr().offset(ps),plen,state,sym))
    var matches=InlineArray[Int32,256](fill=0);var mc=0;var state=0
    for i in range(tlen):state=Int(trans[state*128+Int(v[2+i])]);if state==plen:matches[mc]=Int32(i+1-plen);mc+=1
    let bytes=mc*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(mc):let bits=bitcast[UInt32](matches[i]);for b in range(4):o[i*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
