module conway
const max_text_length = 128
fn decimal_digits(value_input int) int { mut value:=value_input;mut digits:=1;for value>=10{value/=10;digits++};return digits }

// Generate the next look-and-say string from bounded ASCII input.
@[export: 'conway']
pub fn conway(input &i64,length usize,output &u8,capacity usize) i64 {
 if length<2||length>max_text_length+1{return -1}
 unsafe {
  n:=input[0];if n<1||n>max_text_length||length!=usize(n+1){return -1}
  for i in 0..int(n){if input[i+1]<0||input[i+1]>127{return -1}}
  mut needed:=0;mut i:=0
  for i<int(n){mut j:=i+1;for j<int(n)&&(input[j]==input[j+1]||input[j]==10||input[j]==13){j++};needed+=decimal_digits(j-i)+1;i=j}
  if capacity<usize(needed){return -2}
  mut pos:=0;i=0
  for i<int(n){mut j:=i+1;for j<int(n)&&(input[j]==input[j+1]||input[j]==10||input[j]==13){j++};mut run:=j-i;start:=pos
   for {output[pos]=u8(48+run%10);pos++;run/=10;if run==0{break}}
   mut left:=start;mut right:=pos-1;for left<right{tmp:=output[left];output[left]=output[right];output[right]=tmp;left++;right--}
   output[pos]=u8(input[i+1]);pos++;i=j
  }
  return i64(pos)
 }
}
