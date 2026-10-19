from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn morai_store(out: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8): out[pos + b] = UInt8((bits >> (8 * b)) & 255)

fn morai_push(mut h:InlineArray[Int64,256],mut size:Int,x:Int64,ismax:Bool):
    var i=size;size+=1
    while i>0:
        let p=(i-1)//2
        let bad=if ismax:h[p]<x else:h[p]>x
        if not bad:break
        h[i]=h[p];i=p
    h[i]=x
fn morai_pop(mut h:InlineArray[Int64,256],mut size:Int,ismax:Bool)->Int64:
    let result=h[0];size-=1;let last=h[size]
    if size>0:
        var i=0
        while i*2+1<size:
            var child=i*2+1
            if child+1<size:
                if (if ismax:h[child+1]>h[child] else:h[child+1]<h[child]):child+=1
            if not (if ismax:h[child]>last else:h[child]<last):break
            h[i]=h[child];i=child
        h[i]=last
    return result

@export("median_of_running_array_integer")
fn median_of_running_array_integer(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 257: return -1
    let count = v[0]
    if count < 1 or count > 256 or Int(n) != Int(count) + 1: return -1
    var lower = InlineArray[Int64, 256](fill=0)
    var upper = InlineArray[Int64, 256](fill=0)
    var lower_count=0;var upper_count=0
    var staged = InlineArray[Int64, 256](fill=0)
    for i in range(Int(count)):
        let x = v[i + 1]
        if x < -1000000 or x > 1000000: return -1
        if upper_count>0 and x<upper[0]:morai_push(mut lower,mut lower_count,x,True)
        else:morai_push(mut upper,mut upper_count,x,False)
        if lower_count>upper_count+1:morai_push(mut upper,mut upper_count,morai_pop(mut lower,mut lower_count,True),False)
        elif upper_count>lower_count+1:morai_push(mut lower,mut lower_count,morai_pop(mut upper,mut upper_count,False),True)
        if lower_count==upper_count:staged[i]=(lower[0]+upper[0])/2
        elif lower_count>upper_count:staged[i]=lower[0]
        else:staged[i]=upper[0]
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(Int(count) * 8): return -2
    for i in range(Int(count)): morai_store(out, i * 8, staged[i])
    return count * 8
