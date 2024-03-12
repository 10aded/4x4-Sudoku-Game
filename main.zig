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
// *  Add menu button to instructions screen
// *  Create some levels!!!
// *  Choose a niceish color theme.

const std    = @import("std");
const qoi    = @import("qoi.zig");
const parser = @import("level-parser.zig");
const shapes = @import("shapes.zig");
const button = @import("buttons.zig");
const logic  = @import("grid-logic.zig");

const rl     = @cImport(@cInclude("raylib.h"));

const Vec2   = @Vector(2, f32);
const Color = [4] u8;
const Pixel = [4] u8;

// Grid Tile Possiblities
// Note: A zero    (0) denotes an empty tile
// Positive number (+) denotes a fixed tile
// Negative number (-) denotes a selected tile.
const Tile = i8;

const Grid = [16] Tile;

// The level data has type [NUMBER_OF_LEVELS] Grid.
const handcrafted_levels           = parser.parse_levels();
const NUMBER_OF_HANDCRAFTED_LEVELS = handcrafted_levels.len;

// const grid1 = Grid{1,0,3,4,
//                    4,3,2,1,
//                    2,1,4,3,
//                    3,4,1,2};

const GameMode =  enum(u8) {
    main_menu,
    instructions_screen,
    puzzles_handcrafted,
};

const Button = button.Button;

// Make space to decode the "1234", "START GAME", and "INSTRUCTIONS"
// bitmaps at comptime.
const bitmap_1234       = @embedFile("Bitmap-Stuff/1234-bitmap-8514.qoi");
const text_START_GAME   = @embedFile("Bitmap-Stuff/text-start-game.qoi");
const text_INSTRUCTIONS = @embedFile("Bitmap-Stuff/text-instructions.qoi");
const mouse_qoi         = @embedFile("Images/mouse.qoi");
const left_click_qoi    = @embedFile("Images/left-click-image.qoi");
const right_click_qoi    = @embedFile("Images/right-click-image.qoi");

const bitmap_1234_header = qoi.comptime_header_parser(bitmap_1234);
const bitmap_1234_width  = @as(u64, bitmap_1234_header.image_width);
const bitmap_1234_height = @as(u64, bitmap_1234_header.image_height);

const text_start_game_header = qoi.comptime_header_parser(text_START_GAME);
const text_start_game_width  = @as(u64, text_start_game_header.image_width);
const text_start_game_height = @as(u64, text_start_game_header.image_height);

const text_instructions_header = qoi.comptime_header_parser(text_INSTRUCTIONS);
const text_instructions_width  = @as(u64, text_instructions_header.image_width);
const text_instructions_height = @as(u64, text_instructions_header.image_height);

const mouse_image_header = qoi.comptime_header_parser(mouse_qoi);
const mouse_image_width  = @as(u64, mouse_image_header.image_width);
const mouse_image_height = @as(u64, mouse_image_header.image_height);

const left_click_header  = qoi.comptime_header_parser(left_click_qoi);
const left_click_width   = @as(u64, left_click_header.image_width);
const left_click_height   = @as(u64, left_click_header.image_height);


const right_click_header = qoi.comptime_header_parser(right_click_qoi);
const right_click_width   = @as(u64, right_click_header.image_width);
const right_click_height   = @as(u64, right_click_header.image_height);

var bitmap_1234_pixels       : [bitmap_1234_width * bitmap_1234_height] Pixel = undefined;
var text_start_game_pixels   : [text_start_game_width * text_start_game_height] Pixel = undefined;
var text_instructions_pixels : [text_instructions_width * text_instructions_height] Pixel = undefined;
var mouse_image_pixels       : [mouse_image_width * mouse_image_height] Pixel = undefined;
var left_click_pixels        : [left_click_width  * left_click_height] Pixel = undefined;
var right_click_pixels        : [right_click_width  * right_click_height] Pixel = undefined;

// Misc. procedures.

const dprint  = std.debug.print;

// Constants
// UI Colors
//const BLACK     = rlc(  0,   0,   0, 255);
const BLACK     = Color{  0,   0,   0, 255};
const DARKGRAY  = Color{ 40,  40,  40, 255};
const MIDGRAY   = Color{100, 100, 100, 255};
const LIGHTGRAY = Color{200, 200, 200, 255};
const WHITE     = Color{255, 255, 255, 255};

