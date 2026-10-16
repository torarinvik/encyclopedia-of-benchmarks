const MAX:usize=256;
export fn trifid_cipher(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<31)return -1;
    const mode=input[0];const pv=input[1];const nv=input[2];
    if((mode!=0 and mode!=1) or pv<1 or pv>256 or nv<0 or nv>256 or input[3]!=27 or length!=31+@as(usize,@intCast(nv)))return -1;
    var alpha:[27]u8=undefined;var text:[MAX]u8=undefined;var transformed:[MAX]u8=undefined;var al:usize=0;var tl:usize=0;
    for(0..27)|i|{const raw=input[4+@as(usize,@intCast(nv))+i];if(raw<0 or raw>127)return -1;var c:u8=@intCast(raw);if(c>=97 and c<=122)c-=32;if(c==32)continue;for(0..al)|j|{if(alpha[j]==c)return -1;}alpha[al]=c;al+=1;}
    if(al!=27)return -1;
    for(0..@as(usize,@intCast(nv)))|i|{const raw=input[4+i];if(raw<0 or raw>127)return -1;var c:u8=@intCast(raw);if(c>=97 and c<=122)c-=32;if(c==32)continue;var found=false;for(alpha)|a|{if(a==c)found=true;}if(!found)return -1;text[tl]=c;tl+=1;}
    const period:usize=@intCast(pv);var start:usize=0;
    while(start<tl){const k=@min(period,tl-start);var d:[768]u8=undefined;
        if(mode==0){var m:usize=0;for(0..3)|axis|{for(0..k)|i|{var idx:usize=0;while(alpha[idx]!=text[start+i])idx+=1;const div:usize=if(axis==0)9 else if(axis==1)3 else 1;d[m]=@intCast((idx/div)%3);m+=1;}}var i:usize=0;while(i<m):(i+=3){const idx=@as(usize,d[i])*9+@as(usize,d[i+1])*3+d[i+2];transformed[start+i/3]=alpha[idx];}}
        else{for(0..k)|i|{var idx:usize=0;while(alpha[idx]!=text[start+i])idx+=1;d[3*i]=@intCast((idx/9)%3);d[3*i+1]=@intCast((idx/3)%3);d[3*i+2]=@intCast(idx%3);}for(0..k)|i|{const idx=@as(usize,d[i])*9+@as(usize,d[k+i])*3+d[2*k+i];transformed[start+i]=alpha[idx];}}
        start+=k;
    }
    if(capacity<tl)return -2;if(tl>0 and output==null)return -1;for(0..tl)|i|output[i]=transformed[i];return @intCast(tl);
}
