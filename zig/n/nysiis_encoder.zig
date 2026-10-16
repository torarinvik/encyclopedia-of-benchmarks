const std = @import("std");
fn vowel(c: u8) bool { return c == 'A' or c == 'E' or c == 'I' or c == 'O' or c == 'U'; }
fn matches(s: []const u8, at: usize, p: []const u8) bool { return at + p.len <= s.len and std.mem.eql(u8, s[at .. at+p.len], p); }
fn replace(s: *[256]u8, n: *usize, at: usize, old: usize, to: []const u8) void {
    if (to.len > old) { var i = n.*; while (i > at + old) { i -= 1; s[i - old + to.len] = s[i]; } }
    else { var i = at + old; while (i < n.*) : (i += 1) s[i-old+to.len] = s[i]; }
    @memcpy(s[at..][0..to.len], to); n.* = n.* - old + to.len;
}
export fn nysiis_encoder(values: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (length < 2 or length > 65 or values[0] < 1 or values[0] > 64 or length != @as(usize,@intCast(values[0]+1))) return -1;
    var s: [256]u8 = undefined; var n: usize = 0;
    for (0..@intCast(values[0])) |i| { var c=values[i+1]; if (c>=97 and c<=122) c-=32; if (c<65 or c>90) return -1; s[n]=@intCast(c); n+=1; }
    const starts=[_] [2][]const u8{.{"MAC","MCC"},.{"KN","NN"},.{"K","C"},.{"PH","FF"},.{"PF","FF"},.{"SCH","SSS"}};
    for(starts)|p|{if(matches(s[0..n],0,p[0])){replace(&s,&n,0,p[0].len,p[1]);break;}}
    const ends=[_] [2][]const u8{.{"EE","Y"},.{"IE","Y"},.{"DT","D"},.{"RT","D"},.{"NT","D"},.{"ND","D"}};
    for(ends)|p|{if(n>=p[0].len and matches(s[0..n],n-p[0].len,p[0])){replace(&s,&n,n-p[0].len,p[0].len,p[1]);break;}}
    const rules=[_] [2][]const u8{.{"EV","AF"},.{"E","A"},.{"I","A"},.{"O","A"},.{"U","A"},.{"Q","G"},.{"Z","S"},.{"M","N"},.{"KN","NN"},.{"K","C"},.{"SCH","SSS"},.{"PH","FF"}};
    var i:usize=1;while(i<n):(i+=1){var changed=false;for(rules)|p|{if(matches(s[0..n],i,p[0])){replace(&s,&n,i,p[0].len,p[1]);changed=true;break;}}if(!changed){if(s[i]=='H' and (!vowel(s[i-1]) or (i+1<n and !vowel(s[i+1]))))s[i]=s[i-1] else if(s[i]=='W' and vowel(s[i-1]))s[i]=s[i-1];}}
    var w:usize=0;for(0..n)|j|{if(j==0 or s[j]!=s[j-1]){s[w]=s[j];w+=1;}}n=w;
    if(n>0 and s[n-1]=='S')n-=1 else if(n>=2 and s[n-2]=='A' and s[n-1]=='Y'){s[n-2]='Y';n-=1;}else if(n>0 and s[n-1]=='A')n-=1;
    if(n>capacity)return -2;@memcpy(output[0..n],s[0..n]);return @intCast(n);
}
