// TODO: Write summary of 4 x 4 Sudoku game
//
// Created by 10aded Jan 2024 --- ???
//
// This project was compiled using the Zig compiler (version 0.11.0)
// and built with the command:
//
//     zig build -Doptimize=ReleaseFast
//
// run in the top directory of the project.
//
// The entire source code of this project is available on GitHub at:
//
//   https://github.com/10aded/4x4-Sudoku-Game
//
// and was developed (almost) entirely on the Twitch channel 10aded. Copies of the
// stream are available on YouTube at the @10aded channel.
//
// This project includes a copy of raylib, specifically v5.0 (commit number ae50bfa).
//
// Raylib is created by github user Ray (@github handle raysan5) and available at:
//
//    https://github.com/raysan5a
//
// See the pages above for full license details.


// TODO LIST:
// *  Don't forget an UNDO feature!!!
// ---[current]---> Think about / implement buttons (and just do rects)
// *  Dragging tiles functionality
// *  Do README file
// *  Main menu
// *  Create a place for possible tiles to be dragged
// *  Think about playing game with the keyboard only

// ** Randomized puzzles (of various degrees of difficulty)

const std    = @import("std");
const qoi    = @import("qoi.zig");
const parser = @import("level-parser.zig");
const rl     = @cImport(@cInclude("raylib.h"));

const Vec2   = @Vector(2, f32);
const Pixel = [4] u8;

// Grid Tile Possiblities
// Note: 0 denotes an empty tile
// Positive number represents a fixed tile
// Negative number represents a selected tile.
const Tile = i8;

const Grid = [16] Tile;

const handcrafted_levels           = parser.parse_levels();
const NUMBER_OF_HANDCRAFTED_LEVELS = handcrafted_levels.len;

// const grid1 = Grid{1,0,3,4,
//                    4,3,2,1,
//                    2,1,4,3,
//                    3,4,1,2};

const GameMode =  enum(u8) {
    main_menu,
    puzzles_handcrafted,
    puzzles_randomized,
};

const Color = [4] u8;

const Button = struct {
    width  : f32,
    height : f32,
    pos    : Vec2,
    color1_def : Color,
    color2_def : Color,
    color1_hov : Color,
    color2_hov : Color,
};

// Make space to decode the bitmap at comptime.
const bitmap = @embedFile("Bitmap-Stuff/8514-bitmap.qoi");
const bitmap_header = qoi.comptime_header_parser(bitmap);
const bitmap_width  = @as(u64, bitmap_header.image_width);
const bitmap_height = @as(u64, bitmap_header.image_height);

var bitmap_pixels : [bitmap_width * bitmap_height] Pixel = undefined;
var bitmap_bools : [bitmap_width * bitmap_height] bool = undefined;


// Misc. procedures.

const dprint  = std.debug.print;

// Constants
// UI Colors
//const BLACK     = rlc(  0,   0,   0, 255);
const BLACK     = Color{  0,   0,   0, 255};
const DARKGRAY  = Color{ 40,  40,  40, 255};
const LIGHTGRAY = Color{200, 200, 200, 255};
const WHITE     = Color{255, 255, 255, 255};

const RED       = Color{255,   0,   0, 255};
const GREEN     = Color{  0, 255,   0, 255};
const BLUE      = Color{  0,   0, 255, 255};
const YELLOW    = Color{255, 255,   0, 255};
const MAGENTA   = Color{255,   0, 255, 255};

const TRANSPARENT = Color{0,0,0,0};

const DEBUG  = MAGENTA;

const initial_screen_width = 1902;
const initial_screen_hidth = 1080;
const WINDOW_TITLE = "4x4 Sudoku Game";

// Globals
// Game
var gamemode : GameMode = undefined;

var   current_handcrafted_levels       = handcrafted_levels;
var   current_handcrafted_level_index : usize = 0;

// Colors
const grid_fill_color = LIGHTGRAY;
const grid_bar_color  = BLACK;

const tile_fixed_background_color   = grid_fill_color;
const tile_movable_background_color = DEBUG;

