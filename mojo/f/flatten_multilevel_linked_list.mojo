from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn fm_write(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):out[at+b]=UInt8((bits>>(8*b))&255)

@export("flatten_multilevel_linked_list")
fn flatten_multilevel_linked_list(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                                  output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>73:return -1
    let columns=input[0]
    if columns<0 or columns>8:return -1
    if columns==0:
        if length!=1:return -1
        return 0
    var vals=InlineArray[Int64,64](fill=0)
    var lens=InlineArray[Int32,8](fill=0)
    var cursor=1;var total=0
    for c in range(Int(columns)):
        if cursor>=Int(length) or input[cursor]<1 or input[cursor]>8:return -1
        let n=Int(input[cursor]);cursor+=1;lens[c]=Int32(n)
        if n>Int(length)-cursor:return -1
        for j in range(n):
            let x=input[cursor];cursor+=1
            if x< -1000 or x>1000 or (j>0 and x<vals[c*8+j-1]):return -1
            vals[c*8+j]=x
        total+=n
    if cursor!=Int(length):return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(total*8):return -2
    var merged=InlineArray[Int64,64](fill=0)
    var merged_len=0
    var c=Int(columns)-1
    while c>=0:
        var temp=InlineArray[Int64,64](fill=0)
        var i=0;var j=0;var k=0;let leftn=Int(lens[c])
        while i<leftn and j<merged_len:
            if vals[c*8+i]<merged[j]:temp[k]=vals[c*8+i];i+=1
            else:temp[k]=merged[j];j+=1
            k+=1
        while i<leftn:temp[k]=vals[c*8+i];i+=1;k+=1
        while j<merged_len:temp[k]=merged[j];j+=1;k+=1
        merged=temp;merged_len=k;c-=1
    for i in range(total):fm_write(output,i*8,merged[i])
    return Int64(total)
