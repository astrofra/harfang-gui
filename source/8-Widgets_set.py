import harfang as hg
from harfang_gui import HarfangUI as hgui

# Init Harfang

hg.InputInit()
hg.WindowSystemInit()

width, height = 1920, 1080 
window = hg.RenderInit('Harfang - GUI', width, height, hg.RF_VSync | hg.RF_MSAA4X | hg.RF_MaxAnisotropy)

hg.AddAssetsFolder("assets_compiled")

res = hg.PipelineResources()
pipeline = hg.CreateForwardPipeline()
render_data = hg.SceneForwardPipelineRenderData()

# Setup HarfangGUI

hgui.init(["default.ttf"], [20], width, height)
hgui.set_line_space_size(5)
hgui.set_inner_line_space_size(5)

# Setup inputs

keyboard = hg.Keyboard()
mouse = hg.Mouse()

# Main loop

cb = True
it = "input text"
current_rib = 0
toggle_image_idx = 0
toggle_btn_idx = 0

while not hg.ReadKeyboard().Key(hg.K_Escape) and hg.IsWindowOpen(window): 
	
    _, width, height = hg.RenderResetToWindow(window, width, height, hg.RF_VSync | hg.RF_MSAA4X | hg.RF_MaxAnisotropy)
    dt = hg.TickClock()
    dt_f = hg.time_to_sec_f(dt)
    keyboard.Update()
    mouse.Update()
    view_id = 0
    
	
    if hgui.begin_frame(dt, mouse, keyboard, window):
        if hgui.begin_window_2D("My window",  hg.Vec2(50, 50), hg.Vec2(1500, 900), 1): #, hgui.HGUIWF_HideTitle | hgui.HGUIWF_Invisible):
            

            hgui.set_inner_line_space_size(200)

            
            hgui.info_text("info1", "Information text")

            
            hgui.image("my image1", "textures/logo.png", hg.Vec2(90,80))
            
            
            hgui.same_line()
            hgui.image("Info image label", "textures/logo.png", hg.Vec2(90,80), show_label=True)
            
            
            f,it = hgui.input_text("Input text",it, show_label=False, forced_text_width = 150)
            
            hgui.same_line()
            f,it = hgui.input_text("Input text label",it)

            f_pressed, f_down = hgui.button("Button")
            
            f_pressed, f_down = hgui.button_image("Button image", "textures/coffee.png", hg.Vec2(20,20))
            
            hgui.same_line()
            f_pressed, f_down = hgui.button_image("label##button_image", "textures/coffee.png", hg.Vec2(20,20), show_label=True)
            
            f, cb = hgui.check_box("Checkbox", cb, show_label=False)
            hgui.same_line()
            
            f,cb = hgui.check_box("Checkbox##label", cb)
            
            
            tex_list = ["hgui_textures/Icon_Pause.png", "hgui_textures/Icon_Play.png"]
            f, toggle_image_idx = hgui.toggle_image_button("Toggle", tex_list, toggle_image_idx, hg.Vec2(15, 15))
            
            hgui.same_line()
            f, toggle_image_idx = hgui.toggle_image_button("Toggle##label", tex_list, toggle_image_idx, hg.Vec2(15, 15), show_label=True)
            

            lbl_list = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            f, toggle_btn_idx = hgui.toggle_button("Texts_toggle", lbl_list, toggle_btn_idx)
            hgui.same_line()
            f, toggle_btn_idx = hgui.toggle_button("Texts_toggle##label", lbl_list, toggle_btn_idx, show_label=True)

            
            if hgui.begin_widget_group_2D("Select texture"): #, cpos, hg.Vec2(373, 190)):
                hgui.set_inner_line_space_size(25)

                _, current_rib = hgui.radio_image_button("rib_0","textures/cube_1.png", current_rib, 0, hg.Vec2(64, 64))
                hgui.same_line()
                _, current_rib = hgui.radio_image_button("rib_1","textures/cube_2.png", current_rib, 1)
                hgui.same_line()
                _, current_rib = hgui.radio_image_button("rib_2","textures/cube_3.png", current_rib, 2)
                hgui.same_line()
                _, current_rib = hgui.radio_image_button("rib_3","textures/cube_4.png", current_rib, 3)
                hgui.end_widget_group()
            hgui.set_inner_line_space_size(200)
            hgui.end_window()
		
        hgui.end_frame(view_id)

    hg.Frame()

    hg.UpdateWindow(window)

hg.RenderShutdown()
hg.DestroyWindow(window)
