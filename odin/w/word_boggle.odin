package word_boggle
import "core:c"

Max_Nodes :: 481
Alphabet :: 52
char_index :: proc "contextless" (ch: i64) -> int { if ch <= 90 do return int(ch-65); return int(ch-97+26) }
valid_char :: proc "contextless" (ch: i64) -> bool { return (ch>=65 && ch<=90) || (ch>=97 && ch<=122) }
visit :: proc "contextless" (board: [^]i64, rows, cols, pos, node: int,
    children: [^]u16, terminal: [^]int, visited: [^]bool, found: [^]bool) {
    visited[pos] = true
    if terminal[node] >= 0 do found[terminal[node]] = true
    row := pos/cols; col := pos%cols
    for dr := -1; dr <= 1; dr += 1 {
        for dc := -1; dc <= 1; dc += 1 {
            if dr == 0 && dc == 0 do continue
            nr := row+dr; nc := col+dc
            if nr < 0 || nc < 0 || nr >= rows || nc >= cols do continue
            next := nr*cols+nc
            if visited[next] do continue
            child := int(children[node*Alphabet+char_index(board[next])])
            if child > 0 do visit(board,rows,cols,next,child-1,children,terminal,visited,found)
        }
    }
    visited[pos] = false
}
less :: proc "contextless" (words: [^]i64, lengths: [^]int, a,b: int) -> bool {
    n := lengths[a]; if lengths[b] < n do n = lengths[b]
    for i := 0; i < n; i += 1 { x:=words[a*15+i]; y:=words[b*15+i]; if x != y do return x<y }
    return lengths[a] < lengths[b]
}
@(export)
word_boggle :: proc "c" (input: [^]i64, length: uint, output: [^]u8, capacity: uint) -> i64 {
    if input == nil || length < 3 || length > 551 do return -1
    if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6 do return -1
    rows:=int(input[0]); cols:=int(input[1]); cells:=rows*cols; dict_at:=2+cells
    if length <= uint(dict_at) || input[dict_at] < 0 || input[dict_at] > 32 do return -1
    count:=int(input[dict_at])
    for i:=0;i<cells;i+=1 {if !valid_char(input[2+i]) do return -1}
    words:[480]i64; lengths:[32]int
    for i:=0;i<480;i+=1 {words[i]=0}; for i:=0;i<32;i+=1 {lengths[i]=0}
    unique:=0; at:=dict_at+1
    for k:=0;k<count;k+=1 {
        if at>=int(length)||input[at]<1||input[at]>15 do return -1
        n:=int(input[at]);at+=1;if int(length)-at<n do return -1
        for j:=0;j<n;j+=1 {if !valid_char(input[at+j]) do return -1}
        duplicate:=false
        for w:=0;w<unique;w+=1 {if lengths[w]==n {same:=true;for j:=0;j<n;j+=1 {if words[w*15+j]!=input[at+j] do same=false};if same do duplicate=true}}
        if !duplicate {lengths[unique]=n;for j:=0;j<n;j+=1 {words[unique*15+j]=input[at+j]};unique+=1}
        at+=n
    }
    if at!=int(length) do return -1
    children:[Max_Nodes*Alphabet]u16;terminal:[Max_Nodes]int
    for i:=0;i<Max_Nodes*Alphabet;i+=1 {children[i]=0};for i:=0;i<Max_Nodes;i+=1 {terminal[i]=-1}
    nodes:=1
    for w:=0;w<unique;w+=1 {node:=0;for j:=0;j<lengths[w];j+=1 {slot:=node*Alphabet+char_index(words[w*15+j]);if children[slot]==0 {children[slot]=u16(nodes+1);nodes+=1};node=int(children[slot])-1};terminal[node]=w}
    found:[32]bool;visited:[36]bool;for i:=0;i<32;i+=1 {found[i]=false};for i:=0;i<36;i+=1 {visited[i]=false}
    for p:=0;p<cells;p+=1 {child:=int(children[char_index(input[2+p])]);if child>0 do visit(&input[2],rows,cols,p,child-1,&children[0],&terminal[0],&visited[0],&found[0])}
    order:[32]int;found_count:=0;output_size:=0
    for w:=0;w<unique;w+=1 {if found[w] {order[found_count]=w;found_count+=1;output_size+=lengths[w]+1}}
    for i:=1;i<found_count;i+=1 {value:=order[i];j:=i;for j>0 && less(&words[0],&lengths[0],value,order[j-1]) {order[j]=order[j-1];j-=1};order[j]=value}
    if capacity<uint(output_size) || (output_size>0 && output==nil) do return -2
    pos:=0;for k:=0;k<found_count;k+=1 {w:=order[k];for j:=0;j<lengths[w];j+=1 {output[pos]=u8(words[w*15+j]);pos+=1};output[pos]=0;pos+=1}
    return i64(output_size)
}
