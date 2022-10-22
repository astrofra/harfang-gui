hg = require("harfang")
require("utils")

function on_key_press(str)
	HarfangUI.ascii_code = text
end

HarfangGUIRenderer = {
	local vtx_layout = nil
	local vtx = nil
	local shader = nil
	local shader_texture = nil
	local uniforms_values_list = nil
	local uniforms_textures_list = nil
	local text_uniform_values = nil
	local text_render_state = nil

	local fonts = {}
	local fonts_sizes = {}

	local box_render_state = nil

	local frame_buffers_scale = 3 -- For AA

	-- sprites
	local textures = {}
	local textures_info = {}

	local function init(cls, fonts_files, fonts_sizes)
		cls.vtx_layout = hg.VertexLayout()
		cls.vtx_layout:Begin()
		cls.vtx_layout:Add(hg.A_Position, 3, hg.AT_Float)
		cls.vtx_layout:Add(hg.A_Color0, 4, hg.AT_Float)
		cls.vtx_layout:Add(hg.A_TexCoord0, 3, hg.AT_Float)
		cls.vtx_layout:End()

		cls.vtx = hg.Vertices(cls.vtx_layout, 256)

		cls.shader_flat = hg.LoadProgramFromAssets('hgui_shaders/hgui_pos_rgb')
		cls.shader_texture = hg.LoadProgramFromAssets('hgui_shaders/hgui_texture')
		cls.shader_texture_opacity = hg.LoadProgramFromAssets('hgui_shaders/hgui_texture_opacity')

		cls.uniforms_values_list = hg.UniformSetValueList()
		cls.uniforms_textures_list = hg.UniformSetTextureList()

		cls.box_render_state = hg.ComputeRenderState(hg.BM_Alpha, hg.DT_LessEqual, hg.FC_Disabled, False)
		cls.box_overlay_render_state = hg.ComputeRenderState(hg.BM_Alpha, hg.DT_Disabled, hg.FC_Disabled, False)
		cls.box_render_state_opaque = hg.ComputeRenderState(hg.BM_Opaque, hg.DT_LessEqual, hg.FC_Disabled, True)

		cls.fonts_sizes = fonts_sizes
		for i = 1, #fonts_files do
			cls.fonts.append(hg.LoadFontFromAssets('font/' + fonts_files[i], fonts_sizes[i], 1024, 1, "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"))
		end
		cls.font_prg = hg.LoadProgramFromAssets('hgui_shaders/hgui_font')
		cls.current_font_id = 0

		# text uniforms and render state
		cls.text_uniform_values = {hg.MakeUniformSetValue('u_color', hg.Vec4(1, 1, 0))}
		w_z, w_r, w_g, w_b, w_a = false, true, true, true, true
		cls.text_render_state = hg.ComputeRenderState(hg.BM_Alpha, hg.DT_Disabled, hg.FC_Disabled, w_z, w_r, w_g, w_b, w_a)
	end

	local function get_texture(cls, texture_path)
		if cls.textures[texture_path] == nil then
			cls.textures[texture_path], cls.textures_info[texture_path] = hg.LoadTextureFromAssets(texture_path, 0)
		return cls.textures[texture_path]
	end

	-- (cls, vid:int, vertices:list, color:hg.Color)
	local function draw_convex_polygon(cls, vid, vertices, color) then

		cls.vtx:Clear()
		cls.uniforms_values_list = {}
		cls.uniforms_textures_list = {}
		-- triangles fan:
		local idx  = {}
		local n = #vertices
		for v_idx = 0, n-1 do
			if v_idx < n-2 then
				idx = table_merge(idx, {0, v_idx + 1, v_idx + 2})
			end
			cls.vtx:Begin(v_idx):SetPos(vertices[v_idx] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(0, 0)):End()
		end
		local shader = cls.shader_flat
		local rs = cls.box_render_state
		hg.DrawTriangles(vid, idx, cls.vtx, shader, cls.uniforms_values_list, cls.uniforms_textures_list, rs)
	end

	-- (cls, vid:int, vertices_ext:list, vertices_in:list, color:hg.Color)
	local function draw_rounded_borders(cls, vid, vertices_ext, vertices_in, color)
		cls.vtx:Clear()
		cls.uniforms_values_list = {}
		cls.uniforms_textures_list = {
		-- triangles fan:
		local idx = {}
		local n = #vertices_ext
		for v_idx  = 0, n-1 do
			v1 = (v_idx+1) % n
			idx = table_merge(idx, {v_idx, v1, v_idx + n, v_idx + n, v1, v1 + n})
		end

		local vertices = table_merge(vertices_ext, vertices_in)
		for v_idx = (#n * 2) do
			cls.vtx:Begin(v_idx):SetPos(vertices[v_idx] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(0, 0)):End()
		end

		local shader = cls.shader_flat
		local rs = cls.box_render_state
		hg.DrawTriangles(vid, idx, cls.vtx, shader, cls.uniforms_values_list, cls.uniforms_textures_list, rs)
	end

	-- (cls, vid:int, vertices:list, color:hg.Color, texture_path = None, flag_opaque = False)
	local function draw_box(cls, vid, vertices, color, texture_path = nil, flag_opaque = false)
		texture_path = texture_path or nil
		flag_opaque = flag_opaque or false

		cls.vtx:Clear()
		cls.uniforms_values_list = {}
		cls.uniforms_textures_list = {}
		local idx = {0, 1, 2, 0, 2, 3}
		cls.vtx:Begin(0):SetPos(vertices[0] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(0, 0)):End()
		cls.vtx:Begin(1):SetPos(vertices[1] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(0, 1)):End()
		cls.vtx:Begin(2):SetPos(vertices[2] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(1, 1)):End()
		cls.vtx:Begin(3):SetPos(vertices[3] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(1, 0)):End()

		local shader, rs
		if texture_path ~= nil then
			cls.uniforms_textures_list:push_back(hg.MakeUniformSetTexture("u_tex", cls.get_texture(texture_path), 0))
			shader = cls.shader_texture
		else
			shader = cls.shader_flat
		end

		if flag_opaque then
			rs = cls.box_render_state_opaque
		else
			rs = cls.box_render_state
		end

		hg.DrawTriangles(vid, idx, cls.vtx, shader, cls.uniforms_values_list, cls.uniforms_textures_list, rs)
	end

	-- (cls, vid: int, vertices, color: hg.Color, texture: hg.Texture)
	local function draw_rendered_texture_box(cls, vid, vertices, color, texture)
		cls.vtx:Clear()
		cls.uniforms_values_list = {}
		cls.uniforms_textures_list = {}
		local idx = {0, 1, 2, 0, 2, 3}
		cls.vtx:Begin(0):SetPos(vertices[0] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(0, 0)):End()
		cls.vtx:Begin(1):SetPos(vertices[1] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(0, 1)):End()
		cls.vtx:Begin(2):SetPos(vertices[2] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(1, 1)):End()
		cls.vtx:Begin(3):SetPos(vertices[3] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(1, 0)):End()
		cls.uniforms_textures_list:push_back(hg.MakeUniformSetTexture("u_tex", texture, 0))
		hg.DrawTriangles(vid, idx, cls.vtx, cls.shader_texture_opacity, cls.uniforms_values_list, cls.uniforms_textures_list, cls.box_render_state)
	end

	-- (cls, vid: int, vertices, color: hg.Color, flag_opaque = False)
	def draw_box_border(cls, vid, vertices, color, flag_opaque):
		flag_opaque = flag_opaque or false

		cls.vtx:Clear()
		cls.uniforms_values_list = {}
		cls.uniforms_textures_list = {}
		idx = {0, 1, 5, 0, 5, 4, 
				1, 2, 6, 1, 6, 5,
				2, 3, 7, 2, 7, 6,
				3, 0, 4, 3, 4, 7}
		
		for i = 0, 8 do
			cls.vtx:Begin(i):SetPos(vertices[i] * cls.frame_buffers_scale):SetColor0(color):SetTexCoord0(hg.Vec2(0, 0)):End()
		end
		
		local rs
		if flag_opaque then
			rs = cls.box_render_state_opaque
		else
			rs = cls.box_render_state
		end
		hg.DrawTriangles(vid, idx, cls.vtx, cls.shader_flat, cls.uniforms_values_list, cls.uniforms_textures_list, rs)
	end

	-- (cls, vid, matrix:hg.Mat4, pos, r, angle_start, angle, color)
	local function draw_circle(cls, vid, matrix, pos, r, angle_start, angle, color)
		cls.vtx:Clear()
		cls.uniforms_values_list = {}
		cls.uniforms_textures_list = {}
		cls.vtx:Begin(0):SetPos(matrix * hg.Vec3(pos.x, pos.y, pos.z)):SetColor0(color):SetTexCoord0(hg.Vec2(0, 0)):End()

		local idx = []
		local num_sections = 32
		local step = angle / num_sections
		for i = num_sections + 1 do
			alpha = i * step + angle_start
			cls.vtx:Begin(i + 1):SetPos(matrix * hg.Vec3(pos.x + cos(alpha) * r, pos.y + sin(alpha) * r, pos.z)):SetColor0(color):SetTexCoord0(hg.Vec2(0, 0)):End()
			if i > 0 then
				idx = table_merge(idx, {0, i + 1, i})
			end
		end

		hg.DrawTriangles(vid, idx, cls.vtx, cls.shader_flat, cls.uniforms_values_list, cls.uniforms_textures_list, cls.box_render_state)
	end

	local function compute_text_size(cls, font_id, text)
		local rect = hg.ComputeTextRect(cls.fonts[font_id], text)
		return hg.Vec2(rect.ex, rect.ey)
	end

	-- (cls, vid, matrix:hg.Mat4, text, font_id, color)
	local function draw_text(cls, vid, matrix, text, font_id, color)
		local scale = hg.GetScale(matrix) * cls.frame_buffers_scale
		local pos = hg.GetT(matrix) * cls.frame_buffers_scale
		local rot = hg.GetR(matrix)
		local mat = hg.TransformationMat4(pos, rot, scale)
		cls.text_uniform_values = {hg.MakeUniformSetValue('u_color', hg.Vec4(color.r, color.g, color.b, color.a))}
		hg.DrawText(vid, cls.fonts[font_id], text, cls.font_prg, 'u_tex', 0, mat, hg.Vec3(0, 0, 0), hg.DTHA_Left, hg.DTVA_Bottom, cls.text_uniform_values, {}, cls.text_render_state)
	end

	local function render_widget_container(cls, view_id, container)
		local draw_list = HarfangGUISceneGraph.widgets_containers_displays_lists[container["widget_id"]]
		hg.SetViewFrameBuffer(view_id, container["frame_buffer"].handle)
	
		hg.SetViewMode(view_id, hg.VM_Sequential)
		local w, h = math.floor(container["size"].x * cls.frame_buffers_scale), math.floor(container["size"].y * cls.frame_buffers_scale)
		hg.SetViewRect(view_id, 0, 0, w, h)
		
		hg.SetViewOrthographic(view_id, 0, 0, w, h, hg.TransformationMat4(hg.Vec3(w / 2 + container["scroll_position"].x * cls.frame_buffers_scale, h / 2 + container["scroll_position"].y * cls.frame_buffers_scale, 0), hg.Vec3(0, 0, 0), hg.Vec3(1, -1, 1)), 0, 101, h)
		hg.SetViewClear(view_id, hg.CF_Depth | hg.CF_Color, hg.Color(0, 0, 0, 0), 1, 0)

		for draw_element, _ in pairs(draw_list) do
			if draw_element["type"] == "box" then
					cls.draw_box(view_id, draw_element["vertices"], draw_element["color"], draw_element["texture"])
			elseif draw_element["type"] == "convex_polygon" then
					cls.draw_convex_polygon(view_id, draw_element["vertices"], draw_element["color"])
			elseif draw_element["type"] == "rounded_borders" then
					cls.draw_rounded_borders(view_id, draw_element["vertices_ext"], draw_element["vertices_in"], draw_element["color"])
			elseif draw_element["type"] == "box_border" then
					cls.draw_box_border(view_id, draw_element["vertices"], draw_element["color"])
			elseif draw_element["type"] == "opaque_box" then
					cls.draw_box(view_id, draw_element["vertices"], draw_element["color"], draw_element["texture"], True)
			elseif draw_element["type"] == "text" then
					cls.draw_text(view_id, draw_element["matrix"], draw_element["text"], draw_element["font_id"], draw_element["color"])
			elseif draw_element["type"] == "rendered_texture_box" then
					cls.draw_rendered_texture_box(view_id, draw_element["vertices"], draw_element["color"], draw_element["texture"])
			end
		end

		container["view_id"] = view_id -- FIXME: reference with side effect ?
		
		return view_id + 1
	end

	-- (cls, resolution: hg.Vec2, view_state: hg.ViewState, frame_buffer: hg.FrameBuffer)
	local function create_output(cls, resolution, view_state, frame_buffer)
		return {resolution = resolution, view_state = view_state, frame_buffer = frame_buffer}
	end

	-- (cls, view_id, outputs2D: list, outputs3D: list)
	local function render(cls, view_id, outputs2D, outputs3D)
		local resolution, view_state
		local fb
		local shader, rs
		
		-- Setup 3D views
		local render_views_3D = {}
		for output, _ in pairs(outputs3D) do
			resolution = output["resolution"]
			view_state = output["view_state"]
			if resolution ~= nil and view_state ~= nil then
				fb = output["frame_buffer"]
				
				if fb == nil:
					hg.SetViewFrameBuffer(view_id, hg.InvalidFrameBufferHandle)
				else
					hg.SetViewFrameBuffer(view_id, fb.GetHandle())
				end
				
				hg.SetViewMode(view_id, hg.VM_Sequential)
				hg.SetViewRect(view_id, 0, 0, int(resolution.x), int(resolution.y))
				hg.SetViewTransform(view_id, view_state.view, view_state.proj)
				hg.SetViewClear(view_id, 0, hg.Color.Black, 1, 0)
				
				table.insert(render_views_3D, view_id)
				view_id = view_id + 1
			end
		end

		-- Setup 2D views
		render_views_2D = {}
		for output, _ in pairs(outputs2D):
			resolution = output["resolution"]
			view_state = output["view_state"]
			if resolution ~= nil then
				fb = output["frame_buffer"]
				if fb == nil then
					hg.SetViewFrameBuffer(view_id, hg.InvalidFrameBufferHandle)
				else
					hg.SetViewFrameBuffer(view_id, fb.GetHandle())
				end
				if view_state == nil then
					hg.SetViewOrthographic(view_id, 0, 0, int(resolution.x), int(resolution.y), hg.TransformationMat4(hg.Vec3(resolution.x / 2, -resolution.y / 2, 0), hg.Vec3(0, 0, 0), hg.Vec3(1, 1, 1)), 0.1, 1000, resolution.y)
				else
					hg.SetViewTransform(view_id, view_state.view, view_state.proj)
				end
				hg.SetViewMode(view_id, hg.VM_Sequential)
				hg.SetViewRect(view_id, 0, 0, int(resolution.x), int(resolution.y))
				if view_id == 0 tben
					hg.SetViewClear(view_id, hg.CF_Color | hg.CF_Depth, hg.Color.Black, 1, 0)
				else
					hg.SetViewClear(view_id, hg.CF_Depth, hg.Color.Black, 1, 0)
				end
				
				table.insert(render_views_2D, view_id)
				view_id = view_id + 1
			end
		end

		-- Render widgets containers to textures then display to fbs or screen
		cls.uniforms_values_list = {}
		shader = cls.shader_texture_opacity
		local idx = {0, 1, 2, 0, 2, 3}

		-- Render 3D containers
		for container, _ in pairs(HarfangGUISceneGraph.widgets_containers3D_children_order) do
			view_id = cls.render_widget_container(view_id, container)
		end
		
		-- for container in reversed(HarfangGUISceneGraph.widgets_containers3D_children_order):
		local i
		for i = #HarfangGUISceneGraph.widgets_containers3D_children_order, 0, -1 do
			container = HarfangGUISceneGraph.widgets_containers3D_children_order[i]
			-- Display 3D widgets containers
			if container["flag_2D"] then
				-- Render widgets container to texture:
				local c = hg.Color(1, 1, 1, container["opacity"])
				local matrix =container["world_matrix"]
				local pos = hg.Vec3(0, 0, 0)
				local size = container["size"]
				local p0 = matrix * pos
				local p1 = matrix * hg.Vec3(pos.x, pos.y + size.y, pos.z)
				local p2 = matrix * hg.Vec3(pos.x + size.x, pos.y + size.y, pos.z)
				local p3 = matrix * hg.Vec3(pos.x + size.x, pos.y, pos.z)
				local tex = container["color_texture"]

				-- Display widgets container
				cls.vtx:Clear()
				cls.uniforms_textures_list = {}
				
				cls.vtx:Begin(0):SetPos(p0):SetColor0(c):SetTexCoord0(hg.Vec2(0, 0)):End()
				cls.vtx:Begin(1):SetPos(p1):SetColor0(c):SetTexCoord0(hg.Vec2(0, 1)):End()
				cls.vtx:Begin(2):SetPos(p2):SetColor0(c):SetTexCoord0(hg.Vec2(1, 1)):End()
				cls.vtx:Begin(3):SetPos(p3):SetColor0(c):SetTexCoord0(hg.Vec2(1, 0)):End()

				cls.uniforms_textures_list:push_back(hg.MakeUniformSetTexture("u_tex", tex, 0))
				
				if container["flag_overlay"] then
					rs = cls.box_overlay_render_state
				else
					rs = cls.box_render_state
				end
				
				for vid in render_views_3D:
					hg.DrawTriangles(vid, idx, cls.vtx, shader, cls.uniforms_values_list, cls.uniforms_textures_list, rs)
			end
		end
		
		-- Render 2D containers
		if #render_views_2D > 0 then
			for container, _ in pairs(HarfangGUISceneGraph.widgets_containers2D_children_order) do
				
				view_id = cls.render_widget_container(view_id, container)
				
				-- Display 3D widgets containers
				if container["parent_id"] == "MainContainer2D" then
					-- Render widgets container to texture:
					local c = hg.Color(1, 1, 1, container["opacity"])
					local matrix = container["world_matrix"]
					local pos = hg.Vec3(0, 0, 0)
					local size = container["size"]
					local p0 = matrix * pos
					local p1 = matrix * hg.Vec3(pos.x, pos.y + size.y, pos.z)
					local p2 = matrix * hg.Vec3(pos.x + size.x, pos.y + size.y, pos.z)
					local p3 = matrix * hg.Vec3(pos.x + size.x, pos.y, pos.z)
					local tex = container["color_texture"]

					-- Display widgets container
					cls.vtx.Clear()
					cls.uniforms_textures_list = {}
					
					cls.vtx:Begin(0):SetPos(p0):SetColor0(c):SetTexCoord0(hg.Vec2(0, 0)):End()
					cls.vtx:Begin(1):SetPos(p1):SetColor0(c):SetTexCoord0(hg.Vec2(0, 1)):End()
					cls.vtx:Begin(2):SetPos(p2):SetColor0(c):SetTexCoord0(hg.Vec2(1, 1)):End()
					cls.vtx:Begin(3):SetPos(p3):SetColor0(c):SetTexCoord0(hg.Vec2(1, 0)):End()


					cls.uniforms_textures_list:push_back(hg.MakeUniformSetTexture("u_tex", tex, 0))
					
					if container["flag_overlay"] then
						rs = cls.box_overlay_render_state
					else
						rs = cls.box_render_state
					end
					
					for vid, _ in pairs(render_views_2D) do
						hg.DrawTriangles(vid, idx, cls.vtx, shader, cls.uniforms_values_list, cls.uniforms_textures_list, rs)
					end
				end
			end
		end
		
		return view_id, render_views_3D, render_views_2D
	end
}

HarfangUISkin = {

	local check_texture = nil
	local check_texture_info = nil
 
	local keyboard_cursor_color = nil
 
	-- Level 0 primitives
	local properties = {}
 
	-- Components
	local components = {}
 
	-- Widgets models
	local widgets_models = {}

	local function init(cls)
		local idle_t = 0.2
		local hover_t = 0.15
		local mb_down_t = 0.05
		local check_t = 0.2
		local edit_t = 0.1

		cls.check_texture, cls.check_texture_info = hg.LoadTextureFromAssets("hgui_textures/check.png", 0)

		cls.keyboard_cursor_color = hg.Color(1, 1, 1, 0.75)

		cls.properties = cls.load_properties("properties.json")

		cls.primitives = { } -- FIXME : include the dictionnary

		cls.components = { } -- FIXME : include the dictionnary

		cls.widgets_models = { } -- FIXME : include the dictionnary

		local function interpolate_values(cls, v_start, v_end, t)
			local t = max(0, min(1, t))
			local v = v_start * (1-t) + v_end * t
			return v
		end

		local function load_properties(cls, file_name) -- FIXME : file operations
			file = open(file_name, "r")
			json_script = file.read()
			file.close()
			if json_script ~= "" then
				return json.loads(json_script)
			else
				print("HGUISkin - ERROR - Can't open properties json file !")
			end
			return nil
		end

		local function convert_properties_color_to_RGBA32(cls):
			for property_name, property in pairs(cls.properties.items()) do
				if property["type"] == "color" then
					property["type"] = "RGBA32"
					for layer, _ in pairs(property["layers"]) do
						for state_name, state in pairs(layer["states"].items()) do
							local v = state["value"]
							local vrgba32 = (math.floor(v[0] * 255) << 24) + (math.floor(v[1] * 255) << 16) + (math.floor(v[2] * 255) << 8) + math.floor(v[3] * 255)
							state["value"] = hex(vrgba32)
						end
					end
				end
			end
		
			cls.save_properties("properties_rgba32.json")
		end

		local function convert_properties_RGBA32_to_RGB24_APercent(cls)
			for property_name, property in pairs(cls.properties.items()) do
				if property["type"] == "RGBA32" then
					property["type"] = "RGB24_APercent"
					for layer, _ in pairs(property["layers"]) do
						for state_name, state in pairs(layer["states"].items()) do
							local v = hg.ColorFromRGBA32(hg.ARGB32ToRGBA32(int(state["value"].replace("#", "0x"),16)))
							local vrgb24 = (int(v.r * 255) << 16) + (int(v.g * 255) << 8) + int(v.b * 255)
							state["value"] = [str(hex(vrgb24)).replace("0x", "#"), int(v.a * 100)]
						end
					end
				end
			end

			cls.save_properties("properties_rgb24_apercent.json")
		end

}