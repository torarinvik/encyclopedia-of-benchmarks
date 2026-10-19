from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn fp_grow(mut order:InlineArray[Int32,8],minimum:Int64,mut result:Int64,
           masks:InlineArray[Int64,64],weights:InlineArray[Int64,64],length:Int,rank_limit:Int):
    for rank in range(rank_limit-1,-1,-1):
        let item=Int(order[rank]);let bit=Int64(1)<<UInt(item)
        var support:Int64=0
        for i in range(length):
            if (masks[i]&bit)!=0:support+=weights[i]
        if support<minimum:continue
        result+=1
        var ancestor:Int64=0
        for earlier in range(rank):ancestor|=Int64(1)<<UInt(Int(order[earlier]))
        var cm=InlineArray[Int64,64](fill=0);var cw=InlineArray[Int64,64](fill=0);var cn=0
        for i in range(length):
            if (masks[i]&bit)!=0:cm[cn]=masks[i]&ancestor;cw[cn]=weights[i];cn+=1
        fp_grow(order,minimum,mut result,cm,cw,cn,rank)

@export("frequent_pattern_growth")
fn frequent_pattern_growth(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>67:return -1
    let tx=input[0];let items=input[1];let minimum=input[2]
    if tx<1 or tx>64 or items<1 or items>8 or minimum<1 or minimum>tx or length!=c_size_t(3+tx):return -1
    let mask_limit=Int64(1)<<UInt(items)
    var masks=InlineArray[Int64,64](fill=0);var weights=InlineArray[Int64,64](fill=0)
    for i in range(Int(tx)):
        if input[3+i]<0 or input[3+i]>=mask_limit:return -1
        masks[i]=input[3+i];weights[i]=1
    var support=InlineArray[Int32,8](fill=0)
    for item in range(Int(items)):
        for i in range(Int(tx)):
            if (masks[i]&(Int64(1)<<UInt(item)))!=0:support[item]+=1
    var order=InlineArray[Int32,8](fill=0)
    for i in range(Int(items)):order[i]=Int32(i)
    for i in range(1,Int(items)):
        let val=order[i];var j=i
        while j>0 and (support[Int(order[j-1])]<support[Int(val)] or (support[Int(order[j-1])]==support[Int(val)] and order[j-1]>val)):
            order[j]=order[j-1];j-=1
        order[j]=val
    var result:Int64=0
    fp_grow(order,minimum,mut result,masks,weights,Int(tx),Int(items))
    return result
