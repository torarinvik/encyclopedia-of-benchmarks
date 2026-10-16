const ROTORS = [_][]const u8{"EGZWVONAHDCLFQMSIPJBYUKXTR","FOBHMDKEXQNRAULPGSJVTYICZW","ZJXESIUQLHAVRMDOYGTNFWPBKC"};
pub export fn enigma_machine2(a: [*c]const i64, length: usize) i64 {
 if(a==null or length<4 or length>16)return -1;
 const n64=a[0];if(n64<0 or n64>12 or length!=4+@as(usize,@intCast(n64)))return -1;
 var p:[3]i32=@splat(0);
 for(0..3)|j|{const v=a[j+1];if(v<1 or v>26)return -1;p[j]=@intCast(v-1);}
 const n:usize=@intCast(n64);for(0..n)|i|{if(a[4+i]<0 or a[4+i]>25)return -1;}
 var out:i64=0;
 for(0..n)|i|{var x:i32=@intCast(a[4+i]);for(0..3)|r|{const index:usize=@intCast(@mod(x+p[r],26));x=@as(i32,ROTORS[r][index])-@as(i32,'A');}x=@mod(x+13,26);var rr:usize=3;while(rr>0){rr-=1;var z:i32=0;while(z<26 and @as(i32,ROTORS[rr][@intCast(z)])-@as(i32,'A')!=x):(z+=1){}x=@mod(z-p[rr],26);}out=out*26+x;p[0]+=1;if(p[0]==26){p[0]=0;p[1]+=1;if(p[1]==26){p[1]=0;p[2]=@mod(p[2]+1,26);}}}
 return out;
}
