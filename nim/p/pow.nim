proc pow_algorithm*(v: ptr UncheckedArray[int64], n: csize_t): float64 {.cdecl, exportc: "pow_algorithm".} =
 if v.isNil or n != 2 or v[0] < -1000 or v[0] > 1000 or v[1] < -8 or v[1] > 12: return -1.0e300
 var result=1.0
 for i in 1..v[1]: result *= float64(v[0])
 result
