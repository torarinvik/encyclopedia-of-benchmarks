from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn maze_vertical(input: UnsafePointer[Int64, ImmutAnyOrigin], plane: Int, columns: Int, x: Int, a: Int, b: Int) -> Bool:
    var lo = a; var hi = b
    if lo > hi: lo = b; hi = a
    for y in range(lo,hi+1):
        if input[plane+y*columns+x-1] != 0: return False
    return True

fn maze_horizontal(input: UnsafePointer[Int64, ImmutAnyOrigin], plane: Int, columns: Int, a: Int, b: Int, y: Int) -> Bool:
    var lo = a; var hi = b
    if lo > hi: lo = b; hi = a
    for x in range(lo,hi+1):
        if input[plane+y*columns+x-1] != 0: return False
    return True

fn maze_candidate(input: UnsafePointer[Int64, ImmutAnyOrigin], columns: Int, tracks: Int,
                  column: Int, bottom: Int, top: Int, neighbor: Int, upper: Bool) -> Bool:
    let plane = 5+columns
    if upper:
        let jog = bottom-1
        return maze_vertical(input,plane,columns,column,tracks+1,bottom) and maze_vertical(input,plane,columns,column,0,jog) and maze_horizontal(input,plane,columns,column,neighbor,jog) and maze_vertical(input,plane,columns,neighbor,jog,top) and input[5+neighbor-1] == 0
    let jog = top+1
    return maze_vertical(input,plane,columns,column,0,top) and maze_vertical(input,plane,columns,column,tracks+1,jog) and maze_horizontal(input,plane,columns,column,neighbor,jog) and maze_vertical(input,plane,columns,neighbor,jog,bottom) and input[5+neighbor-1] == 0

@export("ptrdist_yacr2_maze1_dogleg")
fn ptrdist_yacr2_maze1_dogleg(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5: return -1
    let cv = input[0]; let tv = input[1]; let colv = input[2]; let bv = input[3]; let topv = input[4]
    if cv < 2 or cv > 16 or tv < 2 or tv > 16 or colv < 1 or colv > cv or bv < 1 or bv >= topv or topv > tv: return -1
    let columns = Int(cv); let tracks = Int(tv); let column = Int(colv); let bottom = Int(bv); let top = Int(topv)
    if length != c_size_t(5+columns+columns*(tracks+2)): return -1
    for i in range(5,Int(length)):
        if input[i] != 0 and input[i] != 1: return -1
    if bottom > 1 and column > 1 and maze_candidate(input,columns,tracks,column,bottom,top,column-1,True): return 1
    if bottom > 1 and column < columns and maze_candidate(input,columns,tracks,column,bottom,top,column+1,True): return 2
    if top < tracks and column > 1 and maze_candidate(input,columns,tracks,column,bottom,top,column-1,False): return 3
    if top < tracks and column < columns and maze_candidate(input,columns,tracks,column,bottom,top,column+1,False): return 4
    return 0
