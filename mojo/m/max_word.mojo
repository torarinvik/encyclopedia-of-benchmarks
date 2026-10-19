from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray

fn mw_lower(x:Int64)->Int64:
    return x+32 if x>=65 and x<=90 else x

@export("max_word")
fn max_word(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>514:return -1
    let textn=v[0]
    if textn<1 or textn>512 or n!=c_size_t(textn+1):return -1
    var text=InlineArray[Int64,512](fill=0)
    for i in range(Int(textn)):
        let x=v[i+1];let letter=(x>=65 and x<=90) or (x>=97 and x<=122)
        if x==32:
            if i==0 or i+1==Int(textn) or text[i-1]==32:return -1
        elif not letter or x==73:return -1
        text[i]=x
    var starts=InlineArray[Int,512](fill=0);var lens=InlineArray[Int,512](fill=0);var counts=InlineArray[Int,512](fill=0);var unique=0;var start=0
    while start<Int(textn):
        var end=start
        while end<Int(textn) and text[end]!=32:end+=1
        let wordlen=end-start;if wordlen>6:return -1
        var found=unique
        for key in range(unique):
            if lens[key]!=wordlen:continue
            var equal=True
            for off in range(wordlen):if mw_lower(text[starts[key]+off])!=mw_lower(text[start+off]):equal=False
            if equal:found=key;break
        if found==unique:starts[unique]=start;lens[unique]=wordlen;counts[unique]=1;unique+=1
        else:counts[found]+=1
        start=end+1
    var winner=0
    for key in range(1,unique):if counts[key]>counts[winner]:winner=key
    let resultlen=lens[winner]
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(resultlen):return -2
    let keepcase=unique==1 and counts[0]==1
    var staged=InlineArray[UInt8,6](fill=0)
    for i in range(resultlen):staged[i]=UInt8(text[starts[winner]+i] if keepcase else mw_lower(text[starts[winner]+i]))
    for i in range(resultlen):out[i]=staged[i]
    return Int64(resultlen)