const RED       = Color{255,   0,   0, 255};
const GREEN     = Color{  0, 255,   0, 255};
const BLUE      = Color{  0,   0, 255, 255};
const YELLOW    = Color{255, 255,   0, 255};
const MAGENTA   = Color{255,   0, 255, 255};

const TRANSPARENT = Color{0,0,0,0};

const DEBUG  = MAGENTA;

const initial_screen_width =     1920;
const initial_screen_hidth =     1920 / 4 * 3;
const WINDOW_TITLE = "4x4 Sudoku Game";

// Globals
// Game
var gamemode : GameMode = undefined;

var   current_handcrafted_levels       = handcrafted_levels;
var   current_handcrafted_level_index : usize = 0;
var   handcrafted_levels_solved_status = [1]bool{false} ** handcrafted_levels.len;

// Tile manipulation
var tile_dragging_index : usize = 0;
var mouse_to_tile_dragging_vec  = Vec2{0,0};

// Colors
const grid_fill_color = LIGHTGRAY;
const grid_bar_color  = BLACK;

const tile_fixed_background_color   = grid_fill_color;
const tile_movable_background_color = MIDGRAY;

const tile_option_background = LIGHTGRAY;

const def_background_color = DARKGRAY;

// Button Colors
const menu_button_background_def_color        = LIGHTGRAY;
const menu_button_detail_def_color            = BLACK;
const menu_button_background_hover_color      = YELLOW;
const menu_button_detail_hover_color          = BLACK;

const arrow_button_background_def_color       = LIGHTGRAY;
const arrow_button_detail_def_color           = DARKGRAY;
const arrow_button_background_hover_color     = LIGHTGRAY;
const arrow_button_detail_hover_color         = YELLOW;

const menu_return_button_background_def_color = LIGHTGRAY;
const menu_return_button_detail_def_color     = DARKGRAY;
const menu_return_button_background_hov_color = LIGHTGRAY;
const menu_return_button_detail_hov_color     = YELLOW;

const reset_button_background_def_color  = LIGHTGRAY;
const reset_button_detail_def_color      = DARKGRAY;
const reset_button_background_hov_color  = LIGHTGRAY;
const reset_button_detail_hov_color      = YELLOW;

// Textures
var numeral_textures : [4] rl.Texture2D = undefined;
var start_game_texture   :     rl.Texture2D = undefined;
var instructions_texture :     rl.Texture2D = undefined;
var mouse_texture        :     rl.Texture2D = undefined;
var left_click_texture   :     rl.Texture2D = undefined;
var right_click_texture  :     rl.Texture2D = undefined;

// Mouse
var left_mouse_down             : bool = undefined;
var left_mouse_down_last_frame  : bool = false;
var right_mouse_down            : bool = undefined;
var right_mouse_down_last_frame : bool = false;
var mouse_pos                   : Vec2 = undefined;

// Screen geometry
var screen_width : f32 = undefined;
var screen_hidth : f32 = undefined;

var minimum_screen_dim : f32 = undefined;

// Buttons
const menu_button_defaults  = button.Button{
    .hovering = false,
    .width = 0,
    .height = 0,
    .pos = .{0,0},
	.color1_def = menu_button_background_def_color,
	.color2_def = menu_button_detail_def_color,
	.color1_hov = menu_button_background_hover_color,
	.color2_hov = menu_button_detail_hover_color,
};

const arrow_button_defaults  = button.Button{
    .hovering = false,
    .width = 0,
    .height = 0,
    .pos = .{0,0},
	.color1_def = arrow_button_background_def_color,
	.color2_def = arrow_button_detail_def_color,
	.color1_hov = arrow_button_background_hover_color,
	.color2_hov = arrow_button_detail_hover_color,
};

const menu_return_button_defaults = button.Button{
    .hovering   = false,
    .width      = 0,
    .height     = 0,
    .pos        = .{0,0},
    .color1_def = menu_return_button_background_def_color,
    .color2_def = menu_return_button_detail_def_color,
    .color1_hov = menu_return_button_background_hov_color,
    .color2_hov = menu_return_button_detail_hov_color,
};

