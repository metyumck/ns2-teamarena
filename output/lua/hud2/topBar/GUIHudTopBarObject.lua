-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/Hud2/topBar/GUIHudTopBarObject.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Base class for a single object to be displayed in the Hud top bar.  Each object is composed of
--    one icon on the left, and one text object on the right.  To ensure the whole bar doesn't
--    jitter around due to changing text width, the text object itself is placed inside of a holder
--    object that is as wide as the text given some "max width" sample string.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/GUIText.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")

local baseClass = GUIObject
class "GUIHudTopBarObject" (baseClass)

function GUIHudTopBarObject:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    -- Each object must have a layout priority, to ensure consistent arrangement in the top bar.
    RequireType("number", self.kLayoutSortPriority, "self.kLayoutSortPriority", errorDepth)
    
    baseClass.Initialize(self, params, errorDepth)
    
    self.layout = CreateGUIObject("layout", GUIListLayout, self,
    {
        orientation = "horizontal",
        
        -- already plenty of spacing built-in to the icon textures. :(
        --spacing = 8,
    })
    self.layout:SetCropMax(1, 1)
    self:HookEvent(self.layout, "OnSizeChanged", self.SetSize)
    
    self.icon = CreateGUIObject("icon", GUIObject, self.layout)
    self.icon:SetColor(1, 1, 1, 1)
    self.icon:AlignLeft()
    
    self.textHolder = CreateGUIObject("textHolder", GUIObject, self.layout)
    self.textHolder:AlignLeft()
    
    self.text = CreateGUIObject("text", GUIText, self.textHolder)
    self.text:SetFontSize(18)
    self.text:SetFontFamily("AgencyBold")
    self.text:AlignLeft()
    self.text:SetText(self:GetMaxWidthText())
    self.textHolder:SetSize(self.text:GetSize())
    self.text:SetText("")
    self.text:SetDropShadowEnabled(true)
    
end

function GUIHudTopBarObject:GetMaxWidthText()
    return "000"
end

function GUIHudTopBarObject:GetIconObj()
    return self.icon
end

function GUIHudTopBarObject:GetTextObj()
    return self.text
end

-- By default, always show the top bar object (eg regardless of team type).
function GUIHudTopBarObject.EvaluateVisibility(topBarObj)
    return false
end

