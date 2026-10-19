// Bounded port of the Benchmark Game fannkuch counter traversal.
package fannkuch
import "core:c"

@(export)
fannkuch::proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 1 do return -1
    n64 := values[0]
    if n64 < 1 || n64 > 8 do return -1
    n := int(n64)
    perm: [8]int
    perm1: [8]int
    count: [8]int
    for i in 0..<n { perm1[i] = i }
    r := n
    flips_max := 0
    for {
        for r != 1 { count[r-1] = r; r -= 1 }
        if perm1[0] != 0 && perm1[n-1] != n-1 {
            for i in 1..<n { perm[i] = perm1[i] }
            k := perm1[0]
            flips := 0
            for {
                i, j := 1, k-1
                for i < j { perm[i], perm[j] = perm[j], perm[i]; i += 1; j -= 1 }
                flips += 1
                j = perm[k]
                perm[k] = k
                k = j
                if k == 0 do break
            }
            if flips_max < flips do flips_max = flips
        }
        for {
            if r == n do return i64(flips_max)
            first := perm1[0]
            for i in 0..<r { perm1[i] = perm1[i+1] }
            perm1[r] = first
            count[r] -= 1
            if count[r] > 0 do break
            r += 1
        }
    }
}