const reset_button_defaults = button.Button{
    .hovering   = false,
    .width      = 0,
    .height     = 0,
    .pos        = .{0,0},
    .color1_def = reset_button_background_def_color,
    .color2_def = reset_button_detail_def_color,
    .color1_hov = reset_button_background_hov_color,
    .color2_hov = reset_button_detail_hov_color,
};

// Menu buttons.
var start_game_button       = menu_button_defaults;
var instructions_button     = menu_button_defaults;

// Menu button geometry.
var menu_text_height : f32 = undefined;

// Puzzle game buttons.
var left_arrow_button       = arrow_button_defaults;
var right_arrow_button      = arrow_button_defaults;
var reset_button            = reset_button_defaults;
var menu_return_button      = menu_return_button_defaults;


// Instruction menu geometry.
const Instructions_Geometry = struct{
    mouse1_pos     : Vec2,
    mouse2_pos     : Vec2,
    mouse_height   : f32,
    disk1_pos      : Vec2,
    disk2_pos      : Vec2,
    disk_radius    : f32,
};

var instructions_geometry : Instructions_Geometry = undefined;
    
// Grid geometry
const Grid_Geometry = struct{
    grid_pos            : Vec2,
    tile_length         : f32,
    bar_thickness       : f32,
    total_length        : f32,
    grid_tile_positions : [16] Vec2,
};

// Tile options geometry
const Tile_Options_Geometry = struct{
    background_rect_pos    : Vec2,
    tile_positions : [4] Vec2,
};

var grid_geometry         : Grid_Geometry = undefined;
var tile_options_geometry : Tile_Options_Geometry = undefined;

