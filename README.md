# Mojito Dialogue 💬
Simple to use NPC interaction / dialogue system to take a user's input. NPC spawning is optimised and handled by PolyZones.

### Code Example
```lua
exports['mojito_dialogue']:NewDialogue(`a_m_y_skater_02`, vec3(-727.74, -143.54, 36.36), 20.0, {
    title = "Would you like to start a mission",
    items = {
        {text = "Yes", value="yes"},
        {text = "No", value="no"}
    }
}, function(selection)
    if selection == "yes" then
     QBCore.Functions.Notify("You picked yes", "success")
    else
     QBCore.Functions.Notify("You picked no", "error")
    end
end)
```

The result is returned as a callback function with argument 0 being the selection value in string form.

<p align="center">
    <a href="https://streamable.com/v4ekkm"> Video Preview </a>
</p>