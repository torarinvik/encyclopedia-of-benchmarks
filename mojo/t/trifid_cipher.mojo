from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn tf_code(idx:Int,axis:Int)->UInt8:
    let divisor=9 if axis==0 else (3 if axis==1 else 1)
    return UInt8(49+(idx/divisor)%3)
fn tf_upper(v:Int64)->UInt8:
    let b=UInt8(v)
    return b-32 if b>=97 and b<=122 else b
@export("trifid_cipher")
fn trifid_cipher(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<31 or n>287:return -1
    let mode=a[0];let per=a[1];let textn=a[2];let an=a[3]
    if (mode!=0 and mode!=1) or per<1 or per>256 or textn<0 or textn>256 or an!=27 or n!=c_size_t(textn+31):return -1
    var alphabet=InlineArray[UInt8,27]();var alen=0
    for i in range(27):
        let v=a[4+Int(textn)+i]
        if v<0 or v>127:return -1
        let c=tf_upper(v)
        if c==32:continue
        for j in range(alen):if alphabet[j]==c:return -1
        alphabet[alen]=c;alen+=1
    if alen!=27:return -1
    var text=InlineArray[UInt8,256]();var tl=0
    for i in range(Int(textn)):
        let v=a[4+i]
        if v<0 or v>127:return -1
        let c=tf_upper(v)
        if c==32:continue
        var found=false
        for j in range(27):if alphabet[j]==c:found=true
        if not found:return -1
        text[tl]=c;tl+=1
    var result=InlineArray[UInt8,256]();var rl=0;var start=0
    while start<tl:
        let k=min(Int(per),tl-start);var digits=InlineArray[UInt8,768]()
        if mode==0:
            var m=0
            for axis in range(3):
                for i in range(k):
                    var idx=0
                    while alphabet[idx]!=text[start+i]:idx+=1
                    digits[m]=tf_code(idx,axis);m+=1
            for i in range(0,m,3):
                var idx=0
                while idx<27 and (tf_code(idx,0)!=digits[i] or tf_code(idx,1)!=digits[i+1] or tf_code(idx,2)!=digits[i+2]):idx+=1
                if idx>=27:return -1
                result[rl]=alphabet[idx];rl+=1
        else:
            for i in range(k):
                var idx=0
                while alphabet[idx]!=text[start+i]:idx+=1
                for d in range(3):digits[i*3+d]=tf_code(idx,d)
            for i in range(k):
                var idx=0
                while idx<27 and (tf_code(idx,0)!=digits[i] or tf_code(idx,1)!=digits[k+i] or tf_code(idx,2)!=digits[2*k+i]):idx+=1
                if idx>=27:return -1
                result[rl]=alphabet[idx];rl+=1
        start+=k
    if cap<c_size_t(rl) or (rl>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(rl):o[i]=result[i]
    return Int64(rl)
