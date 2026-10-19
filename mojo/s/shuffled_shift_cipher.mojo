from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn shc_alnum(x:Int64)->Bool:return (x>=48 and x<=57) or (x>=65 and x<=90) or (x>=97 and x<=122)
@export("shuffled_shift_cipher")
fn shuffled_shift_cipher(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>279:return -1
    let pn=a[0];let tn=a[1];if pn<1 or pn>20 or tn<0 or tn>256 or n!=c_size_t(2+pn+tn):return -1
    var breaks=InlineArray[Bool,128]();var shift:Int64=0
    for i in range(Int(pn)):
        let c=a[i+2];if not shc_alnum(c):return -1;breaks[Int(c)]=True
        shift+=c if i%2==0 else -c
    for i in range(Int(tn)):
        let c=a[2+Int(pn)+i];if not ((c>=32 and c<=126) or c==9 or c==10):return -1
    let amount=Int(shift if shift>0 else pn)%97
    var alphabet=InlineArray[Int64,97]();var al=0
    for c in range(97,123):alphabet[al]=c;al+=1
    for c in range(65,91):alphabet[al]=c;al+=1
    for c in range(48,58):alphabet[al]=c;al+=1
    for c in range(33,127):if not shc_alnum(c):alphabet[al]=c;al+=1
    alphabet[al]=32;al+=1;alphabet[al]=9;al+=1;alphabet[al]=10;al+=1
    var key=InlineArray[Int64,97]();var kl=0;var segment=InlineArray[Int64,97]();var sl=0
    for i in range(al):
        let c=alphabet[i];segment[sl]=c;sl+=1
        if breaks[Int(c)] or i+1==al:
            while sl>0:sl-=1;key[kl]=segment[sl];kl+=1
    for i in range(Int(tn)):
        let c=a[2+Int(pn)+i];var idx=0;while idx<kl and key[idx]!=c:idx+=1
        if idx>=kl:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(tn):return -2
    for i in range(Int(tn)):
        let c=a[2+Int(pn)+i];var idx=0;while key[idx]!=c:idx+=1;o[i]=UInt8(key[(idx+amount)%97])
    return tn
