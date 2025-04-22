-- Класс Game
local Game = {}
Game.__index = Game

-- Константы
local FIELD_SIZE = 10
local COLORS = {'A', 'B', 'C', 'D', 'E', 'F'}

-- Создание нового экземпляра игры
function Game.new()
    local self = setmetatable({}, Game)
    self.field = {}
    return self
end

-- Инициализация поля
function Game:init()
    for y = 0, FIELD_SIZE - 1 do
        self.field[y] = {}
        for x = 0, FIELD_SIZE - 1 do
            self.field[y][x] = COLORS[math.random(#COLORS)]
        end
    end
end

-- Проверка на наличие совпадений
function Game:checkMatches(x1, y1, x2, y2)
    local marked = {}
    
    -- Функция для проверки горизонтальных совпадений
    local function checkHorizontal(y, startX)
        local count = 1
        local color = self.field[y][startX]
        local matches = {startX}
        
        -- Проверяем влево
        for x = startX - 1, 0, -1 do
            if self.field[y][x] == color then
                count = count + 1
                table.insert(matches, x)
            else
                break
            end
        end
        
        -- Проверяем вправо
        for x = startX + 1, FIELD_SIZE - 1 do
            if self.field[y][x] == color then
                count = count + 1
                table.insert(matches, x)
            else
                break
            end
        end
        
        if count >= 3 then
            if not marked[y] then marked[y] = {} end
            for _, x in ipairs(matches) do
                marked[y][x] = true
            end
        end
    end
    
    -- Функция для проверки вертикальных совпадений
    local function checkVertical(x, startY)
        local count = 1
        local color = self.field[startY][x]
        local matches = {startY}
        
        -- Проверяем вверх
        for y = startY - 1, 0, -1 do
            if self.field[y][x] == color then
                count = count + 1
                table.insert(matches, y)
            else
                break
            end
        end
        
        -- Проверяем вниз
        for y = startY + 1, FIELD_SIZE - 1 do
            if self.field[y][x] == color then
                count = count + 1
                table.insert(matches, y)
            else
                break
            end
        end
        
        if count >= 3 then
            for _, y in ipairs(matches) do
                if not marked[y] then marked[y] = {} end
                marked[y][x] = true
            end
        end
    end
    
    -- Если переданы координаты, проверяем только вокруг них
    if x1 and y1 and x2 and y2 then
        checkHorizontal(y1, x1)
        checkVertical(x1, y1)
        checkHorizontal(y2, x2)
        checkVertical(x2, y2)
    else
        -- Иначе проверяем все поле
        for y = 0, FIELD_SIZE - 1 do
            for x = 0, FIELD_SIZE - 2 do
                checkHorizontal(y, x)
            end
        end
        
        for x = 0, FIELD_SIZE - 1 do
            for y = 0, FIELD_SIZE - 2 do
                checkVertical(x, y)
            end
        end
    end
    
    return marked
end

-- Удаление совпадений и смещение кристаллов
function Game:removeMatches(marked)
    local changes = false
    
    -- Удаление отмеченных кристаллов
    for y = 0, FIELD_SIZE - 1 do
        if marked[y] then
            for x = 0, FIELD_SIZE - 1 do
                if marked[y][x] then
                    self.field[y][x] = nil
                    changes = true
                end
            end
        end
    end

    -- Смещение кристаллов вниз
    for x = 0, FIELD_SIZE - 1 do
        local empty = 0
        for y = FIELD_SIZE - 1, 0, -1 do
            if self.field[y][x] == nil then
                empty = empty + 1
            elseif empty > 0 then
                self.field[y + empty][x] = self.field[y][x]
                self.field[y][x] = nil
            end
        end
    end

    -- Добавление новых кристаллов
    for x = 0, FIELD_SIZE - 1 do
        for y = 0, FIELD_SIZE - 1 do
            if self.field[y][x] == nil then
                self.field[y][x] = COLORS[math.random(#COLORS)]
                changes = true
            end
        end
    end

    return changes
end

-- Вспомогательная функция для обмена кристаллов
function Game:swapGems(x1, y1, x2, y2)
    local temp = self.field[y1][x1]
    self.field[y1][x1] = self.field[y2][x2]
    self.field[y2][x2] = temp
end

-- Выполнение хода игрока
function Game:move(fromX, fromY, direction)
    local toX, toY = fromX, fromY
    
    if direction == 'l' then toX = fromX - 1
    elseif direction == 'r' then toX = fromX + 1
    elseif direction == 'u' then toY = fromY - 1
    elseif direction == 'd' then toY = fromY + 1
    end

    -- Проверка границ поля
    if toX < 0 or toX >= FIELD_SIZE or toY < 0 or toY >= FIELD_SIZE then
        return false
    end

    -- Обмен кристаллов
    self:swapGems(fromX, fromY, toX, toY)

    -- Проверяем, образовались ли совпадения
    local marked = self:checkMatches(fromX, fromY, toX, toY)
    
    -- Если совпадений нет, возвращаем кристаллы на место
    if not next(marked) then
        self:swapGems(toX, toY, fromX, fromY)
        return false
    end

    return true
end

-- Основной цикл обработки изменений
function Game:tick()
    local marked = self:checkMatches()
    return self:removeMatches(marked)
end

-- Перемешивание поля
function Game:mix()
    local temp = {}
    for y = 0, FIELD_SIZE - 1 do
        for x = 0, FIELD_SIZE - 1 do
            table.insert(temp, self.field[y][x])
        end
    end

    for i = #temp, 2, -1 do
        local j = math.random(i)
        temp[i], temp[j] = temp[j], temp[i]
    end

    local index = 1
    for y = 0, FIELD_SIZE - 1 do
        for x = 0, FIELD_SIZE - 1 do
            self.field[y][x] = temp[index]
            index = index + 1
        end
    end
end

-- Задержка между выводами поля
function sleep(n)
    local t = os.clock()
    while os.clock() - t <= n do end
end

-- Вывод поля на экран
function Game:dump(message)
    if message then
        print(message)
    end
    print("    0 1 2 3 4 5 6 7 8 9")
    print("  --------------------")
    for y = 0, FIELD_SIZE - 1 do
        io.write(y .. " |")
        for x = 0, FIELD_SIZE - 1 do
            io.write(" " .. self.field[y][x])
        end
        print()
    end
    print()
end

-- Проверка наличия возможных ходов
function Game:checkPossibleMoves()
    -- Проверяем только потенциально возможные ходы
    for y = 0, FIELD_SIZE - 1 do
        for x = 0, FIELD_SIZE - 1 do
            local color = self.field[y][x]
            
            -- Проверяем правого соседа
            if x < FIELD_SIZE - 1 and self.field[y][x + 1] == color then
                -- Проверяем возможность образования тройки вправо
                if x < FIELD_SIZE - 2 and self.field[y][x + 2] == color then
                    return true
                end
                -- Проверяем возможность образования тройки вверх/вниз
                if y > 0 and self.field[y - 1][x + 1] == color then
                    return true
                end
                if y < FIELD_SIZE - 1 and self.field[y + 1][x + 1] == color then
                    return true
                end
            end
            
            -- Проверяем нижнего соседа
            if y < FIELD_SIZE - 1 and self.field[y + 1][x] == color then
                -- Проверяем возможность образования тройки вниз
                if y < FIELD_SIZE - 2 and self.field[y + 2][x] == color then
                    return true
                end
                -- Проверяем возможность образования тройки влево/вправо
                if x > 0 and self.field[y + 1][x - 1] == color then
                    return true
                end
                if x < FIELD_SIZE - 1 and self.field[y + 1][x + 1] == color then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Основной код игры
local game = Game.new()
game:init()
game:dump()

-- Основной игровой цикл
while true do
    io.write("> ")
    local input = io.read()
    
    if input == "q" then
        break
    end
    
    local command, x, y, direction = input:match("(%w+)%s+(%d+)%s+(%d+)%s+(%w+)")
    
    if command == "m" and x and y and direction then
        x = tonumber(x)
        y = tonumber(y)
        
        if game:move(x, y, direction) then
            -- Обработка изменений на поле
            local changes = true
            while changes do
                changes = game:tick()
                if changes then
                    game:dump("Совпадения! Кристаллы удаляются...")
                    sleep(0.5)
                end
            end
            
            -- Проверка на необходимость перемешивания
            if not game:checkPossibleMoves() then
                print("Нет возможных ходов. Перемешиваем поле...")
                game:mix()
                game:dump("Поле перемешано!")
            end
        else
            print("Некорректный ход!")
        end
    else
        print("Некорректная команда!")
        print("Используйте: m x y d (где d - l/r/u/d) или q для выхода")
    end
end 