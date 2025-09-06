# Main stuff
# Entities
- Applicable to entities
- User data system
    - Supports namespacing via prefixes
    - Specified on the entity in shared
        - May need to specify client data redundantly, but atleast in the same place
    - Supports copying to menu

# Tools
- Needs a library for supporting tools
- Need menu tool
    - Left to spawn main
    - Shift Left to spawn seconary
    - Right to start/finish a link
    - Shift Right to continue a link
    - Since links are symmetrical, can just shift link both type1 and type2 together and right click on the final one

# Menu
- Client data system
    - Supports "namespacing" via prefixes
        - "ACF.SetClientNamespace"
        - Set/Get client data will check this namespace and append a prefix before sending
    - Supports delayed batchings
    - Supports logging to file
    - Standardized set of datatypes (e.g. number, vector, string, etc.)
        - Standardized set of verifiers (e.g. range, valid model/pm, etc.)
        - Standart set of panels (e.g. checkbox, slider, vector slider, text entry, etc.)
    - "Forms" can be generated from the current client data
        - Must be able to create a form from entity data alone if it involves entities
            - Provide an autogeneratable "Form" menu for an entity under this assumption
            - Extra options like shiftpoint calculator for automatics, can be one directional and not react to changes
            - "Copying" an entity's values is as easy as setting each of its client data to user data
    - Not identical to uservars since stuff like settings exist
- General DTree menu like ACF's
    - Clicking on an item loads a menu
    - Needs Git status tab
    - Needs Further links tab
    - Needs cl/sv settings tab

# Armor
- Hitboxes of entities should be defined by primitives
    - Represented by parameters to create it, etc.
        - Supports naming and getting:
            - Volume
            - Surface Area
            - Closest point
            - Bounding Box
            - Bounding Sphere

    - primitive can take stats from a model if needed (ironic)
    - additionally or otherwise, can be specified based on its dimensions
- Armor for components should be a function of its hitbox, but not be settable by the user directly
- Main armor created by spawnable primitives
    - Can be compiled into a controller, where through BVH it stores them internally
        - Can be decompiled for editting
    - When a bullet hits, travserse the BVH
    - Explosions can also be tested by effective blast radius and bounding sphere

## Experimental
# Virtual entities
- Can compile multiple parented entities into a static representation of themselves similar to a dupe
- Instead of having multiple entities with multiple convexes, can have one entity with shared draw calls, shared etc.
- How to deal with indexing... I guess we'd need like Controller:GetEntity(Index) and support basic operations like getting pos/size/etc.

# Shell Types
- Ancestor shell is inert (No damage)
    - APHE
        - HEAT
            - HEATFS
            - GLATGM
            - FL
        - Flechette
           - AHEAD
    - Smoke
- Missiles should have generic models and be procedural
- Likewise with racks

# Crates
- Global table of shell data, added to on crate creation, deleted when no longer referenced by bullets, ammo, guns
- Supports a thickness argument

# Fuels
- Supports a thickness argument

# Refills
- Mass cost based reload
    - Interfaces with ammo/fuel and refills based on mass
    - quantity of item transferred is determined by the mass transfer rate, floored

# Fires
- Represent as a sphere
    - Gradually melts armor at a given rate, after which it can "bypass" a prop

# Smokes
- Represent as a sphere
    - Gradually increases in size and decreases in density over time
    - Blocks / diffuses lasers (and imagers)

# Explosions
- Represent as a sphere
    - Force to break

# Effects
- Need to have LOD to scale based on FPS etc.

# Debris
- Can be generated from the primitives hit?