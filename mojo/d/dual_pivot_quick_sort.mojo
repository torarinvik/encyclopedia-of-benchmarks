from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
fn dp_swap(a:UnsafePointer[Int64,MutAnyOrigin],i:Int,j:Int):
    let t=a[i];a[i]=a[j];a[j]=t
fn dp_sort(a:UnsafePointer[Int64,MutAnyOrigin],low0:Int,high0:Int):
    var low=low0;var high=high0
    while high-low>2:
        if a[low]>a[high-1]:dp_swap(a,low,high-1)
        let p1=a[low];let p2=a[high-1];var less=low+1;var scan=low+1;var greater=high-2
        while scan<=greater:
            if a[scan]<p1:dp_swap(a,scan,less);less+=1
            elif a[scan]>=p2:
                while scan<greater and a[greater]>p2:greater-=1
                dp_swap(a,scan,greater);greater-=1
                if a[scan]<p1:dp_swap(a,scan,less);less+=1
            scan+=1
        let p1i=less-1;let p2i=greater+1;dp_swap(a,low,p1i);dp_swap(a,high-1,p2i)
        let ls=p1i-low;let ms=p2i-p1i-1;let rs=high-p2i-1
        if ls>=ms and ls>=rs:
            dp_sort(a,p1i+1,p2i);dp_sort(a,p2i+1,high);high=p1i
        elif ms>=rs:
            dp_sort(a,low,p1i);dp_sort(a,p2i+1,high);low=p1i+1;high=p2i
        else:
            dp_sort(a,low,p1i);dp_sort(a,p1i+1,p2i);low=p2i+1
    if high-low==2 and a[low]>a[low+1]:dp_swap(a,low,low+1)
@export("dual_pivot_quick_sort")
fn dual_pivot_quick_sort(values:UnsafePointer[Int64,MutAnyOrigin],length:c_size_t) abi("C"):
    if length>1:dp_sort(values,0,Int(length))