const tile_option_background = LIGHTGRAY;

const background_color = DARKGRAY;


// Textures.
var numeral_textures : [4] rl.Texture2D = undefined;

// Mouse
var mouse_down            : bool = undefined;
var mouse_down_last_frame : bool = false;
var mouse_pos             : Vec2 = undefined;

// Screen geometry
var screen_width : f32 = undefined;
var screen_hidth : f32 = undefined;

var minimum_screen_dim : f32 = undefined;

// Grid geometry
const Grid_Geometry = struct{
    gridpos             : Vec2,
    tile_length         : f32,
    bar_thickness       : f32,
    total_length        : f32,
    grid_tile_positions : [16] Vec2,
};

var grid_geometry : Grid_Geometry = undefined;

// TODO:
// Write procedure to validate whether or not a given grid is a valid solution.

pub fn main() anyerror!void {

    // Set up RNG.
    // const seed  = std.time.milliTimestamp();
    // prng        = std.rand.DefaultPrng.init(@intCast(seed));

    // Spawn / setup raylib window.    
    rl.InitWindow(initial_screen_width, initial_screen_hidth, WINDOW_TITLE);
    defer rl.CloseWindow();

    rl.SetWindowState(rl.FLAG_WINDOW_RESIZABLE);
    rl.SetTargetFPS(144);

    // Import font from embedded file.
//    const merriweather_font = rl.LoadFontFromMemory(".ttf", merriweather_ttf, merriweather_ttf.len, 108, null, 95);

    // button_option_font = merriweather_font;
    // attribution_font   = merriweather_font;
    
//    const random = prng.random();

    gamemode = GameMode.main_menu;

    // @debug


    // Load at runtime the bitmap, and convert to an array of bools.
    qoi.qoi_to_pixels(bitmap, bitmap_width * bitmap_height, &bitmap_pixels);

    dprint("{any}\n", .{bitmap_pixels}); // @debug
    
    // Create a rl.Image s from which to generate the textures containing
    // the bitmap numerals in the game.

    // @magic constant alert!
    // Each character in the bitmap has an x offset that is a multiple of 10.
    // Each has the same height of 20.
    
    var numeral_images : [4] rl.Image = undefined;

    for (0..4) |i| {
        numeral_images[i] = rl.GenImageColor(20, 20, rlc(TRANSPARENT));
//        numeral_images[i] = rl.GenImageColor(20, 20, DEBUG); // @debug
    }

    // TODO... transfer bitmap info onto testi using ImageDrawRectangle;    
//    var testi : rl.Image = rl.GenImageColor(5, 5, DEBUG);

//    rl.ImageDrawRectangle(&testi, 1, 1, 2, 2, YELLOW);

    // Initialize the textures for '1', '2', '3', '4'.
    // Since the images have a width of 20, but the numerals have a width
    // of 10, when copying over the pixels from the bitmaps, we want to
    // do += 5.
    // In the bitmap, the background pixels are BLACK, the numeral pixels are WHITE,
    // so below we set:
    //     the numeral pixels to:    BLACK,
    //     the background pixels to: TRANSPARENT.
    
    for (0..4) |numeral_i| {
        for (0..20) |yi| {
            for (0..10) |xi| {
                const bitmap_pixel_color = bitmap_pixels[yi * bitmap_width + xi + 10 * numeral_i];
                const color = if (bitmap_pixel_color[0] == 255) BLACK else TRANSPARENT;
                rl.ImageDrawPixel(&numeral_images[numeral_i], @intCast(xi + 5), @intCast(yi), rlc(color)); 
            }
        }
    }
        
    for (0..4) |i| {
        numeral_textures[i] = rl.LoadTextureFromImage(numeral_images[i]);
    }

    //    dprint("{any}\n", .{bitmap_bools}); // @debug
    
    // +----------------+
    // | Main game loop |
    // +----------------+
    while ( ! rl.WindowShouldClose() ) { // Listen for close button or ESC key.

        screen_width = @floatFromInt(rl.GetScreenWidth());
        screen_hidth = @floatFromInt(rl.GetScreenHeight());
        minimum_screen_dim = @min(screen_width, screen_hidth);
        
        calculate_geometry();
        
        process_input_update_state();

        render();
    }
}

