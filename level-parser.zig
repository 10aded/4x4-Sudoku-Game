const std = @import("std");

const dassert = std.debug.assert;
const dprint  = std.debug.print;

const Tile = i8;
const Grid = [16] Tile;

const NUMBER_OF_LEVELS = 4;
const LEVEL_FILENAME   = "levels.txt";

const level_string_data = @embedFile(LEVEL_FILENAME);

pub fn parse_levels() [NUMBER_OF_LEVELS] Grid {
    @setEvalBranchQuota(10_000);
    var level_data : [NUMBER_OF_LEVELS] Grid = undefined;
    
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const ally = arena.allocator();

    var line_list = std.ArrayList([] const u8).init(ally);
    defer line_list.deinit();

    // NOTE: The \r is needed for windows newlines!!!

    var grid_row_number     : usize = 0;
    var current_level       : Grid  = undefined;
    var current_level_index : usize = 0;
    
    var line_iter = std.mem.tokenizeAny(u8, level_string_data, "\r\n");
    while (line_iter.next()) |line| {
        const fc = line[0];
        if (fc != '0' and fc != '1' and fc != '2' and fc != '3' and fc != '4') continue;
        // Create the current_level data.
        for (0..4) |i| {
            const tile : i8 = @intCast(line[i] - '0');
            // Check that the tile is one of: 0,1,2,3,4.
            dassert(0 <= tile and tile <= 4);
            current_level[4 * grid_row_number + i] = tile;
        }
//        dprint("DEBUG: current level:{any}\n", .{current_level}); // @debug
        grid_row_number = grid_row_number + 1;

        if (grid_row_number == 4) {
            grid_row_number = 0;
            level_data[current_level_index] = current_level;
            current_level_index += 1;
        }
    }
    // After all of the lines have gone through, check that the number
    // of levels processed actually equals NUMBER_OF_LEVELS.
    dassert(current_level_index == NUMBER_OF_LEVELS);
    return level_data;
}

