from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn msort(mut a: InlineArray[Int64,25], start: Int, end: Int):
    for i in range(start+1,end):
        let x=a[i];var j=i
        while j>start and a[j-1]>x: a[j]=a[j-1];j-=1
        a[j]=x
fn mselect(mut a: InlineArray[Int64,25], n: Int, k: Int) -> Int64:
    var med=InlineArray[Int64,5](fill=0);var m=0
    for s in range(0,n,5):
        let e=min(s+5,n);msort(mut a,s,e);med[m]=a[(s+e)//2];m+=1
    for i in range(1,m):
        let x=med[i];var j=i
        while j>0 and med[j-1]>x:med[j]=med[j-1];j-=1
        med[j]=x
    let p=med[(m-1)//2];var lo=InlineArray[Int64,25](fill=0);var hi=InlineArray[Int64,25](fill=0);var lc=0;var hc=0
    for i in range(n):
        if a[i]<p:lo[lc]=a[i];lc+=1
        elif a[i]>p:hi[hc]=a[i];hc+=1
    if k<lc:return mselect(mut lo,lc,k)
    if k>lc:return mselect(mut hi,hc,k-lc-1)
    return p

@export("median_search")
fn median_search(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>28 or v[0]<1 or v[0]>25 or v[1]<0 or v[1]>=v[0] or Int(n)!=Int(v[0])+2:return -1
    let count=Int(v[0]);var a=InlineArray[Int64,25](fill=0)
    for i in range(count):
        let x=v[i+2]
        if x<0 or x>2147483647:return -1
        for j in range(i):if a[j]==x:return -1
        a[i]=x
    return mselect(mut a,count,Int(v[1]))
