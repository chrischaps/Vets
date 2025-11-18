-- Environmental Props Metadata
-- Generated for VETS-66: Create Environmental Props and Decorative Tiles
-- All props use side-view perspective for platformer gameplay

return {
    -- Chimney Props
    chimney_tall = {
        filename = "chimney_tall.png",
        size = {width = 32, height = 32},
        description = "Tall brick chimney with terracotta cap",
        collision = true,
        z_index = 10, -- Background prop, behind player
        solid = true,
        hazard = false,
        animated = false
    },

    chimney_short = {
        filename = "chimney_short.png",
        size = {width = 32, height = 32},
        description = "Short brick chimney",
        collision = true,
        z_index = 10,
        solid = true,
        hazard = false,
        animated = false
    },

    -- Window Props
    window_lit = {
        filename = "window_lit.png",
        size = {width = 32, height = 32},
        description = "Glowing window with warm yellow light (delivery zone marker)",
        collision = false,
        z_index = 15, -- Foreground, renders after delivery zone glow
        solid = false,
        hazard = false,
        animated = true, -- Can pulse/glow for delivery zones
        glow = true,
        delivery_target = true
    },

    window_dark = {
        filename = "window_dark.png",
        size = {width = 32, height = 32},
        description = "Dark window without light",
        collision = false,
        z_index = 8,
        solid = false,
        hazard = false,
        animated = false
    },

    greenhouse = {
        filename = "greenhouse1.png",
        size = {width = 32, height = 32},
        description = "Rooftop greenhouse",
        collision = false,
        z_index = 10, -- Mid-ground, behind player
        solid = false, -- Can walk over
        hazard = false,
        animated = true, -- Can pulse/glow for delivery zones
        glow = true,
        delivery_target = true
    },

    -- HVAC Props
    ac_unit = {
        filename = "ac_unit.png",
        size = {width = 48, height = 48},
        description = "Metal air conditioning unit with vents",
        collision = true,
        z_index = 10,
        solid = true,
        hazard = false,
        animated = false
    },

    vent_exhaust = {
        filename = "vent_exhaust.png",
        size = {width = 32, height = 32},
        description = "Rooftop exhaust vent with fan grill (potential hazard)",
        collision = true,
        z_index = 10,
        solid = true,
        hazard = true, -- Can be used as steam/air hazard
        animated = true, -- Fan can rotate
        damage = 1
    },

    -- Antenna Props
    antenna_tv = {
        filename = "antenna_tv.png",
        size = {width = 32, height = 32},
        description = "Old TV antenna with metal rods (falling hazard)",
        collision = true,
        z_index = 10,
        solid = true,
        hazard = true, -- Can fall on player
        animated = true, -- Can wobble before falling
        damage = 2
    },

    satellite_dish = {
        filename = "satellite_dish.png",
        size = {width = 40, height = 40},
        description = "Satellite dish antenna",
        collision = true,
        z_index = 10,
        solid = true,
        hazard = false,
        animated = false
    },

    -- Decorative Props
    plant_potted = {
        filename = "plant_potted.png",
        size = {width = 8, height = 8},
        description = "Potted plant with green leaves",
        collision = true,
        z_index = 12, -- Foreground decoration
        solid = false, -- Can jump through
        hazard = false,
        animated = true, -- Leaves can sway
        breakable = true -- Can be knocked over
    },

    crate_wood = {
        filename = "crate_wood.png",
        size = {width = 32, height = 32},
        description = "Wooden crate box",
        collision = true,
        z_index = 12,
        solid = true,
        hazard = false,
        animated = false,
        breakable = true,
        pushable = true
    },

    -- Large Infrastructure Props
    water_tower = {
        filename = "water_tower.png",
        size = {width = 64, height = 64},
        description = "Water tower tank on metal legs",
        collision = true,
        z_index = 5, -- Large background element
        solid = true,
        hazard = false,
        animated = false,
        landmark = true -- Can be used for navigation/checkpoints
    },

    rooftop_door = {
        filename = "rooftop_door.png",
        size = {width = 40, height = 40},
        description = "Rooftop access door hatch",
        collision = true,
        z_index = 8,
        solid = false, -- Can walk over
        hazard = false,
        animated = true, -- Can open/close
        interactive = true -- Potential entrance/exit point
    },

    -- Z-Index Guide:
    -- 1-5: Far background elements (skyline, clouds)
    -- 6-10: Mid-ground props (chimneys, vents, antennas)
    -- 11-15: Foreground props (plants, crates, player layer)
    -- 16-20: UI elements and effects

    -- Usage Notes:
    -- - All props have transparent backgrounds for easy compositing
    -- - Props marked as 'hazard' can damage the player
    -- - Props marked as 'delivery_target' indicate letter delivery zones
    -- - Props marked as 'animated' may have frame-based or shader animations
    -- - Z-index determines rendering order (lower = farther back)
    -- - Props marked as 'solid' block player movement
    -- - Props marked as 'breakable' can be destroyed by player actions
}
