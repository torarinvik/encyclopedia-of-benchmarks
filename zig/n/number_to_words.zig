const SMALL=[_] []const u8 {"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten","Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen"};
const TENS=[_] []const u8 {"","","Twenty","Thirty","Forty","Fifty","Sixty","Seventy","Eighty","Ninety"};
const SCALE=[_] []const u8 {"","Thousand","Million","Billion","Trillion"};
fn add(buf:*[256]u8,n:*usize,w:[]const u8) void {if(n.*>0){buf[n.*]=' ';n.*+=1;}@memcpy(buf[n.*..][0..w.len],w);n.*+=w.len;}
fn chunk(buf:*[256]u8,n:*usize,x0:u32) void {var x=x0;if(x>=100){add(buf,n,SMALL[x/100]);add(buf,n,"Hundred");x%=100;}if(x>=20){add(buf,n,TENS[x/10]);x%=10;}if(x>0 and x<20)add(buf,n,SMALL[x]);}
export fn number_to_words(v:[*]const i64,n:usize,out:[*]u8,cap:usize)i64{
 if(n<3 or n>9 or v[0] < -1 or v[0]>1 or v[1]<0 or v[1]>999999999999999 or v[2]<0 or v[2]>6 or n!=@as(usize,@intCast(v[2]+3)))return -1;
 var nonzero=v[1]!=0;for(3..n)|i|{if(v[i]<0 or v[i]>9)return -1;if(v[i]!=0)nonzero=true;}if((nonzero and v[0]==0)or(!nonzero and v[0]!=0))return -1;
 var b:[256]u8=undefined;var used:usize=0;if(v[0]<0)add(&b,&used,"Negative");var whole:u64=@intCast(v[1]);var groups=[_]u32{0,0,0,0,0};for(0..5)|i|{groups[i]=@intCast(whole%1000);whole/=1000;}var any=false;var i:usize=5;while(i>0){i-=1;if(groups[i]!=0){chunk(&b,&used,groups[i]);if(i>0)add(&b,&used,SCALE[i]);any=true;}}if(!any)add(&b,&used,"Zero");var fnz=false;for(3..n)|j|{if(v[j]!=0){fnz=true;}}if(fnz){add(&b,&used,"Point");for(3..n)|j|{add(&b,&used,SMALL[@intCast(v[j])]);}}if(used>cap)return -2;@memcpy(out[0..used],b[0..used]);return @intCast(used);
}
