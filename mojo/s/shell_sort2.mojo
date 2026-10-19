from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("shell_sort2")
fn shell_sort2(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    let gaps=InlineArray[Int32,8](701,301,132,57,23,10,4,1)
    for z in range(8):
        let gap=Int(gaps[z]);var i=gap
        while i<Int(n):
            let key=a[i];var j=i
            while j>=gap and a[j-gap]>key:a[j]=a[j-gap];j-=gap
            a[j]=key;i+=1
