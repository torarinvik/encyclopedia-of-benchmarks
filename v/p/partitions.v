const max_n = 100
const stride = 101
fn count_parts(n int, k int, mut memo []i64) i64 {
 if (n == 0 && k == 0) || (n > 0 && k == 1) || n == k { return 1 }
 if k == 0 || k > n { return 0 }
 idx := n * stride + k
 if memo[idx] >= 0 { return memo[idx] }
 memo[idx] = count_parts(n - 1, k - 1, mut memo) + count_parts(n - k, k, mut memo)
 return memo[idx]
}
@[export: 'partitions']
pub fn partitions(n i64) i64 {
 if n < 0 || n > max_n { return i64(-9223372036854775807 - 1) }
 mut memo := []i64{len: stride * stride, init: -1}
 mut total := i64(0)
 for k in 1..int(n) + 1 { total += count_parts(int(n), k, mut memo) }
 if n == 0 { return 1 }
 return total
}
