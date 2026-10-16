const max_count = 6
fn mix(h u32,b u8)u32{return u32((u64(h^u32(b))*u64(16777619))&u64(0xffffffff))}
fn next_perm(mut a [max_count]i32,n int)bool{mut i:=n-1;for i>0&&a[i-1]>=a[i]{i--};if i==0{return false};mut j:=n-1;for a[j]<=a[i-1]{j--};a[i-1],a[j]=a[j],a[i-1];mut l:=i;mut r:=n-1;for l<r{a[l],a[r]=a[r],a[l];l++;r--};return true}
@[export:'permutations']
pub fn permutations(v &i64,n usize)i64{unsafe{if v==nil||n<2||n>7||v[0]<1||v[0]>max_count||n!=usize(v[0]+1){return -1};count:=int(v[0]);mut a:=[max_count]i32{};for i in 0..count{x:=v[i+1];if x < -2147483648||x>2147483647{return -1};a[i]=i32(x);if i>0&&a[i-1]>=a[i]{return -1}};mut h:=u32(2166136261);for{for i in 0..count{u:=u32(a[i]);for b in 0..4{h=mix(h,u8(u>>(8*b)))}};h=mix(h,255);if !next_perm(mut a,count){break}};return i64(h)}}
