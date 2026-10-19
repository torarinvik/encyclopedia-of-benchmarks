from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn depreciation_write(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Float64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("depreciation")
fn depreciation(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>20:return -1
    let method=input[0];var years=0;var purchase_scaled:Int64=0;var residual_scaled:Int64=0;var rate:Float64=0.0
    if method==0 or method==3 or method==4:
        if length!=4 or input[1]<1 or input[1]>16:return -1
        years=Int(input[1]);purchase_scaled=input[2];residual_scaled=input[3]
    elif method==1:
        if length!=5 or input[1]<1 or input[1]>16 or input[4]<1 or input[4]>1000000:return -1
        years=Int(input[1]);purchase_scaled=input[2];residual_scaled=input[3];rate=Float64(input[4])/1000000.0
    elif method==2:
        if length<5:return -1
        years=Int(length)-4
        if years>16 or input[3]<1 or input[3]>1000000000:return -1
        purchase_scaled=input[1];residual_scaled=input[2]
        var unit_sum:Float64=0.0
        for i in range(years):
            let units=input[4+i]
            if units< -1000000000 or units>1000000000:return -1
            unit_sum+=Float64(units)
        let unit_diff=unit_sum-Float64(input[3])
        if unit_diff<0.0:
            if -unit_diff>1.0e-6*Float64(input[3]):return -1
        elif unit_diff>1.0e-6*Float64(input[3]):return -1
    else:return -1
    if purchase_scaled<0 or purchase_scaled>1000000000000 or residual_scaled< -1000000000000 or residual_scaled>purchase_scaled:return -1
    let purchase=Float64(purchase_scaled)/1000000.0;let residual=Float64(residual_scaled)/1000000.0;let cost=purchase-residual
    var schedule=List[Float64](length=years,fill=0.0)
    if method==0:
        let annual=cost/Float64(years);var accumulated:Float64=0.0
        for period in range(years):
            if period==years-1:schedule[period]=cost-accumulated
            else:accumulated+=annual;schedule[period]=annual
    elif method==1:
        var book=purchase
        for period in range(years):
            if period==years-1:schedule[period]=book-residual
            else:
                var expense=book*rate
                if expense>book-residual:expense=book-residual
                schedule[period]=expense;book-=expense
    elif method==2:
        let per_unit=cost/Float64(input[3]);var accumulated:Float64=0.0
        for period in range(years):
            if period==years-1:schedule[period]=cost-accumulated
            else:
                let expense=Float64(input[4+period])*per_unit;accumulated+=expense;schedule[period]=expense
    elif method==3:
        let syd=Float64(years)*Float64(years+1)/2.0;var accumulated:Float64=0.0
        for period in range(1,years+1):
            if period==years:schedule[period-1]=cost-accumulated
            else:
                let expense=(Float64(years-period+1)/syd)*cost;accumulated+=expense;schedule[period-1]=expense
    else:
        let ddb_rate=2.0/Float64(years);var book=purchase;var accumulated:Float64=0.0
        for period in range(1,years+1):
            let remaining=Float64(years-period+1);var ddb=book*ddb_rate
            if ddb<0.0:ddb=0.0
            var straight=(book-residual)/remaining
            if straight<0.0:straight=0.0
            var expense=ddb if ddb>straight else straight
            if expense>book-residual:expense=book-residual
            if period==years:schedule[period-1]=cost-accumulated
            else:accumulated+=expense;schedule[period-1]=expense;book-=expense
    let bytes=years*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for i in range(years):depreciation_write(out,i*8,schedule[i])
    return Int64(bytes)
