from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAXP = 16
comptime MASK48 = (1 << 48) - 1
comptime MULT = 0x5DEECE66D

fn lottery_next(state: UInt64) -> UInt64:
    return (state * UInt64(MULT) + UInt64(11)) & UInt64(MASK48)

fn lottery_int(mut state: UInt64, bound: UInt64) -> UInt64:
    if (bound & (bound - 1)) == 0:
        state = lottery_next(state)
        return (bound * (state >> 17)) >> 31
    while True:
        state = lottery_next(state)
        let bits = state >> 17
        let value = bits % bound
        if bits - value + (bound - 1) <= UInt64(0x7fffffff):
            return value

fn lottery_store(out: UnsafePointer[UInt8, MutAnyOrigin], at: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8):
        out[at + b] = UInt8((bits >> (b * 8)) & 255)

@export("lottery_scheduling")
fn lottery_scheduling(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 51: return -1
    let count = v[1]
    if count < 0 or count > MAXP or n != c_size_t(2 + 3 * count): return -1
    var ids = InlineArray[Int64, MAXP](fill=0)
    var bursts = InlineArray[Int64, MAXP](fill=0)
    var tickets = InlineArray[Int64, MAXP](fill=0)
    var total_tickets:Int64 = 0
    var total_burst:Int64 = 0
    for i in range(Int(count)):
        let pid=v[2+3*i];let burst=v[3+3*i];let t=v[4+3*i]
        if pid<0 or pid>32767 or burst<1 or burst>1000 or t<1 or t>1000:return -1
        for j in range(i):
            if ids[j]==pid:return -1
        ids[i]=pid;bursts[i]=burst;tickets[i]=t;total_tickets+=t;total_burst+=burst
    if total_tickets>16000 or total_burst>16000:return -1
    var state=(bitcast[UInt64](v[0]) ^ UInt64(MULT)) & UInt64(MASK48)
    var words=InlineArray[Int64,48](fill=0);var wc=0;var now:Int64=0;var remain=Int(count)
    while remain>0:
        var total:Int64=0
        for i in range(remain):total+=tickets[i]
        let win=lottery_int(state,UInt64(total))+1
        var cumulative:UInt64=0;var chosen=remain
        for i in range(remain):
            cumulative+=UInt64(tickets[i])
            if cumulative>=win:chosen=i;break
        if chosen==remain:return -1
        words[wc]=ids[chosen];words[wc+1]=now;words[wc+2]=now+bursts[chosen];wc+=3
        now+=bursts[chosen]
        for i in range(chosen,remain-1):ids[i]=ids[i+1];bursts[i]=bursts[i+1];tickets[i]=tickets[i+1]
        remain-=1
    let bytes=wc*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(wc):lottery_store(out,i*8,words[i])
    return Int64(bytes)
