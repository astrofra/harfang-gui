# Harfang GUI

**Harfang GUI** is a _immediate mode_ GUI library built on top of HARFANG® 3D.
It supports 2D, 3D & VR (wip).  

![hgui](screenshots/gui.png)
___
## Overview  
* Easy 2D/3D/VR GUI creation with HARFANG® 3D Python
* Immediate mode, inspired by the API of [DearImGui](https://github.com/ocornut/imgui)

## Requirements

* Python 3.6+
* HARFANG 3D for Python
* **Harfang Core shaders**
  * `"shaders/font"` to fonts rendering.  
  * `"fonts/..."` as fonts library. Copy your fonts here if you need custom ones.
* **Harfang Gui specific assets**  
  * `"assets/hgui_textures"` contains core textures (VR mouse pointer, widgets textures...)  
  * `"assets/hgui_shaders"` contains the shaders.  

___
## Widgets types

The current version of the Harfang GUI API provides the following widgets:

- Window 2D / 3D  
- Info text  
- Button  
- Button image  
- Image  
- Check box  
- Input text  
- Scrollbar (vertical & horizontal)  
- Radio image button
- Toggle button
- Toggle image
- ListBox
- Slider float
- Widgets group

## How to use Harfang GUI?

>Please check the code samples to see how to use the library.

## How to run the samples?

1. Download or clone this repository to your computer _(eg. in `C:/harfang-gui`)_.
1. Install the requirements using `pip install -r requirements.txt` or `python -m pip install -r requirements.txt`.
1. Run `1-compile_content.bat`
1. Run `2-start-window2d.bat`
1. Or open the project in VSCode and run each sample (1-Window2D.py, 2-Window3D.py, ...)
