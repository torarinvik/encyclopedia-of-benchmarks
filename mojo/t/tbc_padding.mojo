from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("tbc_padding")
fn tbc_padding(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>259:return -1
    let op=a[0];let offset=a[1];let length=a[2]
    if op<0 or op>2 or length<0 or length>256 or n!=c_size_t(3+length):return -1
    if op==0:
        if offset<0 or offset>length or (offset==0 and length==0):return -1
    elif offset!=0:return -1
    var bytes=InlineArray[UInt8,256]()
    for i in range(Int(length)):
        if a[i+3]<0 or a[i+3]>255:return -1
        bytes[i]=UInt8(a[i+3])
    var result=InlineArray[UInt8,264]();var outlen=0
    if op==0:
        let prior=bytes[Int(offset)-1] if offset>0 else bytes[Int(length)-1]
        let pad:UInt8=0 if prior%2==1 else 255
        let count=length-offset
        let bits=bitcast[UInt64](count)
        for b in range(8):result[b]=UInt8((bits>>UInt(8*b))&255)
        outlen=8
        for i in range(Int(length)):result[outlen+i]=if i<Int(offset) else pad
        # Preserve original bytes before the padding start.
        for i in range(Int(offset)):result[outlen+i]=bytes[i]
        outlen+=Int(length)
    elif op==1:
        if length==0:outlen=0
        else:
            let last=bytes[Int(length)-1];let pad:UInt8=0 if last%2==0 else 255;var keep=Int(length)
            while keep>0 and bytes[keep-1]==pad:keep-=1
            outlen=keep
            for i in range(keep):result[i]=bytes[i]
    else:
        if length==0:return -1
        let last=bytes[Int(length)-1]
        if last!=0 and last!=255:return -1
        var count=0;while count<Int(length) and bytes[Int(length)-1-count]==last:count+=1
        let bits=bitcast[UInt64](Int64(count))
        for b in range(8):result[b]=UInt8((bits>>UInt(8*b))&255)
        outlen=8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(outlen):return -2
    for i in range(outlen):o[i]=result[i]
    return Int64(outlen)
