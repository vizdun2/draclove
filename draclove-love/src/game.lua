local L = require("lib/l")

function L.setup()

end

function L.render(dt)
	L.draw({text="Dt: " .. dt, font="pixelifysans",font_size=42,align="mm",x=0,y=0})
end