pub fn main() anyerror!void {

    // Set up RNG.
    // const seed  = std.time.milliTimestamp();
    // prng        = std.rand.DefaultPrng.init(@intCast(seed));

    // Attempt to make GPU not burn to 100%.
    rl.SetConfigFlags(rl.FLAG_VSYNC_HINT);
    
    // Spawn / setup raylib window.    
    rl.InitWindow(initial_screen_width, initial_screen_hidth, WINDOW_TITLE);
    defer rl.CloseWindow();

    rl.SetWindowState(rl.FLAG_WINDOW_RESIZABLE);
    rl.SetTargetFPS(144);

    //    const random = prng.random();

    gamemode = GameMode.main_menu;

    // Load at runtime the 1234 bitmap, and the text .qoi files.
    qoi.qoi_to_pixels(bitmap_1234, bitmap_1234_width * bitmap_1234_height, &bitmap_1234_pixels);
    qoi.qoi_to_pixels(text_START_GAME, text_start_game_width * text_start_game_height, &text_start_game_pixels);
    qoi.qoi_to_pixels(text_INSTRUCTIONS, text_instructions_width * text_instructions_height, &text_instructions_pixels);
    qoi.qoi_to_pixels(mouse_qoi, mouse_image_width * mouse_image_height, &mouse_image_pixels);
    qoi.qoi_to_pixels(left_click_qoi, left_click_width * left_click_height, &left_click_pixels);
    qoi.qoi_to_pixels(right_click_qoi, right_click_width * right_click_height, &right_click_pixels);

    //    dprint("{any}\n", .{bitmap_1234_pixels}); // @debug
    
    // Create a rl.Image s from which to generate the textures containing
    // the bitmap numerals in the game.

    // @magic constant alert!
    // Each character in the bitmap has an x offset that is a multiple of 10.
    // Each has the same height of 20.
    
    var numeral_images     : [4] rl.Image = undefined;
    var start_game_image   :     rl.Image = undefined;
    var instructions_image :     rl.Image = undefined;
    var mouse_image        :     rl.Image = undefined;
    var left_click_image   :     rl.Image = undefined;
    var right_click_image  :     rl.Image = undefined;

    // Set dimensions of / initialize the images.
    for (0..4) |i| {
        numeral_images[i] = rl.GenImageColor(20, 20, rlc(TRANSPARENT));
    }
    
    start_game_image   = rl.GenImageColor(text_start_game_header.image_width, text_start_game_header.image_height, rlc(TRANSPARENT));
    instructions_image = rl.GenImageColor(text_instructions_header.image_width, text_instructions_header.image_height, rlc(TRANSPARENT));
    mouse_image        = rl.GenImageColor(mouse_image_header.image_width, mouse_image_header.image_height, rlc(TRANSPARENT));
    left_click_image  = rl.GenImageColor(left_click_header.image_width, left_click_header.image_height, rlc(TRANSPARENT));
    right_click_image  = rl.GenImageColor(right_click_header.image_width, right_click_header.image_height, rlc(TRANSPARENT));

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
                const pixel_color = bitmap_1234_pixels[yi * bitmap_1234_width + xi + 10 * numeral_i];
                const color = if (pixel_color[0] == 255) BLACK else TRANSPARENT;
                rl.ImageDrawPixel(&numeral_images[numeral_i], @intCast(xi + 5), @intCast(yi), rlc(color)); 
            }
        }
    }
    
    for (0..4) |i| {
        numeral_textures[i] = rl.LoadTextureFromImage(numeral_images[i]);
    }

    // Fill in the "START GAME" and "INSTRUCTIONS" Images and create their textures.
    for (0..text_start_game_width) |xi| {
        for (0..text_start_game_height) |yi| {
            const pixel_color = text_start_game_pixels[yi * text_start_game_width + xi];
            const color = if (pixel_color[0] == 255) BLACK else TRANSPARENT;
            rl.ImageDrawPixel(&start_game_image, @intCast(xi), @intCast(yi), rlc(color)); 
        }
    }

    for (0..text_instructions_width) |xi| {
        for (0..text_instructions_height) |yi| {
            const pixel_color = text_instructions_pixels[yi * text_instructions_width + xi];
            const color = if (pixel_color[0] == 255) BLACK else TRANSPARENT;
            rl.ImageDrawPixel(&instructions_image, @intCast(xi), @intCast(yi), rlc(color)); 
        }
    }

    // Iterate through the pixels of the mouse_image and store them in the raylib image.
    // Similarly for the instructions images.
    for (0..mouse_image_width) |xi| {
        for (0..mouse_image_height) |yi| {
            const index = mouse_image_width * yi + xi;
            rl.ImageDrawPixel(&mouse_image, @intCast(xi), @intCast(yi), rlc(mouse_image_pixels[index]));             
        }
    }
    
    for (0..left_click_width) |xi| {
        for (0..left_click_height) |yi| {
            const index = left_click_width * yi + xi;
            rl.ImageDrawPixel(&left_click_image, @intCast(xi), @intCast(yi), rlc(left_click_pixels[index]));             
        }
    }
    for (0..right_click_width) |xi| {
        for (0..right_click_height) |yi| {
            const index = right_click_width * yi + xi;
            rl.ImageDrawPixel(&right_click_image, @intCast(xi), @intCast(yi), rlc(right_click_pixels[index]));             
        }
    }
    
    start_game_texture   = rl.LoadTextureFromImage(start_game_image);
    instructions_texture = rl.LoadTextureFromImage(instructions_image);
    mouse_texture        = rl.LoadTextureFromImage(mouse_image);
    left_click_texture   = rl.LoadTextureFromImage(left_click_image);
    right_click_texture   = rl.LoadTextureFromImage(right_click_image);
    
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

