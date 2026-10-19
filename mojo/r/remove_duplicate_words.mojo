from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
comptime MAX=4096
fn ws(x:Int64)->Bool:return x==32 or (x>=9 and x<=13)
@export("remove_duplicate_words")
fn remove_duplicate_words(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4097 or v[0]<0 or v[0]>MAX or Int(n)!=Int(v[0])+1:return -1
    let size=Int(v[0]);for i in range(size):if v[i+1]<0 or v[i+1]>127:return -1
    var starts=InlineArray[Int64,2049](fill=0);var lens=InlineArray[Int64,2049](fill=0);var wc=0;var start=0;var outlen=0
    for boundary in range(size+1):
        if boundary<size and not ws(v[boundary+1]):continue
        let ln=boundary-start;var dup=False
        for j in range(wc):
            if Int(lens[j])!=ln:continue
            var eq=True
            for k in range(ln):if v[1+Int(starts[j])+k]!=v[1+start+k]:eq=False
            if eq:dup=True;break
        if not dup:
            if wc>=2049:return -1
            starts[wc]=Int64(start);lens[wc]=Int64(ln);if wc>0:outlen+=1;outlen+=ln;wc+=1
        if boundary<size:start=boundary+1
    if cap<c_size_t(outlen) or (outlen>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var w=0
    for j in range(wc):
        if j>0:o[w]=32;w+=1
        for k in range(Int(lens[j])):o[w]=UInt8(v[1+Int(starts[j])+k]);w+=1
    return Int64(w)
