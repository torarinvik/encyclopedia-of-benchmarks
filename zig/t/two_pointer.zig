export fn two_pointer(input:[*]const i64,length:usize)i64{
 if(length<2 or length>258)return -2;const n=input[0];const target=input[1];if(n<0 or n>256 or length!=@as(usize,@intCast(n))+2 or target<std.math.minInt(i32) or target>std.math.maxInt(i32))return -2;
 for(0..@as(usize,@intCast(n)))|i|{const x=input[i+2];if(x<std.math.minInt(i32) or x>std.math.maxInt(i32) or (i>0 and input[i+1]>x))return -2;}
 var left:usize=0;var right:usize=if(n>0) @as(usize,@intCast(n))-1 else 0;while(left<right){const sum=input[left+2]+input[right+2];if(sum==target)return @intCast(left*256+right);if(sum<target){left+=1;}else{right-=1;}}return -1;
}
const std=@import("std");
