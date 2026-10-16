const MW=64;const ML=16;
export fn uncommon_words(v:[*c]const i64,n:usize,out:[*c]u8,cap:usize)i64{
 if(v==null or n<1 or n>1089 or v[0]<0 or v[0]>MW)return -1;var words:[MW][ML]u8=@splat(@splat(0));var lens:[MW]usize=@splat(0);var counts:[MW]usize=@splat(0);var d:usize=0;var p:usize=1;
 for(0..@as(usize,@intCast(v[0]))) |_| {if(p>=n or v[p]<1 or v[p]>ML)return -1;const l:usize=@intCast(v[p]);p+=1;if(l>n-p)return -1;for(0..l)|j|if(v[p+j]<'a' or v[p+j]>'z')return -1;var id:usize=0;while(id<d):(id+=1){if(lens[id]==l){var j:usize=0;while(j<l and words[id][j]==v[p+j]):(j+=1){}if(j==l)break;}}if(id==d){lens[d]=l;for(0..l)|j|words[d][j]=@intCast(v[p+j]);d+=1;}counts[id]+=1;p+=l;}
 if(p!=n)return -1;var temp:[1089]u8=@splat(0);var at:usize=0;for(0..d)|id|{if(counts[id]==1){@memcpy(temp[at..][0..lens[id]],words[id][0..lens[id]]);at+=lens[id];temp[at]='\n';at+=1;}}if(at>0)at-=1;temp[at]=0;at+=1;if(out==null or cap<at)return -2;@memcpy(out[0..at],temp[0..at]);return @intCast(at);
}
