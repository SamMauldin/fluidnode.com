-- Goo: A ComputerCraft GUI API

-- createView([target display])
-- Creates a view object which is used to run the app
function createView(target)
	local view = {}
	
	view.widgets = {}
	
	local display = target or term
	local w, h = display.getSize();
	view.window = window.create(display, 1, 1, w, h, false)
	
	view.exit = false
	
	return view
end

-- runView(view)
-- Runs the event loop for the GUI
function runView(view)
	view.window.setVisible(true)
	while not view.exit do
		
	end
	view.window.setVisible(false)
end
