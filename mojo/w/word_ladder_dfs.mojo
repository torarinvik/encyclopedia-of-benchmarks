from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wld_pow26(e:Int)->Int64:
    var p:Int64=1;for _ in range(e):p*=26
    return p
fn wld_find(words:InlineArray[Int64,8],active:InlineArray[Bool,8],count:Int,c:Int64)->Int:
    for i in range(count):if active[i] and words[i]==c:return i
    return -1
fn wld_back(current:Int64,target:Int64,width:Int,words:InlineArray[Int64,8],count:Int,inout active:InlineArray[Bool,8],inout path:InlineArray[Int64,9],inout pathlen:Int)->Bool:
    if current==target:return True
    for position in range(width):
        let factor=wld_pow26(width-position-1);let digit=(current/factor)%26
        for replacement in range(26):
            let candidate=current+(Int64(replacement)-digit)*factor;let ix=wld_find(words,active,count,candidate)
            if ix<0:continue
            active[ix]=False;path[pathlen]=candidate;pathlen+=1
            if wld_back(candidate,target,width,words,count,active,path,pathlen):return True
            pathlen-=1;active[ix]=True
    return False
@export("word_ladder_dfs")
fn word_ladder_dfs(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>12:return -1
    let width=a[0];let begin=a[1];let target=a[2];let count=a[3]
    if width<1 or width>5 or count<0 or count>8 or n!=c_size_t(4+count):return -1
    let limit=wld_pow26(Int(width))
    if begin<0 or begin>=limit or target<0 or target>=limit:return -1
    var words=InlineArray[Int64,8]();var active=InlineArray[Bool,8]()
    for i in range(Int(count)):
        let x=a[4+i]
        if x<0 or x>=limit or (i>0 and x<=a[3+i]):return -1
        words[i]=x;active[i]=True
    var path=InlineArray[Int64,9]();var pathlen=0
    if wld_find(words,active,Int(count),target)>=0:
        path[0]=begin;pathlen=1
        if not wld_back(begin,target,Int(width),words,Int(count),active,path,pathlen):pathlen=0
    var fields=InlineArray[Int64,19]();var fc=0;fields[fc]=Int64(pathlen);fc+=1
    for i in range(pathlen):fields[fc]=path[i];fc+=1
    var remain=0
    for i in range(Int(count)):if active[i]:remain+=1
    fields[fc]=Int64(remain);fc+=1
    for i in range(Int(count)):if active[i]:fields[fc]=words[i];fc+=1
    let bytes=fc*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(fc):
        let bits=bitcast[UInt64](fields[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
