// Validate an even-length decimal digit array using the Luhn checksum.
@[export: 'luhn_validate']
pub fn luhn_validate(input &i64, length usize) i64 {
 if length<1{return -1}
 unsafe {
  n:=input[0]
  if n<2||n>64||n%2!=0||length!=usize(n+1){return -1}
  mut sum:=i64(0)
  for i:=i64(0);i<n;i++ {mut digit:=input[i+1];if digit<0||digit>9{return -1};if i%2==0{digit*=2;if digit>9{digit-=9}};sum+=digit}
  if sum%10==0{return 1};return 0
 }
}
