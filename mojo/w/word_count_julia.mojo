from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wcj_lower(a:UnsafePointer[Int64,ImmutAnyOrigin],i:Int)->UInt8:
    let b=UInt8(a[i]);return b+32 if b>=65 and b<=90 else b
fn wcj_word(b:UInt8)->Bool:return (b>=97 and b<=122) or (b>=48 and b<=57) or b==95
fn wcj_less(a:UnsafePointer[Int64,ImmutAnyOrigin],s1:Int,l1:Int,s2:Int,l2:Int)->Bool:
    let common=min(l1,l2)
    for i in range(common):
        let x=wcj_lower(a,s1+i);let y=wcj_lower(a,s2+i)
        if x!=y:return x<y
    return l1<l2
@export("word_count_julia")
fn word_count_julia(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>1000 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if a[i]<0 or a[i]>127:return -1
    var starts=InlineArray[Int32,1000]();var lens=InlineArray[Int32,1000]();var counts=InlineArray[Int32,1000]();var unique=0;var i=0
    while i<Int(n):
        if not wcj_word(wcj_lower(a,i)):i+=1;continue
        let start=i
        while i<Int(n) and wcj_word(wcj_lower(a,i)):i+=1
        var length=i-start
        if i+1<Int(n) and a[i]==39 and wcj_word(wcj_lower(a,i+1)):length+=2;i+=2
        var pos=0
        while pos<unique and wcj_less(a,start,length,Int(starts[pos]),Int(lens[pos])):pos+=1
        if pos<unique and not wcj_less(a,start,length,Int(starts[pos]),Int(lens[pos])) and not wcj_less(a,Int(starts[pos]),Int(lens[pos]),start,length):counts[pos]+=1
        else:
            var j=unique
            while j>pos:starts[j]=starts[j-1];lens[j]=lens[j-1];counts[j]=counts[j-1];j-=1
            starts[pos]=Int32(start);lens[pos]=Int32(length);counts[pos]=1;unique+=1
    var required=0
    for k in range(unique):
        var x=Int(counts[k]);var digits=1
        while x>=10:x/=10;digits+=1
        required+=Int(lens[k])+1+digits+1
    if cap<c_size_t(required) or (required>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var p=0
    for k in range(unique):
        for j in range(Int(lens[k])):o[p]=wcj_lower(a,Int(starts[k])+j);p+=1
        o[p]=61;p+=1;var x=Int(counts[k]);var digits=InlineArray[UInt8,4]();var dc=0
        if x==0:digits[0]=48;dc=1
        while x>0:digits[dc]=UInt8(48+x%10);dc+=1;x/=10
        while dc>0:dc-=1;o[p]=digits[dc];p+=1
        o[p]=10;p+=1
    return Int64(p)
