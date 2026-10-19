from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List

fn dancing_search(universe:Int,row_count:Int,rows:List[Int],covered:Int,selected:Int,mut solutions:List[Int]):
    if covered==universe:
        solutions.append(selected)
        return
    let remaining=universe & (~covered)
    var best_col=-1
    var best_count=100
    for col in range(8):
        let bit=1<<col
        if (remaining&bit)==0:continue
        var candidates=0
        for r in range(row_count):
            if (rows[r]&bit)!=0 and (rows[r]&covered)==0:candidates+=1
        if candidates<best_count:
            best_count=candidates;best_col=col
    if best_col<0 or best_count==0:return
    let bit=1<<best_col
    for r in range(row_count):
        if (rows[r]&bit)!=0 and (rows[r]&covered)==0:
            dancing_search(universe,row_count,rows,covered|rows[r],selected|(1<<r),solutions)

@export("dancing_links")
fn dancing_links(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2:return -1
    let universe_size=input[0];let row_count=input[1]
    if universe_size<1 or universe_size>8 or row_count<0 or row_count>8 or length!=c_size_t(row_count+2):return -1
    let universe=(1<<Int(universe_size))-1
    var rows=List[Int](length=8,fill=0)
    for i in range(Int(row_count)):
        if input[i+2]<=0 or input[i+2]>Int64(universe):return -1
        rows[i]=Int(input[i+2])
    var solutions=List[Int](capacity=256)
    dancing_search(universe,Int(row_count),rows,0,0,solutions)
    for i in range(1,len(solutions)):
        let v=solutions[i];var j=i
        while j>0 and solutions[j-1]>v:solutions[j]=solutions[j-1];j-=1
        solutions[j]=v
    if len(solutions)>0 and (output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(len(solutions))):return -2
    for i in range(len(solutions)):output[i]=UInt8(solutions[i])
    return Int64(len(solutions))
