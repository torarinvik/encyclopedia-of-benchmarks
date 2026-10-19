from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
comptime LWE_MOD=3329
fn lwe_byte(h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*UInt64(1099511628211)
fn lwe_word(h:UInt64,x:Int64)->UInt64:
    let b=UInt64(x);return lwe_byte(lwe_byte(h,UInt8(b&255)),UInt8((b>>8)&255))
@export("encrypt_and_decrypt")
fn lwe_encryption(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>8358:return -1
    let m=v[0]
    if m<1 or m>4:return -1
    let secret=1+Int(m);let matrix=secret+32;let errors=matrix+4096;let subsets=errors+128;let subset_count=Int(m)*8*128
    if n!=c_size_t(subsets+subset_count):return -1
    for i in range(Int(m)):if v[1+i]<0 or v[1+i]>255:return -1
    for i in range(32):if v[secret+i]<0 or v[secret+i]>=LWE_MOD:return -1
    for i in range(4096):if v[matrix+i]<0 or v[matrix+i]>=LWE_MOD:return -1
    for i in range(128):if v[errors+i]<0 or v[errors+i]>6:return -1
    for i in range(subset_count):if v[subsets+i]!=0 and v[subsets+i]!=1:return -1
    var public=InlineArray[Int64,128](fill=0)
    for row in range(128):
        var sum:Int64=0
        for col in range(32):sum+=v[matrix+row*32+col]*v[secret+col]
        var reduced=(sum+v[errors+row]-3)%LWE_MOD
        if reduced<0:reduced+=LWE_MOD
        public[row]=reduced
    var hash:UInt64=14695981039346656037;var cursor=subsets
    for bi in range(Int(m)):
        let message=UInt8(v[1+bi]);var decoded:UInt8=0
        for bit in range(8):
            let message_bit=Int64((message>>(7-bit))&1);var accum=InlineArray[Int64,32](fill=0);var vacc=message_bit*(LWE_MOD//2)
            for row in range(128):
                let selected=v[cursor];cursor+=1
                if selected!=0:
                    for col in range(32):accum[col]+=v[matrix+row*32+col]
                    vacc+=public[row]
            var u=InlineArray[Int64,32](fill=0)
            for col in range(32):
                u[col]=accum[col]%LWE_MOD;hash=lwe_word(hash,u[col])
            let ciphertext_v=vacc%LWE_MOD;hash=lwe_word(hash,ciphertext_v);var dot:Int64=0
            for col in range(32):dot+=u[col]*v[secret+col]
            var difference=(ciphertext_v-dot)%LWE_MOD
            if difference<0:difference+=LWE_MOD
            let dec:Int64=if difference>=832 and difference<2496:1 else:0
            decoded=(decoded<<1)|UInt8(dec)
        hash=lwe_byte(hash,decoded)
    return Int64(hash&UInt64(0x7fffffffffffffff))
