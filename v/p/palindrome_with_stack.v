@[export: 'palindrome_with_stack']
pub fn palindrome_with_stack(v &i64, n usize) i64 {
 unsafe {
  if v==nil||n<1||n>129||v[0]<0||v[0]>128||n!=usize(v[0]+1){return -1}
  length:=int(v[0]);mut stack:=[128]u8{}
  for i in 0..length { x:=v[i+1];if x<0||x>127{return -1};mut c:=u8(x);if c>=u8(65)&&c<=u8(90){c+=32};stack[i]=c }
  for i in 0..length { if stack[i]!=stack[length-1-i]{return 0} };return 1
 }
}