fn calculate_geometry() void {
    // Calculate the sizes of much of the global geometry.
    const gridpos       = Vec2{0.5 * screen_width, 0.4 * screen_hidth};
    const tile_length = 0.1  * minimum_screen_dim;
    const bar_thickness = 0.01 * minimum_screen_dim;
    const total_length  = 5 * bar_thickness + 4 * tile_length;
    grid_geometry.gridpos       = gridpos;
    grid_geometry.tile_length = tile_length;
    grid_geometry.bar_thickness = bar_thickness;
    grid_geometry.total_length  = total_length;

    const tl_tile_pos = gridpos - Vec2{1.5 * ( tile_length + bar_thickness), 1.5 * ( tile_length + bar_thickness)};
    
    for (0..4) |yi| {
        for (0..4) |xi| {
            const xif = @as(f32, @floatFromInt(xi));
            const yif = @as(f32, @floatFromInt(yi));
            const tile_pos = tl_tile_pos + Vec2{xif * (tile_length + bar_thickness), yif * (tile_length + bar_thickness)};
            grid_geometry.grid_tile_positions[4 * yi + xi] = tile_pos;
        }
    }
}

fn process_input_update_state() void {
    // Mouse input processing.
    const rl_mouse_pos = rl.GetMousePosition();
    mouse_pos = Vec2 { rl_mouse_pos.x, rl_mouse_pos.y};

    // Detect button clicks.
    mouse_down = rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT);
    defer mouse_down_last_frame = mouse_down;

    // @temp
    // Change from the main menu to the puzzles when the left mouse is clicked.
    if (mouse_down and ! mouse_down_last_frame) {
        gamemode = switch (gamemode) {
            .main_menu           => .puzzles_handcrafted,
            .puzzles_handcrafted => block: {
                if (current_handcrafted_level_index == NUMBER_OF_HANDCRAFTED_LEVELS - 1) {
                    current_handcrafted_level_index = 0;
                    break :block .main_menu;
                } else {
                    current_handcrafted_level_index += 1;
                    break :block .puzzles_handcrafted;
                }
            },
            .puzzles_randomized  => .main_menu,
        };
    }
}


fn render() void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    rl.ClearBackground(rlc(background_color));

    switch(gamemode) {
        .main_menu => {
            render_menu();  
        },
        .puzzles_handcrafted => {
            render_puzzle();
        },
        .puzzles_randomized => {
            unreachable;
        },
    }
}



// TODO:
// Create an actual main menu.

fn render_menu() void {
    const pos = Vec2{0.5 * screen_width, 0.5 * screen_hidth};
    draw_centered_rect(pos, 100, 100, DEBUG);

    for (0..4) |i| {
        const ii = @as(f32, @floatFromInt(i));
        draw_texture(&numeral_textures[i], Vec2{100 + 200 * ii, 100 + 200 * ii}, 200);
    }
}

