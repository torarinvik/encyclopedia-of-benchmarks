# Bounded Shootout object-instantiation draft; see package README for provenance.
from std.collections import InlineArray
from std.ffi import c_size_t, external_call
from std.memory import MutAnyOrigin, MutUntrackedOrigin, Pointer, UnsafePointer

fn objinst_flip(mut state: Bool):
    state = not state

fn objinst_flip_third(mut state: Bool, mut count: Int, count_max: Int):
    count += 1
    if count >= count_max:
        count = 0
        state = not state

fn objinst_value(state: Bool) -> Bool:
    return state

struct ObjinstToggle:
    var state: Bool
    var activate: def(mut Bool) -> None
    var value: def(Bool) -> Bool

    fn __init__(out self):
        self.state = True
        self.activate = objinst_flip
        self.value = objinst_value

struct ObjinstNthToggle:
    var state: Bool
    var count_max: Int
    var count: Int
    var activate: def(mut Bool, mut Int, Int) -> None
    var value: def(Bool) -> Bool

    fn __init__(out self):
        self.state = True
        self.count_max = 3
        self.count = 0
        self.activate = objinst_flip_third
        self.value = objinst_value

fn objinst_append(mut output: InlineArray[UInt8, 72], mut used: Int, state: Bool):
    if state:
        output[used] = 116; output[used+1] = 114
        output[used+2] = 117; output[used+3] = 101
        used += 4
    else:
        output[used] = 102; output[used+1] = 97; output[used+2] = 108
        output[used+3] = 115; output[used+4] = 101
        used += 5
    output[used] = 10
    used += 1

@export("shootout_objinst")
fn shootout_objinst(n: Int64, output: UnsafePointer[UInt8, MutAnyOrigin],
                    capacity: c_size_t) abi("C") -> Int64:
    if n < -100_000 or n > 100_000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 72: return -2
    var staged = InlineArray[UInt8, 72](fill=0)
    var used = 0
    # Use the separately linked malloc/free helpers to preserve allocation
    # failure handling and keep observed objects alive until after observation.
    let allocation = external_call["benchmark_allocate_toggle",
        Optional[Pointer[ObjinstToggle, MutUntrackedOrigin]]](c_size_t(size_of[ObjinstToggle]()))
    if not allocation: return -1
    let ptr = allocation.value()
    ptr.unsafe_write(ObjinstToggle())
    for _ in range(5):
        let activate = ptr[].activate
        let value = ptr[].value
        activate(ptr[].state)
        objinst_append(staged, used, value(ptr[].state))
    ptr.unsafe_deinit_pointee()
    external_call["benchmark_release_toggle", NoneType](ptr.unsafe_bitcast[NoneType]())
    for _ in range(max(0, Int(n))):
        let allocated = external_call["benchmark_allocate_toggle",
            Optional[Pointer[ObjinstToggle, MutUntrackedOrigin]]](c_size_t(size_of[ObjinstToggle]()))
        if not allocated: return -1
        let extra = allocated.value()
        extra.unsafe_write(ObjinstToggle())
        external_call["benchmark_observe_toggle", NoneType](extra.unsafe_bitcast[NoneType]())
        extra.unsafe_deinit_pointee()
        external_call["benchmark_release_toggle", NoneType](extra.unsafe_bitcast[NoneType]())

    staged[used] = 10
    used += 1
    let nth_allocation = external_call["benchmark_allocate_nth_toggle",
        Optional[Pointer[ObjinstNthToggle, MutUntrackedOrigin]]](c_size_t(size_of[ObjinstNthToggle]()))
    if not nth_allocation: return -1
    let nth = nth_allocation.value()
    nth.unsafe_write(ObjinstNthToggle())
    for _ in range(8):
        let activate = nth[].activate
        let value = nth[].value
        let maximum = nth[].count_max
        activate(nth[].state, nth[].count, maximum)
        objinst_append(staged, used, value(nth[].state))
    nth.unsafe_deinit_pointee()
    external_call["benchmark_release_nth_toggle", NoneType](nth.unsafe_bitcast[NoneType]())
    for _ in range(max(0, Int(n))):
        let allocated = external_call["benchmark_allocate_nth_toggle",
            Optional[Pointer[ObjinstNthToggle, MutUntrackedOrigin]]](c_size_t(size_of[ObjinstNthToggle]()))
        if not allocated: return -1
        let extra = allocated.value()
        extra.unsafe_write(ObjinstNthToggle())
        external_call["benchmark_observe_nth_toggle", NoneType](extra.unsafe_bitcast[NoneType]())
        extra.unsafe_deinit_pointee()
        external_call["benchmark_release_nth_toggle", NoneType](extra.unsafe_bitcast[NoneType]())
    if used != 72: return -1
    for i in range(used): output[i] = staged[i]
    return Int64(used)
