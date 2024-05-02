// The code in the file determines whether or not a given 4x4 Sudoku grid
// has been solved.
// This file contains some tests at the end, these can be run with the command
//
//     zig test grid-logic.zig
//
// The 'test' really contains 5 tests, although the Zig compiler should just output
//
//     "All 1 tests passed."

const std = @import("std");

// Recall that for positive n, the tiles n and -n represent
// fixed and draggable tiles with numeral n respectively.
const Tile = i8;

const Grid = [16] Tile;

// The main procedure that is called to check if a given puzzle has been solved.
pub fn is_grid_solved(grid : Grid) bool {
    // First check that the grid does not have an empty tile.
    var grid_full = true;
    for (grid) |tile| {
        grid_full = grid_full and tile != 0;
    }

    if (! grid_full) {
        return false;
    }

    // Check to see that every row, column and 2x2 quadrant contains
    // each of {1,2,3,4} exactly once.
    var cols_unique  = true;
    var rows_unique  = true;
    var quads_unique = true;
    // Rows first.
    for (0..4) |i| {
//        const texture_index = @as(usize, @intCast(@abs(tile))) - 1;
        const t1 = @abs(grid[4*i + 0]);
        const t2 = @abs(grid[4*i + 1]);
        const t3 = @abs(grid[4*i + 2]);
        const t4 = @abs(grid[4*i + 3]);
        const unique = t1 != t2 and t1 != t3 and t1 != t4 and t2 != t3 and t2 != t4 and t3 != t4;
        rows_unique = rows_unique and unique;
    }
    // Cols next.
    for (0..4) |j| {
        const t1 = @abs(grid[0  + j]);
        const t2 = @abs(grid[4  + j]);
        const t3 = @abs(grid[8  + j]);
        const t4 = @abs(grid[12 + j]);
        const unique = t1 != t2 and t1 != t3 and t1 != t4 and t2 != t3 and t2 != t4 and t3 != t4;
        cols_unique = cols_unique and unique;
    }
    // Quads.
    for ([4]usize{0,2,8,10}) |k| {
        const t1 = @abs(grid[k]);
        const t2 = @abs(grid[k + 1]);
        const t3 = @abs(grid[k + 4]);
        const t4 = @abs(grid[k + 5]);
        const unique = t1 != t2 and t1 != t3 and t1 != t4 and t2 != t3 and t2 != t4 and t3 != t4;
        quads_unique = quads_unique and unique;
    }
    return rows_unique and cols_unique and quads_unique;
}

// Tests to check that is_grid_solved is working as intended.

const grid_correct_1 = Grid{1,2,3,4,
                            4,3,2,1,
                            2,1,4,3,
                            3,4,1,2};

const grid_with_empty = Grid{1,0,3,4,
                             4,3,2,1,
                             2,1,4,3,
                             3,4,1,2};

const grid_row_repeat = Grid{1,1,1,1,
                             2,2,2,2,
                             3,3,3,3,
                             4,4,4,4};

const grid_col_repeat = Grid{1,2,3,4,
                             1,2,3,4,
                             1,2,3,4,
                             1,2,3,4};

const grid_quad_fail = Grid{1,2,3,4,
                            2,1,4,3,
                            3,4,1,2,
                            4,3,2,1};

test "is_grid_solved logic" {
    try std.testing.expectEqual(is_grid_solved(grid_correct_1),  true);
    try std.testing.expectEqual(is_grid_solved(grid_with_empty), false);
    try std.testing.expectEqual(is_grid_solved(grid_row_repeat), false);
    try std.testing.expectEqual(is_grid_solved(grid_col_repeat), false);
    try std.testing.expectEqual(is_grid_solved(grid_quad_fail),  false);
}
