-- Open the file LibSerialize.lua in read mode
local from = io.open("LibSerialize.lua", "r")
-- Open the file README.md in write mode
local to = io.open("README.md", "w")

if from and to then
    local writeMode = false
    -- Read each line of `from`
    for line in from:lines() do
        if line == "--[[ BEGIN_README" then
            -- Start writing after this line
            writeMode = true
        elseif line == "END_README --]]" then
            -- Stop writing after this line
            writeMode = false
        elseif writeMode then
            -- Write the content between BEGIN_README and END_README to `to`
            to:write(line .. "\n")
        end
    end

    -- Close both files
    from:close()
    to:close()

    print("Generated README.md!")
else
    error("Could not open files!")
end
