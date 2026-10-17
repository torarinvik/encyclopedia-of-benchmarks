module char_array_left_rotation
const max_len=256
fn reverse_bytes(mut a [256]u8,from int,to int){mut left:=from;mut right:=to;for left<right{t:=a[left];a[left]=a[right];a[right]=t;left++;right--}}
@[export:'char_array_left_rotation']
pub fn char_array_left_rotation(input &i64,length usize,mut output &u8,capacity usize)i64{if unsafe{input==nil}||length<2||length>259{return -1};unsafe{if input[0]<0||input[0]>256{return -1};n:=int(input[0]);if input[1]<0||input[1]>i64(n)||length!=usize(n+2){return -1};for i in 0..n{if input[i+2]<0||input[i+2]>127{return -1}};if unsafe{output==nil}||capacity<usize(n){return -2};mut a:=[256]u8{};for i in 0..n{a[i]=u8(input[i+2])};k:=int(input[1]);if k>0{reverse_bytes(mut a,0,k-1)};if k<n{reverse_bytes(mut a,k,n-1)};if n>0{reverse_bytes(mut a,0,n-1)};for i in 0..n{output[i]=a[i]};return i64(n)}}
