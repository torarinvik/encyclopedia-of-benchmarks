from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn motqs_median(a:Int64,b:Int64,c:Int64)->Int64:
    if a<=b:
        if b<=c:return b
        if a<=c:return c
        return a
    if b>=c:return b
    if a>=c:return c
    return a
fn motqs_partition(v:UnsafePointer[Int64,MutAnyOrigin],left:Int,right:Int)->Int:
    let mid=left+(right-left)//2;let pivot=motqs_median(v[left],v[mid],v[right]);var i=left;var j=right
    while True:
        while v[i]<pivot:i+=1
        while v[j]>pivot:j-=1
        if i>=j:return j
        let t=v[i];v[i]=v[j];v[j]=t;i+=1;j-=1
    return left
fn motqs_sort(v:UnsafePointer[Int64,MutAnyOrigin],l:Int,r:Int):
    if l>=r:return
    let p=motqs_partition(v,l,r);motqs_sort(v,l,p);motqs_sort(v,p+1,r)
@export("median_of_three_quick_sorter")
fn median_of_three_quick_sorter(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if n>256 or n<2 or v==UnsafePointer[Int64,MutAnyOrigin]():return
    motqs_sort(v,0,Int(n)-1)
