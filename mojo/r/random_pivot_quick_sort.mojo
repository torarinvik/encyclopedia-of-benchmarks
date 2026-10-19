from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
fn rpq_next(mut state:UInt64)->UInt64:
    state=(state*48271)%2147483647;let high=state
    state=(state*48271)%2147483647;let low=state
    return high*2147483647+low
fn rpq_part(v:UnsafePointer[Int64,MutAnyOrigin],low:Int,high:Int,mut state:UInt64)->Int:
    let pivot=low+Int(rpq_next(state)%UInt64(high-low));let pv=v[pivot];v[pivot]=v[high-1];v[high-1]=pv;var boundary=low
    for scan in range(low,high-1):
        if v[scan]<pv:let t=v[boundary];v[boundary]=v[scan];v[scan]=t;boundary+=1
    let t=v[boundary];v[boundary]=v[high-1];v[high-1]=t;return boundary
@export("random_pivot_quick_sort")
fn random_pivot_quick_sort(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C"):
    if n<2 or v==UnsafePointer[Int64,MutAnyOrigin]():return
    var lows=InlineArray[Int64,64](fill=0);var highs=InlineArray[Int64,64](fill=0);var top=0;var low=0;var high=Int(n);var state:UInt64=1
    while True:
        while high-low>1:
            let pivot=rpq_part(v,low,high,state);let left=pivot-low;let right=high-pivot-1
            if left<right:
                if right>1:lows[top]=Int64(pivot+1);highs[top]=Int64(high);top+=1
                high=pivot
            else:
                if left>1:lows[top]=Int64(low);highs[top]=Int64(pivot);top+=1
                low=pivot+1
        if top==0:break
        top-=1;low=Int(lows[top]);high=Int(highs[top])
