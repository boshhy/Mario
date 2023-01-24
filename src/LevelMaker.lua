--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    -- TODO delete the following line, for testing only
    width = 16
    -- TODO delete ABOVE line
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    local keyBlock = false
    local hasKey = false
    local keyColor = math.random(4)
    --TODO change back
    local keyLocation = math.random(2, width-4)
    local lockedBlockLocation = math.random(2, width-8)
    while math.abs(keyLocation - lockedBlockLocation) < 2 do
        keyLocation = math.random(2, width-2)
        lockedBlockLocation = math.random(2, width-4)
    end

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 and x ~= 1 and x ~= keyLocation and x ~= lockedBlockLocation and x ~= width - 1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 and x ~= 1 then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 and x ~= keyLocation then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 and x ~= keyLocation then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if math.random(2) == 1  and x ~= 1 and x ~= 2  and x ~= keyLocation and x ~= lockedBlockLocation and x ~= width - 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
            if x == keyLocation then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)
                            -- maintain reference so we can set it to nil
                            if not obj.hit then
                                local key = GameObject {
                                    texture = 'keys-and-locks',
                                    x = (x - 1) * TILE_SIZE,
                                    y = (blockHeight - 1) * TILE_SIZE - 4,
                                    width = 16,
                                    height = 16,
                                    frame = keyColor,
                                    collidable = true,
                                    consumable = true,
                                    solid = false,

                                    -- gem has its own function to add to the player's score
                                    onConsume = function(player, object)
                                        gSounds['pickup']:play()
                                        player.score = player.score + 100
                                        keyBlock.unlocked = true
                                        -- hasKey = true
                                        -- test.keyBlock = true
                                    end
                                }
                                
                                -- make the gem move up from the block and play a sound
                                Timer.tween(0.1, {
                                    [key] = {y = (blockHeight - 2) * TILE_SIZE}
                                })
                                gSounds['powerup-reveal']:play()

                                table.insert(objects, key)
                            end
                            obj.hit = true

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
            if x == lockedBlockLocation then
                

                    -- jump block
                keyBlock = GameObject {
                        texture = 'keys-and-locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = keyColor + 4,
                        collidable = true,
                        hit = false,
                        solid = true,
                        unlocked = false,

                        -- collision function takes itself
                        onCollide = function(obj)
                            -- maintain reference so we can set it to nil
                            if not obj.unlocked then
                                gSounds['empty-block']:play()
                            elseif not obj.hit then
                                poleY = 6
                                if tiles[6][width-1].id == TILE_ID_GROUND then
                                    poleY = 4
                                end
                                local pole = GameObject {
                                    --TODO change this to flag spawn instead
                                    texture = 'poles',
                                    x = (width - 2) * TILE_SIZE,
                                    y = (1-4) * TILE_SIZE,
                                    width = 16,
                                    height = 48,
                                    frame = math.random(6),
                                    collidable = true,
                                    consumable = true,
                                    solid = false,

                                    -- gem has its own function to add to the player's score
                                    onConsume = function(player, object)
                                        gSounds['pickup']:play()
                                        player.score = player.score + 100
                                    end
                                }
                                local flag = GameObject {
                                    --TODO change this to flag spawn instead
                                    texture = 'flags',
                                    x = 6 + (width - 2) * TILE_SIZE,
                                    y = 8 + (1-4) * TILE_SIZE,
                                    width = 16,
                                    height = 16,
                                    frame = 7 + 9 * (math.random(4) - 1),
                                    collidable = false,
                                    consumable = false,
                                    solid = false,

                                    -- gem has its own function to add to the player's score
                                    onConsume = function(player, object)
                                        gSounds['pickup']:play()
                                        player.score = player.score + 100
                                    end
                                }
                                
                                -- make the gem move up from the block and play a sound
                                Timer.tween(0.5, {
                                    [pole] = {y = (poleY - 3) * TILE_SIZE}
                                })
                                Timer.tween(0.5, {
                                    [flag] = {y = (poleY - 3) * TILE_SIZE}
                                })
                                gSounds['powerup-reveal']:play()

                                table.insert(objects, pole)
                                table.insert(objects, flag)
                                obj.hit = true
                            end
                            gSounds['empty-block']:play()
                        end
                    }
                    table.insert(objects, keyBlock)
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end