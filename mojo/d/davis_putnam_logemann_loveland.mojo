from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List

fn dpll_solve(positive:List[Int],negative:List[Int],variables:Int,clauses:Int,assigned0:Int,truth0:Int)->Bool:
    var assigned=assigned0;var truth=truth0;let universe=(1<<variables)-1
    while True:
        var changed=False;var all_satisfied=True
        for clause in range(clauses):
            let pos=positive[clause];let neg=negative[clause]
            if (pos&neg)!=0 or (pos&truth)!=0 or (neg&(assigned&(~truth)))!=0:continue
            all_satisfied=False
            let open=(pos|neg)&universe&(~assigned)
            if open==0:return False
            if (open&(open-1))==0:
                if (pos&open)!=0:truth|=open
                else:truth&=(~open)
                assigned|=open;changed=True;break
        if all_satisfied:return True
        if changed:continue
        var pos_occ=0;var neg_occ=0
        for clause in range(clauses):
            let pos=positive[clause];let neg=negative[clause]
            if (pos&neg)!=0 or (pos&truth)!=0 or (neg&(assigned&(~truth)))!=0:continue
            let open=(pos|neg)&universe&(~assigned)
            pos_occ|=pos&open;neg_occ|=neg&open
        let pure_true=pos_occ&(~neg_occ);let pure_false=neg_occ&(~pos_occ);let pure=pure_true|pure_false
        if pure!=0:
            truth=(truth|pure_true)&(~pure_false);assigned|=pure;continue
        break
    for variable in range(variables):
        let bit=1<<variable
        if (assigned&bit)==0:
            if dpll_solve(positive,negative,variables,clauses,assigned|bit,truth|bit):return True
            return dpll_solve(positive,negative,variables,clauses,assigned|bit,truth&(~bit))
    return False

@export("davis_putnam_logemann_loveland")
fn davis_putnam_logemann_loveland(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>62:return -1
    let variables=values[0];let clauses=values[1]
    if variables<0 or variables>5 or clauses<0 or clauses>10:return -1
    var positive=List[Int](length=10,fill=0);var negative=List[Int](length=10,fill=0)
    var pos=2
    for clause in range(Int(clauses)):
        if pos>=Int(length):return -1
        let count=values[pos];pos+=1
        if count<0 or count>5 or count>Int64(Int(length)-pos):return -1
        for _ in range(Int(count)):
            let literal=values[pos];pos+=1
            if literal==0 or literal < -variables or literal>variables:return -1
            var variable=literal
            if variable<0:variable=-variable
            let bit=1<<(Int(variable)-1)
            if literal>0:positive[clause]|=bit
            else:negative[clause]|=bit
    if pos!=Int(length):return -1
    if dpll_solve(positive,negative,Int(variables),Int(clauses),0,0):return 1
    return 0
