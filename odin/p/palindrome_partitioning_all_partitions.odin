package palindrome_partitioning_all_partitions

import "core:c"

MAX_LENGTH :: 12
OUT_CAP :: 16000
Context :: struct { text: [^]i64, length: int, ends: [MAX_LENGTH]int, packed: [OUT_CAP]i64, used, partitions: int }

is_palindrome :: proc "contextless" (ctx: ^Context,start,finish:int)->bool {
	left:=start;right:=finish
	for left<right { if ctx.text[left+1]!=ctx.text[right] do return false;left+=1;right-=1 }
	return true
}
enumerate :: proc "contextless" (ctx:^Context,start,depth:int) {
	if start==ctx.length { ctx.partitions+=1;ctx.packed[ctx.used]=i64(depth);ctx.used+=1;for i:=0;i<depth;i+=1{ctx.packed[ctx.used]=i64(ctx.ends[i]);ctx.used+=1};return }
	for finish:=start+1;finish<=ctx.length;finish+=1 { if is_palindrome(ctx,start,finish){ctx.ends[depth]=finish;enumerate(ctx,finish,depth+1)} }
}
put_i64 :: proc "contextless" (out:[^]u8,offset:usize,value:i64){bits:=u64(value);for byte:=0;byte<8;byte+=1{out[offset+usize(byte)]=u8(bits>>(8*byte))}}

@(export)
palindrome_partitioning_all_partitions :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if input==nil||length<1||input[0]<0||input[0]>MAX_LENGTH||length!=c.size_t(input[0])+1 do return -1
	n:=int(input[0]);for i:=0;i<n;i+=1{if input[i+1]<0||input[i+1]>127 do return -1}
	var ctx:Context;ctx.text=input;ctx.length=n;ctx.used=1;ctx.partitions=0;enumerate(&ctx,0,0);ctx.packed[0]=i64(ctx.partitions)
	required:=ctx.used*8;if output==nil||capacity<c.size_t(required) do return -2
	for i:=0;i<ctx.used;i+=1{put_i64(output,usize(i*8),ctx.packed[i])};return i64(required)
}
