from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn mpca_store(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

fn mpca_block_rows(concave: InlineArray[Int64,32], arbitrary: InlineArray[Int64,32],
    mut result: InlineArray[Int64,63], x1: Int, x2: Int, y1: Int, y2: Int,
    row1: Int, row2: Int, q1: Int, q2: Int):
    if row1 > row2: return
    let mid = row1 + (row2-row1)/2
    let x = x1+mid
    var best: Int64 = 9_223_372_036_854_775_807
    var best_q = q1
    for q in range(q1,q2+1):
        let y = y2-q
        let value = arbitrary[y]+concave[x-y]
        if value < best: best=value; best_q=q
    if best < result[x]: result[x]=best
    if row1 < mid: mpca_block_rows(concave,arbitrary,result,x1,x2,y1,y2,row1,mid-1,q1,best_q)
    if mid < row2: mpca_block_rows(concave,arbitrary,result,x1,x2,y1,y2,mid+1,row2,best_q,q2)

fn mpca_scan(concave: InlineArray[Int64,32], arbitrary: InlineArray[Int64,32],
    mut result: InlineArray[Int64,63], y_min: InlineArray[Int,63], y_max: InlineArray[Int,63],
    x1: Int, x2: Int, y1: Int, y2: Int):
    for x in range(x1,x2+1):
        let low=max(y_min[x],y1); let high=min(y_max[x],y2)
        if low <= high:
            for y in range(low,high+1):
                let value=arbitrary[y]+concave[x-y]
                if value < result[x]: result[x]=value

fn mpca_partition(concave: InlineArray[Int64,32], arbitrary: InlineArray[Int64,32],
    mut result: InlineArray[Int64,63], y_min: InlineArray[Int,63], y_max: InlineArray[Int,63],
    x_min: InlineArray[Int,32], x_max: InlineArray[Int,32],
    x1: Int,x2: Int,y1: Int,y2: Int):
    if x1>x2 or y1>y2: return
    if y_max[x1]>=y2 and y1>=y_min[x2]:
        mpca_block_rows(concave,arbitrary,result,x1,x2,y1,y2,0,x2-x1,0,y2-y1)
        return
    if (x2-x1)*(y2-y1)<1000:
        mpca_scan(concave,arbitrary,result,y_min,y_max,x1,x2,y1,y2)
        return
    if x2-x1>y2-y1:
        let mid=(x1+x2)/2
        let left_y2=min(y_max[mid],y2)
        if y1<=left_y2: mpca_partition(concave,arbitrary,result,y_min,y_max,x_min,x_max,x1,mid,y1,left_y2)
        let right_y1=max(y_min[mid],y1)
        if right_y1<=y2: mpca_partition(concave,arbitrary,result,y_min,y_max,x_min,x_max,mid+1,x2,right_y1,y2)
    else:
        let mid=(y1+y2)/2
        let left_x2=min(x_max[mid],x2)
        if x1<=left_x2: mpca_partition(concave,arbitrary,result,y_min,y_max,x_min,x_max,x1,left_x2,y1,mid)
        let right_x1=max(x_min[mid],x1)
        if right_x1<=x2: mpca_partition(concave,arbitrary,result,y_min,y_max,x_min,x_max,right_x1,x2,mid+1,y2)

@export("min_plus_convolution_concave_arbitrary")
fn min_plus_convolution_concave_arbitrary(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length<4 or length>67: return -1
    let n_arg=input[0]; let m_arg=input[1]
    if n_arg<1 or n_arg>32 or m_arg<1 or m_arg>32: return -1
    let n=Int(n_arg); let m=Int(m_arg)
    if length != c_size_t(2+n+m): return -1
    var concave=InlineArray[Int64,32](fill=0)
    var arbitrary=InlineArray[Int64,32](fill=0)
    for i in range(n+m):
        let value=input[2+i]
        if value<0 or value>1_000_000_000: return -1
        if i<n: concave[i]=value
        else: arbitrary[i-n]=value
    var i=0
    while i+2<n:
        if concave[i+1]-concave[i]<concave[i+2]-concave[i+1]: return -1
        i+=1
    let h=n+m-1; let bytes=8*h
    if bytes>504: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes): return -2
    var y_min=InlineArray[Int,63](fill=0); var y_max=InlineArray[Int,63](fill=0)
    var x_min=InlineArray[Int,32](fill=0); var x_max=InlineArray[Int,32](fill=0)
    var result=InlineArray[Int64,63](fill=9_223_372_036_854_775_807)
    for x in range(h):
        y_min[x]=if x>=n then x-n+1 else 0
        y_max[x]=min(m-1,x)
    for y in range(m): x_min[y]=y; x_max[y]=n-1+y
    mpca_partition(concave,arbitrary,result,y_min,y_max,x_min,x_max,0,h-1,0,m-1)
    for k in range(h): mpca_store(result[k],output,8*k)
    return Int64(bytes)
