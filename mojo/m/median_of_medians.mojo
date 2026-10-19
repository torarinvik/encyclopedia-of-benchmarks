from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

fn mom_sort(mut a:InlineArray[Int64,25],start:Int,end:Int):
    for i in range(start+1,end):
        let x=a[i];var j=i
        while j>start and a[j-1]>x:a[j]=a[j-1];j-=1
        a[j]=x
fn mom_select(mut a:InlineArray[Int64,25],n:Int,k:Int)->Int64:
    var medians=InlineArray[Int64,5](fill=0);var m=0
    for start in range(0,n,5):
        let end=min(start+5,n);mom_sort(mut a,start,end);medians[m]=a[(start+end)/2];m+=1
    for i in range(1,m):
        let x=medians[i];var j=i
        while j>0 and medians[j-1]>x:medians[j]=medians[j-1];j-=1
        medians[j]=x
    let pivot=medians[(m-1)/2]
    var lower=InlineArray[Int64,25](fill=0);var higher=InlineArray[Int64,25](fill=0);var lc=0;var hc=0
    for i in range(n):
        if a[i]<pivot:lower[lc]=a[i];lc+=1
        elif a[i]>pivot:higher[hc]=a[i];hc+=1
    if k<lc:return mom_select(mut lower,lc,k)
    if k>lc:return mom_select(mut higher,hc,k-lc-1)
    return pivot

@export("median_of_medians")
fn median_of_medians(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>28 or v[0]<1 or v[0]>25 or v[1]<0 or v[1]>=v[0] or n!=c_size_t(v[0]+2):return -1
    let count=Int(v[0]);var a=InlineArray[Int64,25](fill=0)
    for i in range(count):
        let x=v[i+2];if x<0 or x>2147483647:return -1
        for j in range(i):if a[j]==x:return -1
        a[i]=x
    return mom_select(mut a,count,Int(v[1]))