// Calculate the sizes of much of the global geometry.
fn calculate_geometry() void {
    // Grid calculations.
    const grid_pos       = Vec2{0.5 * screen_width, 0.4 * screen_hidth};
    const tile_length   = 0.1  * minimum_screen_dim;
    const bar_thickness = 0.01 * minimum_screen_dim;
    const total_length  = 5 * bar_thickness + 4 * tile_length;
    grid_geometry.grid_pos      = grid_pos;
    grid_geometry.tile_length   = tile_length;
    grid_geometry.bar_thickness = bar_thickness;
    grid_geometry.total_length  = total_length;

    const tl_tile_pos = grid_pos - Vec2{1.5 * ( tile_length + bar_thickness), 1.5 * ( tile_length + bar_thickness)};
    
    for (0..4) |yi| {
        for (0..4) |xi| {
            const xif = @as(f32, @floatFromInt(xi));
            const yif = @as(f32, @floatFromInt(yi));
            const tile_pos = tl_tile_pos + Vec2{xif * (tile_length + bar_thickness), yif * (tile_length + bar_thickness)};
            grid_geometry.grid_tile_positions[4 * yi + xi] = tile_pos;
        }
    }

    // Tile options calculations.
    const background_rect_pos   = Vec2{0.5 * screen_width, 0.75 * screen_hidth};
    tile_options_geometry.background_rect_pos = background_rect_pos;
    const left_tile_option_pos  = background_rect_pos - Vec2{1.5 * (tile_length + bar_thickness), 0};
    
    for (0..4) |i| {
        const offset = @as(f32, @floatFromInt(i));
        const tile_pos = left_tile_option_pos + Vec2{offset * (tile_length + bar_thickness), 0};
        tile_options_geometry.tile_positions[i] = tile_pos;
    }

    // Menu button calculations.
    // Try setting the width of the longest button (INSTRUCTIONS) to 80% screen width.
    // If the corresponding text height is > 10%, shrink so that
    // its height is 10%.
    // Use menu_text_height as the height of all main menu buttons.

    const max_text_width     = 0.8 * screen_width;
    const max_text_height    = 0.1 * screen_hidth;
    const start_game_ratio   = @as(f32, @floatFromInt(text_start_game_height))   / @as(f32, @floatFromInt(text_start_game_width));
    const instructions_ratio = @as(f32, @floatFromInt(text_instructions_height)) / @as(f32, @floatFromInt(text_instructions_width));

    menu_text_height = instructions_ratio * max_text_width;
    if (menu_text_height > max_text_height) {
        menu_text_height = max_text_height;
    }

    const start_game_text_width   = menu_text_height / start_game_ratio;
    const instructions_text_width = menu_text_height / instructions_ratio;

    // Set start_game_button and instructions_button position, widths etc.

    const text_button_buffer         = 0.3 * menu_text_height;
    const start_game_button_width    = start_game_text_width    + 2 * text_button_buffer;
    const instructions_button_width  = instructions_text_width  + 2 * text_button_buffer;
    const instructions_button_height = menu_text_height         + 2 * text_button_buffer;
    const start_game_button_height   = menu_text_height         + 2 * text_button_buffer;

    start_game_button.pos    = Vec2{0.5 * screen_width, 0.5 * screen_hidth - 1.0 * start_game_button_height};
    start_game_button.width  = start_game_button_width;
    start_game_button.height = start_game_button_height;

    instructions_button.pos    = Vec2{0.5 * screen_width, 0.5 * screen_hidth + 1.0 * start_game_button_height};
    instructions_button.width  = instructions_button_width;
    instructions_button.height = instructions_button_height;
    
    // Puzzle-solving screen buttons. 
    // Arrow button calculations.
    const pbutton_width  = 0.9  * tile_length;
    const pbutton_height = 0.75 * pbutton_width;
    const pbutton_posy   = pbutton_height;
    
    const arrow_button_width  =  pbutton_width;
    const arrow_button_height =  pbutton_height;
    const left_posx  = grid_geometry.grid_tile_positions[0][0];
    const right_posx = grid_geometry.grid_tile_positions[3][0];
    
    left_arrow_button.width  = arrow_button_width;
    left_arrow_button.height = arrow_button_height;
    left_arrow_button.pos    = .{left_posx, pbutton_posy};

    right_arrow_button.width  = arrow_button_width;
    right_arrow_button.height = arrow_button_height;
    right_arrow_button.pos    = .{right_posx, pbutton_posy};

    // Menu return button calculations.
    const menu_return_button_width  = pbutton_width;
    const menu_return_button_height = pbutton_height;
    const menu_return_posx  = 0.5 * (menu_return_button_height + menu_return_button_width);
    const menu_return_posy  = pbutton_posy;
    menu_return_button.pos   = Vec2{menu_return_posx, menu_return_posy};
    menu_return_button.width = arrow_button_width;
    menu_return_button.height = arrow_button_height;

    // Grid reset
    const reset_button_width  = pbutton_width;
    const reset_button_height = pbutton_height;
    const reset_button_posx  = grid_pos[0];
    reset_button.pos = .{reset_button_posx, pbutton_posy};
    reset_button.width = reset_button_width;
    reset_button.height = reset_button_height;

    // Instruction screen calculations.
    const mouse_height = 0.3 * screen_hidth;
    instructions_geometry.disk_radius = 0.05 * mouse_height;
    const mouse1_pos =  Vec2{0.25 * screen_width, 0.25 * screen_hidth};
    const mouse2_pos =  Vec2{0.25 * screen_width, 0.75 * screen_hidth};
    instructions_geometry.mouse1_pos   = mouse1_pos; 
    instructions_geometry.mouse2_pos   = mouse2_pos; 
    instructions_geometry.mouse_height = mouse_height;
    instructions_geometry.disk1_pos    = mouse1_pos + Vec2{-0.15 * mouse_height, -0.15 * mouse_height};
    instructions_geometry.disk2_pos    = mouse2_pos + Vec2{0.10 * mouse_height, -0.25 * mouse_height};
}

