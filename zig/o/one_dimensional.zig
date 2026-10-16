export fn one_dimensional(v:[*]const i64,n:usize,out:[*]u8,cap:usize)i64{
 if(n!=1 or v[0]<0 or v[0]>11111111)return -1;
 var digits=[_]u8{0}**8;var rules=[_]u8{0}**8;var x:u64=@intCast(v[0]);var count:usize=0;
 while(true){const d=x%10;if(d>1)return -1;digits[count]=@intCast(d);count+=1;x/=10;if(x==0)break;if(count==8)return -1;}
 for(0..count)|i|{rules[8-count+i]=digits[count-1-i];}
 var cells=[_] [31]u8{[_]u8{0}**31}**17;cells[0][15]=1;
 for(0..16)|r|{for(0..31)|c|{const l:usize=if(c>0)cells[r][c-1] else 0;const m:usize=cells[r][c];const rr:usize=if(c<30)cells[r][c+1] else 0;const p=(l<<2)|(m<<1)|rr;cells[r+1][c]=rules[7-p];}}
 if(cap<1581)return -2;var pos:usize=0;for(cells)|row|{for(row)|cell|{const color:u8=if(cell==1)0 else 255;out[pos]=color;out[pos+1]=color;out[pos+2]=color;pos+=3;}}return @intCast(pos);
}
