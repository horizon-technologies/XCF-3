TOOL.Name = "XCF Menu"
TOOL.Category = "Construction"

function TOOL.BuildCPanel( CPanel )
	-- Need an XCF panel to add XCF panels to
	local Base = vgui.Create("XCF_Panel")

	-- Add our panel to the control panel	
	CPanel:AddItem(Base)

	Main = Base:AddPanel("XCF_Panel")
	Main:AddLabel("XCF Menu Tool")
	Main:AddLabel("XCF Menu Tool")
	Main:AddButton("Reload Menu")
	Main:AddLabel("XCF Menu Tool")
	Main:AddLabel("XCF Menu Tool")

	-- Main = Base:AddPanel("XCF_Panel")
	-- AddMenu(Main)
end
