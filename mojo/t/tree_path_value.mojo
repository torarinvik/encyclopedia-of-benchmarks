from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("tree_path_value")
fn tree_path_value(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>121 or a[0]<1 or a[0]>14:return -1
    let depth=Int(a[0]);let count=Int(n)-1
    if count==0:return 0
    var vals=InlineArray[Int64,120]();var left=InlineArray[Int,120]();var right=InlineArray[Int,120]()
    for i in range(count):
        vals[i]=a[i+1];left[i]= -1;right[i]= -1
        if (i==0 and (vals[i]< -1000 or vals[i]>1000)) or (i>0 and (vals[i]<1 or vals[i]>1000)):return -1
    var row=0;var width=1
    while row<count:
        for col in range(width):
            let p=row+col;if p>=count:break
            let li=row+width+col;let ri=li+1
            if li<count:left[p]=li
            if ri<count:right[p]=ri
        row+=width;width+=1
    var pivot=0;var maximum=vals[0]
    while left[pivot]>=0:
        var sn=InlineArray[Int,16]();var ss=InlineArray[Int,16]();var sums=InlineArray[Int64,16]();var top=1
        sn[0]=pivot;ss[0]=depth;sums[0]=maximum
        while top>0:
            top-=1;let node=sn[top];let steps=ss[top];let sum=sums[top]
            if steps==0:
                if sum>maximum:maximum=sum;pivot=node
                continue
            if right[node]>=0:sn[top]=right[node];ss[top]=steps-1;sums[top]=sum+vals[right[node]];top+=1
            if left[node]>=0:sn[top]=left[node];ss[top]=steps-1;sums[top]=sum+vals[left[node]];top+=1
            elif sum>maximum:maximum=sum;pivot=node
    return maximum
