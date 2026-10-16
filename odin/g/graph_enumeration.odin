package graph_enumeration
import "core:c"

mix_hash :: proc "contextless" (hash: ^u64, value: i64) {
	z := u64(value)
	h := hash^
	for b := 0; b < 8; b += 1 { h = (h ~ (z&255)) * u64(1099511628211); z>>=8 }
	hash^ = h
}

@(export)
graph_enumeration :: proc "contextless" (a: [^]i64, length: int) -> i64 {
    if a == nil || length < 1 do return -1
    n0 := a[0]; if n0 < 0 || n0 > 16 || length < 1+int(n0) do return -1
    n := int(n0); labels: [16]i64; sorted: [16]i64; adjacency: [16][32]i64; degree: [16]int
    for i := 0; i < n; i += 1 { labels[i]=a[1+i]; if labels[i] < -1000000 || labels[i] > 1000000 do return -1; for j := 0; j < i; j += 1 { if labels[i]==labels[j] do return -1 }; sorted[i]=labels[i] }
    for i := 0; i < n; i += 1 { for j := i+1; j < n; j += 1 { if sorted[j]<sorted[i] { t:=sorted[i]; sorted[i]=sorted[j]; sorted[j]=t } } }
    off := 1+n
    for i := 0; i < n; i += 1 { if off>=length do return -1; d:=a[off]; off+=1; if d<0 || d>32 || off+int(d)>length do return -1; degree[i]=int(d); for j:=0;j<int(d);j+=1 { x:=a[off];off+=1; found:=false;for k:=0;k<n;k+=1{if labels[k]==x do found=true};if !found do return -1;adjacency[i][j]=x } }
    if off!=length do return -1
    h: u64=14695981039346656037
    mix_hash(&h,i64(n+1));mix_hash(&h,0)
    for s:=0;s<n;s+=1 { i:=0;for labels[i]!=sorted[s]{i+=1};mix_hash(&h,i64(degree[i]));for j:=0;j<degree[i];j+=1{k:=0;for sorted[k]!=adjacency[i][j]{k+=1};mix_hash(&h,i64(k+1))} }
    return i64(h)
}
