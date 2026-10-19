from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
comptime MAX_TEXT=1024
fn word_cmp(v:UnsafePointer[Int64,ImmutAnyOrigin],a:Int,al:Int,b:Int,bl:Int)->Int:
    let lim=if al<bl:al else:bl
    for i in range(lim):
        if v[1+a+i]<v[1+b+i]:return -1
        if v[1+a+i]>v[1+b+i]:return 1
    if al<bl:return -1
    if al>bl:return 1
    return 0
@export("remove_duplicate")
fn remove_duplicate(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025 or v[0]<0 or v[0]>MAX_TEXT or Int(n)!=Int(v[0])+1:return -1
    for i in range(Int(v[0])):if v[i+1]!=32 and (v[i+1]<97 or v[i+1]>122):return -1
    var starts=InlineArray[Int64,512](fill=0);var lens=InlineArray[Int64,512](fill=0);var wc=0;var cur=0;let size=Int(v[0])
    while cur<size:
        if v[cur+1]==32:cur+=1;continue
        let st=cur
        while cur<size and v[cur+1]!=32:cur+=1
        starts[wc]=Int64(st);lens[wc]=Int64(cur-st);wc+=1
    for i in range(1,wc):
        let ks=starts[i];let kl=lens[i];var j=i
        while j>0 and word_cmp(v,Int(starts[j-1]),Int(lens[j-1]),Int(ks),Int(kl))>0:
            starts[j]=starts[j-1];lens[j]=lens[j-1];j-=1
        starts[j]=ks;lens[j]=kl
    var olen=0;var uniq=0
    for i in range(wc):
        if i>0 and word_cmp(v,Int(starts[i-1]),Int(lens[i-1]),Int(starts[i]),Int(lens[i]))==0:continue
        if uniq>0:olen+=1
        olen+=Int(lens[i]);uniq+=1
    if cap<c_size_t(olen) or (olen>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var w=0;uniq=0
    for i in range(wc):
        if i>0 and word_cmp(v,Int(starts[i-1]),Int(lens[i-1]),Int(starts[i]),Int(lens[i]))==0:continue
        if uniq>0:o[w]=32;w+=1
        for j in range(Int(lens[i])):o[w]=UInt8(v[1+Int(starts[i])+j]);w+=1
        uniq+=1
    return Int64(w)
