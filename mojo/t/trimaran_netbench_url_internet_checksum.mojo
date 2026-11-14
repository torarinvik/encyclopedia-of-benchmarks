# Modified source-related port; see the package's LICENSE_NOTICE.txt.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("trimaran_netbench_url_internet_checksum")
fn trimaran_netbench_url_internet_checksum(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    let mode = input[0]; let count0 = input[1]
    if (mode != 0 and mode != 1) or count0 < 0 or count0 > 64 or length != c_size_t(count0 + 2): return -1
    let count = Int(count0)
    for i in range(count):
        if input[i + 2] < 0 or input[i + 2] > 255: return -1
    let maximum = UInt64(0xffffffffffffffff)
    var sum = UInt64(0)
    var i = 0
    while i + 1 < count:
        let word = UInt64(input[i + 2]) | (UInt64(input[i + 3]) << 8)
        let amount = word + 1
        if sum < amount: sum = maximum - (amount - sum) + 1
        else: sum -= amount
        i += 2
    if i < count:
        let amount = UInt64(input[i + 2])
        if sum > maximum - amount: sum = amount - (maximum - sum) - 1
        else: sum += amount
    while sum >> 16 != 0: sum = (sum & 0xffff) + (sum >> 16)
    if mode == 1: sum = ((sum >> 8) | ((sum << 8) & 0xff00)) & 0xffff
    return Int64(sum)
