-- Result:
import harfang as hg
from harfang_gui import HarfangUI as hgui

-- Init Harfang

hg.InputInit()
hg.WindowSystemInit()

local width, height = 1280, 720 
local window = hg.RenderInit('Harfang GUI - 2D window', width, height, hg.RF_VSync | hg.RF_MSAA4X | hg.RF_MaxAnisotropy)

hg.AddAssetsFolder("assets_compiled")

-- Setup HarfangGUI

hgui.init(["local functionault.ttf"], [20], width, height)

-- Setup inputs

local keyboard = hg.Keyboard()
local mouse = hg.Mouse()

local flag_check_box0 = false

-- Main loop

while not hg.ReadKeyboard().Key(hg.K_Escape) and hg.IsWindowOpen(window) do 
	
    _, width, height = hg.RenderResetToWindow(window, width, height, hg.RF_VSync | hg.RF_MSAA4X | hg.RF_MaxAnisotropy)

    dt = hg.TickClock()
    keyboard.Update()
    mouse.Update()
    view_id = 0
	
    if hgui.begin_frame(dt, mouse, keyboard, window) then
        
        if hgui.begin_window_2D("My window",  hg.Vec2(50, 50), hg.Vec2(500, 300), 1) then

            hgui.info_text("info1", "Simple Window2D")
            
            f_pressed, f_down = hgui.button("Button")
            if f_pressed then
                print("Click btn")
            
            _, flag_check_box0 = hgui.check_box("Check box", flag_check_box0)

            hgui.end_window()

        hgui.end_frame(view_id)

    hg.Frame()

    hg.UpdateWindow(window)

hg.RenderShutdown()
hg.DestroyWindow(window)