fn process_input_update_state() void {
    // Mouse input processing.
    const rl_mouse_pos = rl.GetMousePosition();
    mouse_pos = Vec2 { rl_mouse_pos.x, rl_mouse_pos.y};

    // Detect mouse clicks.
    left_mouse_down  = rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT);
    defer left_mouse_down_last_frame = left_mouse_down;

    right_mouse_down = rl.IsMouseButtonDown(rl.MOUSE_BUTTON_RIGHT);
    defer right_mouse_down_last_frame = right_mouse_down;

    // Do hover / click logic for the type of screen that the current frame is on.
    switch(gamemode) {
        .main_menu => {
            process_menu_hover_clicks();
        },
        .puzzles_handcrafted => {
            process_puzzle_hover_clicks();
            update_current_grid_solved();
        },
        .instructions_screen => {
            process_instructions_hover_clicks();
        },
    }
}

fn process_instructions_hover_clicks() void {
    button.set_hover_status(mouse_pos, &menu_return_button);

    if (left_mouse_down and ! left_mouse_down_last_frame and menu_return_button.hovering) {
        gamemode = .main_menu;
    }
}

fn process_menu_hover_clicks() void {
    // Determine whether the menu buttons have been hovered / clicked.
    button.set_hover_status(mouse_pos, &start_game_button);
    button.set_hover_status(mouse_pos, &instructions_button);
    
    
    if (left_mouse_down and ! left_mouse_down_last_frame and start_game_button.hovering) {
        gamemode = .puzzles_handcrafted;
    }

    if (left_mouse_down and ! left_mouse_down_last_frame and instructions_button.hovering) {
        gamemode = .instructions_screen;
    }
}
 
