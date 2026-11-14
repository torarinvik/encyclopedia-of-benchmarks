from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn build(mut minimum: InlineArray[Int64, 256], input: UnsafePointer[Int64, ImmutAnyOrigin], node: Int, left: Int, right: Int):
    if right-left==1:
        minimum[node]=input[2+left]
        return
    let middle=(left+right)//2
    build(minimum,input,2*node,left,middle)
    build(minimum,input,2*node+1,middle,right)
    minimum[node]=min(minimum[2*node],minimum[2*node+1])

fn push(mut minimum: InlineArray[Int64, 256], mut lazy: InlineArray[Int64, 256], node: Int):
    for child in range(2*node,2*node+2):
        minimum[child]+=lazy[node]
        lazy[child]+=lazy[node]
    lazy[node]=0

fn add(mut minimum: InlineArray[Int64, 256], mut lazy: InlineArray[Int64, 256], node: Int, left: Int, right: Int, first: Int, last: Int, delta: Int64):
    if last<=left or right<=first: return
    if first<=left and right<=last:
        minimum[node]+=delta
        lazy[node]+=delta
        return
    push(minimum,lazy,node)
    let middle=(left+right)//2
    add(minimum,lazy,2*node,left,middle,first,last,delta)
    add(minimum,lazy,2*node+1,middle,right,first,last,delta)
    minimum[node]=min(minimum[2*node],minimum[2*node+1])

fn query(mut minimum: InlineArray[Int64, 256], mut lazy: InlineArray[Int64, 256], node: Int, left: Int, right: Int, first: Int, last: Int) -> Int64:
    if last<=left or right<=first: return 9223372036854775807
    if first<=left and right<=last: return minimum[node]
    push(minimum,lazy,node)
    let middle=(left+right)//2
    let a=query(minimum,lazy,2*node,left,middle,first,last)
    let b=query(minimum,lazy,2*node+1,middle,right,first,last)
    return min(a,b)

@export("range_add_range_min")
fn range_add_range_min(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>322: return -1
    if input[0]<1 or input[0]>64 or input[1]<1 or input[1]>64: return -1
    let n=Int(input[0]); let q=Int(input[1])
    if length!=c_size_t(2+n+4*q): return -1
    for i in range(n):
        if input[2+i]<-1000000 or input[2+i]>1000000: return -1
    var queries=0
    for i in range(q):
        let base=2+n+4*i
        let op=input[base]; let left=input[base+1]; let right=input[base+2]; let delta=input[base+3]
        if left<0 or left>=right or right>Int64(n): return -1
        if op==0:
            if delta < -100000 or delta > 100000: return -1
        elif op==1:
            if delta!=0: return -1
            queries+=1
        else: return -1
    if queries==0: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(8*queries): return -2
    var minimum=InlineArray[Int64,256](fill=0)
    var lazy=InlineArray[Int64,256](fill=0)
    build(minimum,input,1,0,n)
    var written=0
    for i in range(q):
        let base=2+n+4*i; let left=Int(input[base+1]); let right=Int(input[base+2])
        if input[base]==0:
            add(minimum,lazy,1,0,n,left,right,input[base+3])
        else:
            let bits=bitcast[UInt64](query(minimum,lazy,1,0,n,left,right))
            for byte in range(8): output[8*written+byte]=UInt8((bits >> UInt(8*byte)) & 255)
            written+=1
    return Int64(8*written)
