from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn hmch_mod(x:Int64,m:Int)->Int:
    var r=x%Int64(m);if r<0:r+=Int64(m)
    return Int(r)
fn hmch_byte(h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*1099511628211
@export("hash_map_cuckoo_hashing")
fn hash_map_cuckoo_hashing(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130:return -1
    let cap0=a[0];let count=a[1]
    if cap0<16 or cap0>256 or (cap0&(cap0-1))!=0 or count<0 or count>128 or n!=c_size_t(count+2):return -1
    var keys=InlineArray[Int64,256](fill=-2147483648);let c=Int(cap0)
    var buckets=InlineArray[Int,256](fill=0)
    for i in range(Int(count)):
        let key=a[i+2]
        if key< -2147483647 or key>2147483647:return -1
        for j in range(i):if a[j+2]==key:return -1
        let h1=hmch_mod(key,c);let h2=hmch_mod(key/Int64(c),c)
        buckets[h1]+=1
    var class_b=true
    for i in range(Int(count)):for j in range(i):if hmch_mod(a[i+2],c)==hmch_mod(a[j+2],c):class_b=false
    let class_a=count==2 and hmch_mod(a[2],c)==hmch_mod(a[3],c) and hmch_mod(a[2]/Int64(c),c)!=hmch_mod(a[2],c)
    if not class_a and not class_b:return -1
    var cap=c
    if class_a:
        keys[hmch_mod(a[2]/Int64(cap),cap)]=a[2];keys[hmch_mod(a[3],cap)]=a[3]
    else:
        var size=0
        for i in range(Int(count)):
            let key=a[i+2];size+=1
            if Float64(size)/Float64(cap)>0.7:cap*=2
            let h=hmch_mod(key,Int(cap))
            if keys[h]!= -2147483648:return -1
            keys[h]=key
        var cleared=InlineArray[Int64,256](fill=-2147483648)
        for i in range(Int(count)):
            let key=a[i+2];let h=hmch_mod(key,Int(cap))
            if cleared[h]!= -2147483648:return -1
            cleared[h]=key
        keys=cleared
    var h:UInt64=14695981039346656037
    for word_i in range(Int(count)+1):
        let word:Int64=if word_i==0:Int64(count) else:
            let key=a[word_i+1];var ix=-1
            for s in range(cap):if keys[s]==key:ix=s
            ix
        let bits=bitcast[UInt64](word)
        for b in range(8):h=hmch_byte(h,UInt8((bits>>UInt(8*b))&255))
    return Int64(h&0x7fffffffffffffff)
