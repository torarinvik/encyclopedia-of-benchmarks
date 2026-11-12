"""Bounded, single-process HPCC RandomAccess table update kernel."""

from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_TABLE_SIZE = 256
alias DIGEST_MASK = UInt64(0x7fff_ffff_ffff_ffff)


@export("hpcc_random_access")
fn hpcc_random_access(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != c_size_t(1):
        return -1
    let size_value = input[0]
    if size_value < 2 or size_value > MAX_TABLE_SIZE:
        return -1
    if (size_value & (size_value - 1)) != 0:
        return -1

    let size = Int(size_value)
    var table = InlineArray[UInt64, MAX_TABLE_SIZE](fill=0)
    for index in range(size):
        table[index] = UInt64(index)

    var ran = UInt64(1)
    for _ in range(4 * size):
        let feedback = UInt64(7) if (ran >> 63) != 0 else UInt64(0)
        # Masking the outgoing bit makes this the same low-64-bit shift while
        # keeping the intermediate representable.
        ran = ((ran & DIGEST_MASK) << 1) ^ feedback
        let table_index = Int(ran & UInt64(size - 1))
        table[table_index] = table[table_index] ^ ran

    # UInt64 multiply/add use modulo-2^64 unsigned arithmetic in Mojo.
    var digest = UInt64(0)
    for index in range(size):
        digest = digest + UInt64(index + 1) * table[index]
    return Int64(digest & DIGEST_MASK)
