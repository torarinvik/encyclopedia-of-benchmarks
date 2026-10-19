from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn tree_space(x:Int64)->Bool:return x==32 or (x>=9 and x<=13)
@export("serialize_deserialize_binary_tree")
fn serialize_deserialize_binary_tree(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>2200:return -1
    for i in range(Int(n)):if a[i]<0 or a[i]>127:return -1
    var out=InlineArray[UInt8,2200]();var written=0;var pos=0;var slots=1;var nodes=0;var tokens=0
    while pos<Int(n):
        if slots==0:return -1
        let start=pos
        while pos<Int(n) and a[pos]!=44:pos+=1
        let end=pos;if start==end:return -1
        var nulltok=(end-start==4 and a[start]==110 and a[start+1]==117 and a[start+2]==108 and a[start+3]==108)
        if tokens>0:out[written]=44;written+=1
        if nulltok:
            for c in range(4):out[written+c]=UInt8(a[start+c]);written+=4
        else:
            var x=start;var lo=end
            while x<lo and tree_space(a[x]):x+=1
            while lo>x and tree_space(a[lo-1]):lo-=1
            if x>=lo:return -1
            var neg=False
            if a[x]==45 or a[x]==43:neg=(a[x]==45);x+=1
            if x>=lo:return -1
            var num:Int64=0;let maxv:Int64=2147483647 if not neg else 2147483648
            while x<lo:
                if a[x]<48 or a[x]>57:return -1
                let d=a[x]-48;if num>(maxv-d)/10:return -1
                num=num*10+d;x+=1
            let value= -num if neg else num;nodes+=1;if nodes>127:return -1
            var digits=InlineArray[UInt8,12]();var dc=0;var q=value
            if q<0:q= -q
            if q==0:digits[dc]=48;dc+=1
            while q>0:digits[dc]=UInt8(48+q%10);q/=10;dc+=1
            if value<0:out[written]=45;written+=1
            for j in range(dc):out[written]=digits[dc-1-j];written+=1
        slots-=1;if not nulltok:slots+=2;tokens+=1
        if pos<Int(n):pos+=1;if pos==Int(n):return -1
    if slots!=0:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(written):return -2
    for i in range(written):o[i]=out[i]
    return Int64(written)
