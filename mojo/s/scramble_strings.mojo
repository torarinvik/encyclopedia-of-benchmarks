from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn scramble_rec(a:UnsafePointer[Int64,ImmutAnyOrigin],b1:Int,b2:Int,i:Int,j:Int,l:Int,m:UnsafePointer[Int64,MutAnyOrigin])->Bool:
    let slot=(i*9+j)*9+l
    if m[slot]>=0:return m[slot]==1
    var same=True
    for z in range(l):if a[b1+i+z]!=a[b2+j+z]:same=False
    if same:m[slot]=1;return True
    var counts=InlineArray[Int32,26]()
    for z in range(l):counts[Int(a[b1+i+z]-97)]+=1;counts[Int(a[b2+j+z]-97)]-=1
    for z in range(26):if counts[z]!=0:m[slot]=0;return False
    for s in range(1,l):
        if scramble_rec(a,b1,b2,i,j,s,m) and scramble_rec(a,b1,b2,i+s,j+s,l-s,m):m[slot]=1;return True
        if scramble_rec(a,b1,b2,i,j+l-s,s,m) and scramble_rec(a,b1,b2,i+s,j,l-s,m):m[slot]=1;return True
    m[slot]=0;return False
@export("scramble_strings")
fn scramble_strings(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>19:return -1
    let l=a[0]
    if l<0 or l>8 or n!=c_size_t(2*l+1):return -1
    for i in range(1,Int(n)):if a[i]<97 or a[i]>122:return -1
    var memo=InlineArray[Int64,729]();for i in range(729):memo[i]= -1
    return 1 if scramble_rec(a,1,Int(l)+1,0,0,Int(l),memo.unsafe_ptr()) else 0
