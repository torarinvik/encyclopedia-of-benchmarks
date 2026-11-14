# Bounded callback-dispatch draft; provenance is in the package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn methcall_flip(mut state: Bool, mut counter: Int):
    state = not state

fn methcall_flip_third(mut state: Bool, mut counter: Int):
    counter += 1
    if counter == 3:
        state = not state
        counter = 0

fn methcall_value(state: Bool) -> Bool:
    return state

struct MethcallToggle:
    var state: Bool
    var counter: Int
    var activate: def(mut Bool, mut Int) -> None
    var value: def(Bool) -> Bool

    fn __init__(out self, every_third: Bool):
        self.state = True
        self.counter = 0
        if every_third: self.activate = methcall_flip_third
        else: self.activate = methcall_flip
        self.value = methcall_value

fn methcall_append(mut staged: InlineArray[UInt8, 14], mut used: Int, state: Bool):
    if state:
        staged[used] = 116; staged[used+1] = 114
        staged[used+2] = 117; staged[used+3] = 101
        used += 4
    else:
        staged[used] = 102; staged[used+1] = 97; staged[used+2] = 108
        staged[used+3] = 115; staged[used+4] = 101
        used += 5
    staged[used] = 10; staged[used+1] = 10
    used += 2

@export("shootout_methcall")
fn shootout_methcall(calls: Int64, output: UnsafePointer[UInt8, MutAnyOrigin],
                     capacity: c_size_t) abi("C") -> Int64:
    if calls < -100_000 or calls > 100_000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var plain = MethcallToggle(False)
    var third = MethcallToggle(True)
    var plain_result = True
    var third_result = True
    for _ in range(max(0, Int(calls))):
        let activate = plain.activate
        let value = plain.value
        activate(plain.state, plain.counter)
        plain_result = value(plain.state)
    for _ in range(max(0, Int(calls))):
        let activate = third.activate
        let value = third.value
        activate(third.state, third.counter)
        third_result = value(third.state)
    var staged = InlineArray[UInt8, 14](fill=0)
    var used = 0
    methcall_append(staged, used, plain_result)
    methcall_append(staged, used, third_result)
    if capacity < c_size_t(used): return -2
    for i in range(used): output[i] = staged[i]
    return Int64(used)
