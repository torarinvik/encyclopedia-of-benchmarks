const MAX_TEXT:usize=256;const MAX_INPUT:usize=MAX_TEXT+2;
export fn split(input:?[*]const i64,length:usize,output:?[*]u8,capacity:usize)i64{
 if(input==null or length<2 or length>MAX_INPUT+1)return -1;const v=input.?[0..length];if(v[0]<0 or v[0]>MAX_TEXT or v[1]<0 or v[1]>127)return -1;const n:usize=@intCast(v[0]);if(length!=n+2)return -1;
 for(v[2..])|b|{if(b<0 or b>127)return -1;}if(n>0 and v[n+1]==v[1])return -1;var separators:usize=0;for(v[2..])|b|{if(b==v[1])separators+=1;}if(n>0 and separators==0)return -1;const count=separators+1;const required=2+2*count+n-separators;if(output==null or capacity<required)return -2;
 const o=output.?[0..capacity];o[0]=@intCast(count);o[1]=@intCast(count>>8);var pos:usize=2;var start:usize=0;for(0..n+1)|i|{if(i==n or v[i+2]==v[1]){const field=i-start;o[pos]=@intCast(field);o[pos+1]=@intCast(field>>8);pos+=2;for(start..i)|j|{o[pos]=@intCast(v[j+2]);pos+=1;}start=i+1;}}return @intCast(required);
}