fn process_puzzle_hover_clicks() void {
    // @maybe Add in animation when the mouse is over a tile that can be moved.
    // Determine whether the mouse is over a tile option.
//    const tl = grid_geometry.tile_length;
    const grid           = &current_handcrafted_levels[current_handcrafted_level_index];
    const grid_positions = &grid_geometry.grid_tile_positions;
    
    // Determine whether a tile option has been clicked.
    if (left_mouse_down and ! left_mouse_down_last_frame) {
        for (tile_options_geometry.tile_positions, 0..) |pos, i| {
            if (is_tile_hovered(mouse_pos, pos)) {
                tile_dragging_index = i + 1;
                mouse_to_tile_dragging_vec = pos - mouse_pos;
            }
        }
    }
    // Determine whether a clickable grid tile has been left clicked.
    if (left_mouse_down and ! left_mouse_down_last_frame) {
        for (grid_positions, 0..) |tpos, i| {
            if (is_tile_hovered(mouse_pos, tpos) and grid[i] < 0) {
                const tile_type = grid[i];
                // A moveable tile has been clicked.
                grid[i] = 0;
                tile_dragging_index = @intCast(-tile_type);
                mouse_to_tile_dragging_vec = tpos - mouse_pos;
                break;
            }
        }
    }

    // Determine whether a clickable grid tile has been right clicked.
    if (right_mouse_down and ! right_mouse_down_last_frame) {
        for (grid_positions, 0..) |tpos, i| {
            if (is_tile_hovered(mouse_pos, tpos) and grid[i] <= 0) {
                const tile_type = grid[i];
                // Cycle tile.
                grid[i] = @rem(tile_type - 1, 5);
            }
        }
    }
    
    // if click released, do dragged tile logic.
    if (! left_mouse_down and left_mouse_down_last_frame) {
        defer tile_dragging_index = 0;
        // Determine if the dragged tile pos is in grid.
        const dragged_tile_pos = mouse_pos + mouse_to_tile_dragging_vec;
        for (grid_positions, 0..) |tpos, i| {
            if (is_tile_hovered(dragged_tile_pos, tpos)) {
                // Check if the dragged tile can be placed on the grid.
                if (grid[i] > 0) break;
                grid[i] = -1 * @as(i8, @intCast(tile_dragging_index));
            }
        }
    }

    // Determine whether the mouse is hovering on either of the pbuttons,
    // provided the arrows are getting drawn.
    button.set_hover_status(mouse_pos, &menu_return_button);
    button.set_hover_status(mouse_pos, &reset_button);
    button.set_hover_status(mouse_pos, &left_arrow_button);
    button.set_hover_status(mouse_pos, &right_arrow_button);
    
    // Left click on menu return button moves to menu.
    if (left_mouse_down and ! left_mouse_down_last_frame and menu_return_button.hovering) {
        gamemode = .main_menu;
    }
    
    // Left click on left arrow moves to previous level.
    if (left_mouse_down and ! left_mouse_down_last_frame and left_arrow_button.hovering) {
        if (current_handcrafted_level_index != 0) {
            current_handcrafted_level_index -= 1;
        }
    }
    // Left click on right arrow move to next level.
    if (left_mouse_down and ! left_mouse_down_last_frame and right_arrow_button.hovering) {
        if (current_handcrafted_level_index != NUMBER_OF_HANDCRAFTED_LEVELS - 1) {
            current_handcrafted_level_index += 1;
        }
    }

    // Left click on the reset button clears the grid of any movable tiles.
    if (left_mouse_down and ! left_mouse_down_last_frame and reset_button.hovering) {
        current_handcrafted_levels[current_handcrafted_level_index] = handcrafted_levels[current_handcrafted_level_index];
    }
}

fn update_current_grid_solved() void {
    const grid = current_handcrafted_levels[current_handcrafted_level_index];

    const grid_solved = logic.is_grid_solved(grid);
    handcrafted_levels_solved_status[current_handcrafted_level_index] = grid_solved;
}

fn render() void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    rl.ClearBackground(rlc(def_background_color));

    switch(gamemode) {
        .main_menu => {
            render_menu();  
        },
        .puzzles_handcrafted => {
            render_puzzle();
        },
        .instructions_screen => {
            render_instructions();
        },
    }
}

fn render_menu() void {
    // Draw "START GAME" button.
    button.render_bordered_rect(start_game_button);
    draw_texture(&start_game_texture, start_game_button.pos, menu_text_height);

    // Draw "INSTRUCTIONS" button.
    button.render_bordered_rect(instructions_button);
    draw_texture(&instructions_texture, instructions_button.pos, menu_text_height);
}

fn render_instructions() void {
    // Draw the mouse, twice!
    const mouse_height = instructions_geometry.mouse_height;
    const mouse1pos = instructions_geometry.mouse1_pos;
    const mouse2pos = instructions_geometry.mouse2_pos;
    const instructions_height = 0.3 * mouse_height;
    draw_texture(&mouse_texture, mouse1pos, mouse_height);
    draw_texture(&mouse_texture, mouse2pos, mouse_height);
    // Draw some annuli around the mouse buttons.
    const radius1 = instructions_geometry.disk_radius;
    shapes.draw_centered_circle(instructions_geometry.disk1_pos, radius1, RED);
    shapes.draw_centered_circle(instructions_geometry.disk2_pos, radius1, RED);
    // Draw the instructions images.
    const left_click_pos = Vec2{0.75 * screen_width, mouse1pos[1]};
    const right_click_pos = Vec2{0.75 * screen_width, mouse2pos[1]};
    draw_texture(&left_click_texture, left_click_pos, instructions_height);
    draw_texture(&right_click_texture, right_click_pos, instructions_height);

    // Render menu button.
    button.render_menu_button(menu_return_button);
}

