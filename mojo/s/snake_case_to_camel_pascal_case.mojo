from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("snake_case_to_camel_pascal_case")
fn snake_case_to_camel_pascal_case(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>257:return -1
    let mode=a[0];let count=Int(n)-1;if mode<0 or mode>1 or count<1 or count>256:return -1
    var chars=InlineArray[UInt8,256]();var upper=mode==1;var outn=0
    for i in range(count):
        let c=a[i+1];if c<0 or c>127:return -1
        if c==95:
            if i==0 or i==count-1 or a[i-1]==95:return -1
            upper=true
        elif (c>=97 and c<=122) or (c>=48 and c<=57):
            chars[outn]=UInt8(c-32 if upper and c>=97 and c<=122 else c);outn+=1;upper=false
        else:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(outn):return -2
    for i in range(outn):o[i]=chars[i]
    return outn
