const std = @import("std");
const Lines = [8][3]usize{
    .{0,1,2}, .{3,4,5}, .{6,7,8}, .{0,3,6},
    .{1,4,7}, .{2,5,8}, .{0,4,8}, .{2,4,6},
};

fn won(board: *const [9]i64, player: i64) bool {
    for (Lines) |line| {
        if (board[line[0]] == player and board[line[1]] == player and board[line[2]] == player) return true;
    }
    return false;
}

fn search(board: *[9]i64, side: i64) i32 {
    if (won(board, 1) or won(board, 2)) return -1;
    var available = false;
    for (board.*) |cell| if (cell == 0) { available = true; };
    if (!available) return -1;
    const other = 3 - side;
    var best_rank: i32 = -1;
    var best_score: i32 = 0;
    var best_mask: i32 = 0;
    for (0..9) |index| {
        if (board[index] != 0) continue;
        board[index] = side;
        const score: i32 = if (won(board, 1)) 1 else if (won(board, 2)) 2 else blk: {
            const child = search(board, other);
            break :blk if (child < 0) 0 else @divTrunc(child, 512);
        };
        board[index] = 0;
        const rank: i32 = if (score == side) 2 else if (score == 0) 1 else 0;
        if (rank > best_rank) {
            best_rank = rank; best_score = score; best_mask = @as(i32, 1) << @intCast(index);
        } else if (rank == best_rank) best_mask |= @as(i32, 1) << @intCast(index);
    }
    return best_score * 512 + best_mask;
}

pub export fn depth_first_search_tic_tac_toe(values: [*]const i64, length: usize) i64 {
    if (length != 10 or (values[0] != 1 and values[0] != 2)) return -1;
    var board: [9]i64 = undefined;
    for (0..9) |index| {
        if (values[index + 1] < 0 or values[index + 1] > 2) return -1;
        board[index] = values[index + 1];
    }
    const result = search(&board, values[0]);
    return if (result < 0) 0 else 1 + result;
}
