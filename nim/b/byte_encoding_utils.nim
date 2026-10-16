## Reverse the eight bytes in a 64-bit bit pattern.
proc byte_encoding_utils*(value: int64): int64 {.cdecl, exportc: "byte_encoding_utils".} =
  var bits = cast[uint64](value)
  bits = ((bits and 0x00000000000000FF'u64) shl 56) or
         ((bits and 0x000000000000FF00'u64) shl 40) or
         ((bits and 0x0000000000FF0000'u64) shl 24) or
         ((bits and 0x00000000FF000000'u64) shl 8) or
         ((bits and 0x000000FF00000000'u64) shr 8) or
         ((bits and 0x0000FF0000000000'u64) shr 24) or
         ((bits and 0x00FF000000000000'u64) shr 40) or
         ((bits and 0xFF00000000000000'u64) shr 56)
  cast[int64](bits)
