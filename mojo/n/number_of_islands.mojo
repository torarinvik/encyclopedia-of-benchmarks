from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("number_of_islands")
fn number_of_islands(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>258:return -1
    let rows=a[0];let cols=a[1]
    if rows<1 or rows>16 or cols<1 or cols>16 or n!=c_size_t(2+rows*cols):return -1
    var cells=InlineArray[Int64,256]();var seen=InlineArray[Bool,256](fill=False)
    for i in range(Int(rows*cols)):
        if a[i+2]!=0 and a[i+2]!=1:return -1
        cells[i]=a[i+2]
    var islands:Int64=0
    for start in range(Int(rows*cols)):
        if cells[start]==1 and not seen[start]:
            islands+=1;var stack=InlineArray[Int64,256]();var top=1;stack[0]=start;seen[start]=True
            while top>0:
                top-=1;let pos=Int(stack[top]);let r=pos/Int(cols);let c=pos%Int(cols)
                if r>0:
                    let q=pos-Int(cols)
                    if cells[q]==1 and not seen[q]:seen[q]=True;stack[top]=q;top+=1
                if r+1<Int(rows):
                    let q=pos+Int(cols)
                    if cells[q]==1 and not seen[q]:seen[q]=True;stack[top]=q;top+=1
                if c>0:
                    let q=pos-1
                    if cells[q]==1 and not seen[q]:seen[q]=True;stack[top]=q;top+=1
                if c+1<Int(cols):
                    let q=pos+1
                    if cells[q]==1 and not seen[q]:seen[q]=True;stack[top]=q;top+=1
    return islands