fn render_puzzle() void {
    const grid = current_handcrafted_levels[current_handcrafted_level_index];
    const grid_pos             = grid_geometry.grid_pos;
    const tile_length         = grid_geometry.tile_length;
    const bar_thickness       = grid_geometry.bar_thickness;
    const total_length        = grid_geometry.total_length;
    const grid_tile_positions = grid_geometry.grid_tile_positions;

    // Draw menu and reset buttons.
    button.render_menu_button(menu_return_button);
    button.render_reset_button(reset_button);

    // Draw the left arrow button if not the first level, likewise for the last level.
    if (current_handcrafted_level_index != 0) {
        button.render_arrow_button(left_arrow_button, true);
    }
    if (current_handcrafted_level_index != NUMBER_OF_HANDCRAFTED_LEVELS - 1) {
        button.render_arrow_button(right_arrow_button, false);
    }
    
    // Draw grid background.
    const background_length = total_length - bar_thickness;
    shapes.draw_centered_rect(grid_pos, background_length, background_length, grid_fill_color);

    // Draw grid bars.
    // @temp, presumably bc this is how we're currently indicating  that something is solved !
    const solved = handcrafted_levels_solved_status[current_handcrafted_level_index];
    const bar_color = if (solved) YELLOW else grid_bar_color;
    for (0..5) |i| {
        const offset = @as(f32, @floatFromInt(i)) - 2;
        shapes.draw_centered_rect(grid_pos + Vec2{offset * (tile_length + bar_thickness), 0}, bar_thickness, total_length, bar_color);
        shapes.draw_centered_rect(grid_pos + Vec2{0, offset * (tile_length + bar_thickness)}, total_length, bar_thickness, bar_color);
    }

    // Draw the tiles in the grid.
    for (grid, 0..) |tile, ti| {
        const tile_pos = grid_tile_positions[ti];
        draw_tile(tile, tile_pos);
    }
    
    // Draw tile options.
    const background_rect_pos = tile_options_geometry.background_rect_pos;
    const tile_option_spacing = 0.015 * minimum_screen_dim;
    const background_rect_width  = 4 * tile_length + 3 * bar_thickness + 2 * tile_option_spacing;
    const background_rect_height = 1 * tile_length +                     2 * tile_option_spacing;
    shapes.draw_centered_rect(background_rect_pos, background_rect_width, background_rect_height, tile_option_background);

    for (0..4) |i| {
        draw_tile(-1 * @as(i8, @intCast(i + 1)), tile_options_geometry.tile_positions[i]);
    } 

    // Draw a dragging tile (if applicable).
    if (tile_dragging_index != 0) {
        draw_tile(-1 * @as(i8, @intCast(tile_dragging_index)), mouse_to_tile_dragging_vec + mouse_pos);
    }

    // Draw FPS.
    const fps_posx : c_int = @intFromFloat(screen_width - 100);
    const fps_posy : c_int = @intFromFloat(screen_hidth - 100);
    rl.DrawFPS(fps_posx, fps_posy);
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
    const border_thickness = 10;
    const border_length = length + border_thickness;
    
    const background_color = if (tile > 0) tile_fixed_background_color else tile_movable_background_color;
    const texture_index : usize = std.math.absCast(tile) - 1;
    const texture_ptr = &numeral_textures[texture_index];

    shapes.draw_centered_rect(pos, border_length, border_length, BLACK);
    shapes.draw_centered_rect(pos, length, length, background_color);
    draw_texture(texture_ptr, pos, length);
}

fn is_tile_hovered(cursor_pos : Vec2, tile_pos : Vec2) bool {
    const tl = grid_geometry.tile_length;
    return @fabs(cursor_pos[0] - tile_pos[0]) < 0.5 * tl and @fabs(cursor_pos[1] - tile_pos[1]) < 0.5 * tl;
}