fn render_puzzle() void {
    const grid = current_handcrafted_levels[current_handcrafted_level_index];
    
    const gridpos             = grid_geometry.gridpos;
    const tile_length         = grid_geometry.tile_length;
    const bar_thickness       = grid_geometry.bar_thickness;
    const total_length        = grid_geometry.total_length;
    const grid_tile_positions = grid_geometry.grid_tile_positions;
    
    // Draw grid background.
    const background_length = total_length - bar_thickness;
    draw_centered_rect(gridpos, background_length, background_length, grid_fill_color);

    // Draw the (non-empty) tiles in the grid.
    for (grid, 0..) |tile, ti| {
        const tile_pos = grid_tile_positions[ti];
        draw_tile(tile, tile_pos);
    }

        // Draw vertical grid bars.
    for (0..5) |i| {
        const offset = @as(f32, @floatFromInt(i)) - 2;
        draw_centered_rect(gridpos + Vec2{offset * (tile_length + bar_thickness), 0}, bar_thickness, total_length, grid_bar_color);
        draw_centered_rect(gridpos + Vec2{0, offset * (tile_length + bar_thickness)}, total_length, bar_thickness, grid_bar_color);
    }

    // Draw tile options.
    const background_rect_pos = Vec2{0.5 * screen_width, 0.75 * screen_hidth};
    const tile_option_spacing = 0.015 * minimum_screen_dim;
    const background_rect_width  = 4 * tile_length + 3 * bar_thickness + 2 * tile_option_spacing;
    const background_rect_height = 1 * tile_length +                     2 * tile_option_spacing;
    draw_centered_rect(background_rect_pos, background_rect_width, background_rect_height, tile_option_background);

    const tile_border_thickness = 0.005 * minimum_screen_dim;
    const left_tile_option_pos  = background_rect_pos - Vec2{1.5 * (tile_length + bar_thickness), 0};
    
    for (0..4) |i| {
        // TODO: Write a proc which draws an arbitrary tile at an
        // arbitrary position, use this and rewrite the grid drawing code
        // to use it.
        const offset = @as(f32, @floatFromInt(i));

        const tile_pos = left_tile_option_pos + Vec2{offset * (tile_length + bar_thickness), 0};
        // @temp!
        const tile_border_length = tile_length + tile_border_thickness;
        draw_centered_rect(tile_pos, tile_border_length, tile_border_length, BLACK);
        draw_centered_rect(tile_pos, tile_length, tile_length, DEBUG);
        // Draw the some of the numeral bitmaps! // @temp
        draw_texture(&numeral_textures[i], tile_pos, tile_length);
    }

}


// Draw a plain (colored) rectangle, where the position determines the center.

fn draw_centered_rect( pos : Vec2, width : f32, height : f32, color : Color) void {
    const top_left_x : i32 = @intFromFloat(pos[0] - 0.5 * width);
    const top_left_y : i32 = @intFromFloat(pos[1] - 0.5 * height);
    rl.DrawRectangle(top_left_x, top_left_y, @intFromFloat(width), @intFromFloat(height), rlc(color));
}

fn rlc(color : Color) rl.Color {
    return rl.Color{.r = color[0], .g = color[1], .b = color[2], .a = color[3]};
}

fn draw_texture(texturep : *rl.Texture2D, center_pos : Vec2 , height : f32 ) void {
    const twidth  : f32  = @floatFromInt(texturep.*.width);
    const theight : f32  = @floatFromInt(texturep.*.height);
    
    const scaling_ratio  = height / theight;
    
    const scaled_h  = height;
    const scaled_w  = scaled_h * twidth / theight;
    
    const dumb_rl_tl_vec2 = rl.Vector2{
        .x = center_pos[0] - 0.5 * scaled_w,
        .y = center_pos[1] - 0.5 * scaled_h,
    };

    // The 3rd arg (0) is for rotation.
    rl.DrawTextureEx(texturep.*, dumb_rl_tl_vec2, 0, scaling_ratio, rlc(WHITE));
}

fn vec2_to_rl(vec : Vec2) rl.Vector2 {
    const dumb_rl_tl_vec2 = rl.Vector2{
        .x = vec[0],
        .y = vec[1],
    };
    return dumb_rl_tl_vec2;
}

// Draw tiles, both those that are fixed and movable.
// Fixed / moveable tiles have different background colors.
// These specific color choices are globals. 
fn draw_tile(tile : Tile, pos : Vec2) void {
    // Empty tiles should not get drawn!
    if (tile == 0) return;
    const length = grid_geometry.tile_length;
    const texture_index : usize = std.math.absCast(tile) - 1;
    const tile_texture_ptr = &numeral_textures[texture_index];
    const tile_background_color = if (tile > 0) tile_fixed_background_color else tile_movable_background_color;
    draw_centered_rect(pos, length, length, tile_background_color);
    draw_texture(tile_texture_ptr, pos, length);
}
