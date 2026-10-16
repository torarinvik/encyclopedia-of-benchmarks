export fn word_patterns(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if(input==null or length<1)return -1; const values=input.?[0..length]; if(values[0]<0 or values[0]>256)return -1; const n:usize=@intCast(values[0]); if(length!=n+1)return -1; var first=[_]i32{-1}**128; var next:i32=0; var pos:usize=0;
    for(0..n)|i|{var ch=values[i+1];if(ch<0 or ch>127)return -1;if(ch>=97 and ch<=122)ch-=32;const c:usize=@intCast(ch);if(first[c]<0){first[c]=next;next+=1;}}if(output==null or capacity<4*n+1)return -2; const out=output.?[0..capacity];
    for(0..n)|i|{var ch=values[i+1];if(ch>=97 and ch<=122)ch-=32;const c:usize=@intCast(ch);if(i>0){out[pos]='.';pos+=1;}var value:usize=@intCast(first[c]);var digits:[3]u8=undefined;var count:usize=0;while(true){digits[count]=@intCast(48+value%10);count+=1;value/=10;if(value==0)break;}while(count>0){count-=1;out[pos]=digits[count];pos+=1;}}out[pos]=0;return @intCast(pos);
}
