from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn ddf_last(label:Int64,labels:List[Int64])->Int:
    var found= -1
    for i in range(len(labels)):if labels[i]==label:found=i
    return found
fn ddf_visit(node:Int,starts:List[Int],ends:List[Int],mut seen:List[Int]):
    if seen[node]!=0:return
    seen[node]=1
    for e in range(len(starts)):
        if starts[e]==node and seen[ends[e]]==0:ddf_visit(ends[e],starts,ends,seen)
@export("directed_dfs_forest_count")
fn directed_dfs_forest_count(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>129:return -1
    let ev=input[0]
    if ev<0 or ev>64 or length!=c_size_t(1+2*ev):return -1
    var labels=List[Int64](capacity=128);var starts=List[Int](capacity=64);var ends=List[Int](capacity=64)
    for e in range(Int(ev)):
        let sl=input[1+2*e];let el=input[2+2*e]
        if sl<0 or sl>63 or el<0 or el>63:return -1
        var start=ddf_last(sl,labels);var finish= -1
        if sl==el:
            if start<0:start=len(labels);labels.append(sl)
            finish=len(labels);labels.append(el)
        else:
            finish=ddf_last(el,labels)
            if start<0:start=len(labels);labels.append(sl)
            if finish<0:finish=len(labels);labels.append(el)
        starts.append(start);ends.append(finish)
    var marked=List[Int](length=len(labels),fill=0);var roots=0
    for r in range(len(labels)):
        if marked[r]!=0:continue
        var seen=List[Int](length=len(labels),fill=0);ddf_visit(r,starts,ends,seen)
        for i in range(len(labels)):if seen[i]!=0:marked[i]=1
        roots+=1
    return Int64(roots)
