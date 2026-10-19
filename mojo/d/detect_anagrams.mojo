from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn ana_index(c:Int64)->Int:
    if c>=65 and c<=90:return Int(c-65)
    return Int(c-97)
fn ana_letter(c:Int64)->Bool:return (c>=65 and c<=90) or (c>=97 and c<=122)
@export("detect_anagrams")
fn detect_anagrams(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>290:return -1
    let sn=input[0]
    if sn<0 or sn>16:return -1
    var offset=1+Int(sn)
    if offset>=Int(length):return -1
    var sc=List[Int](length=26,fill=0)
    for i in range(Int(sn)):
        let c=input[1+i]
        if not ana_letter(c):return -1
        sc[ana_index(c)]+=1
    let countv=input[offset]
    if countv<0 or countv>16:return -1
    let count=Int(countv);offset+=1;var words=List[Int](capacity=16);var starts=List[Int](capacity=16);var matches=List[Int](capacity=16)
    for w in range(count):
        if offset>=Int(length) or input[offset]<0 or input[offset]>16:return -1
        let wn=Int(input[offset]);offset+=1
        if offset+wn>Int(length):return -1
        let start=offset;var counts=List[Int](length=26,fill=0)
        for i in range(26):counts[i]=sc[i]
        var identical=wn==Int(sn)
        for i in range(wn):
            let c=input[offset+i]
            if not ana_letter(c):return -1
            counts[ana_index(c)]-=1
            if identical and ana_index(c)!=ana_index(input[1+i]):identical=false
        var same=wn==Int(sn)
        for i in range(26):if counts[i]!=0:same=false
        if same and not identical:matches.append(w)
        starts.append(start);words.append(wn);offset+=wn
    if offset!=Int(length):return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    var needed=1
    for k in range(len(matches)):needed+=words[matches[k]]+1
    if capacity<c_size_t(needed):return -2
    var pos=0
    for k in range(len(matches)):
        let w=matches[k];let start=starts[w];let wn=words[w]
        for j in range(wn):out[pos]=UInt8(input[start+j]);pos+=1
        out[pos]=10;pos+=1
    out[pos]=0
    return Int64(len(matches))
