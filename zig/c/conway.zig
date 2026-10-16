const MAX_TEXT_LENGTH: usize=128;
fn decimalDigits(input_value:usize) usize {var value=input_value;var digits:usize=1;while(value>=10):(value/=10){digits+=1;}return digits;}
/// Generate the next look-and-say string from bounded ASCII input.
export fn conway(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<2 or length>MAX_TEXT_LENGTH+1)return -1;const values=input[0..length];const n=values[0];if(n<1 or n>MAX_TEXT_LENGTH or length!=@as(usize,@intCast(n))+1)return -1;
 for(values[1..])|ch|{if(ch<0 or ch>127)return -1;}
 var needed:usize=0;var i:usize=0;while(i<@as(usize,@intCast(n))){var j=i+1;while(j<@as(usize,@intCast(n)) and (values[j]==values[j+1] or values[j]==10 or values[j]==13)){j+=1;}needed+=decimalDigits(j-i)+1;i=j;}
 if(output==null or capacity<needed)return -2;const out=output[0..capacity];var pos:usize=0;i=0;
 while(i<@as(usize,@intCast(n))){var j=i+1;while(j<@as(usize,@intCast(n)) and (values[j]==values[j+1] or values[j]==10 or values[j]==13)){j+=1;}var run=j-i;const start=pos;while(true){out[pos]=@intCast(48+run%10);pos+=1;run/=10;if(run==0)break;}var left=start;var right=pos-1;while(left<right){const tmp=out[left];out[left]=out[right];out[right]=tmp;left+=1;right-=1;}out[pos]=@intCast(values[i+1]);pos+=1;i=j;}
 return @intCast(pos);
}
