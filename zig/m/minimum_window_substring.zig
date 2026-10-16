const max_text:usize=128;
export fn minimum_window_substring(v:[*c]const i64,n:usize,out:[*c]u8,cap:usize)i64{
 if(v==null or n<3 or n>258 or v[0]<0 or v[0]>max_text)return -1;const s:usize=@intCast(v[0]);if(n<s+2)return -1;const mm=v[s+1];if(mm<1 or mm>max_text)return -1;const m:usize=@intCast(mm);if(n!=s+m+2)return -1;
 var need=[_]i32{0}**128;for(0..s)|i|{if(v[i+1]<0 or v[i+1]>127)return -1;}for(0..m)|i|{const c=v[s+2+i];if(c<0 or c>127)return -1;need[@intCast(c)]+=1;}
 var left:usize=0;var best=s+1;var start:usize=0;var missing:i32=@intCast(m);
 for(0..s)|right|{const c:usize=@intCast(v[right+1]);if(need[c]>0)missing-=1;need[c]-=1;while(missing==0){const length=right-left+1;if(length<best){best=length;start=left;}const x:usize=@intCast(v[left+1]);need[x]+=1;left+=1;if(need[x]>0)missing+=1;}}
 if(best==s+1)return 0;if(best>cap or(out==null and best>0))return -2;for(0..best)|i|{out[i]=@intCast(v[start+1+i]);}return @intCast(best);
}
