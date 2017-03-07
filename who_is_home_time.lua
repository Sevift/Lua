-- Скрипт определяет местоположение iPhones
-- Сначала пингуем блютуз, если пинг прошел, значит телефон дома и следующий пинг будет через INTERVAL (10 минут) 
-- Если пинг по блютуз не прошел, интервал пинга меняется на каждую минуту и после ищем местоположение в iCloud
-- Если местоположение в радиусе RADIUS дома, то и телефон дома и интервал пинга опять INTERVAL (10 минут) 
-- Если местоположение не в радиусе, то выводим адрес через Google
-- Если местоположение сменилось с шагом STEP - то делаем опять запрос адреса через Google. Это сделано потому, что дневной лимит запросов адреса в Google ограничен
-- Если мы не получили координаты в iCloud, то телефон не в сети

commandArray = {}

function getAddress(longitude, latitude)
    local command = "curl -s https://maps.googleapis.com/maps/api/geocode/json?latlng=" .. latitude .. "," .. longitude .. "&sensor=false"
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    
    local output = json:decode(result)
    return output.results[1].formatted_address
end

function iCloud(user, credentials, iPhone, location, iPhoneName, locationName)

    local stage2server = "fmipmobile.icloud.com"
    local stage2command = "curl -s -X POST -L -u '" .. credentials.username .. ":" .. credentials.password .. "' -H 'Content-Type: application/json; charset=utf-8' -H 'X-Apple-Find-Api-Ver: 2.0' -H 'X-Apple-Authscheme: UserIdGuest' -H 'X-Apple-Realm-Support: 1.0' -H 'User-agent: Find iPhone/1.3 MeKit (iPad: iPhone OS/4.2.1)' -H 'X-Client-Name: iPad' -H 'X-Client-UUID: 0cf3dc501ff812adb0b202baed4f37274b210853' -H 'Accept-Language: en-us' -H 'Connection: keep-alive' https://" .. stage2server .. "/fmipservice/device/" .. credentials.username .."/initClient"
    local handle = io.popen(stage2command)
    local result = handle:read("*a")
    handle:close()
        
    local output = json:decode(result)

    for key,value in pairs(output.content) do
        if value.name == credentials.deviceName then
            
            local deviceStatus  = value.deviceStatus -- статус телефона 200, 201, 203
            print('Статус '..deviceStatus..' Имя '..value.name)
            
            if deviceStatus == '203' then -- 203 - оффлайн
                if location ~= STATUS_OFFLINE then 
                    commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[locationName]..'|0|'..STATUS_OFFLINE} 
                end
                if iPhone ~= 'Off' then
                    commandArray[#commandArray+1] = {[iPhoneName] = 'Off'}
                end
                
            else    
            
                local lon = value.location.longitude -- координаты
                local lat = value.location.latitude  -- координаты
        
                local distance = math.sqrt(((lon - HOMELONGITUDE) * 111.320 * math.cos(math.rad(lat)))^2 + ((lat - HOMELATITUDE) * 110.547)^2)  -- дистанция до дома
                local distance_text = '(' .. (math.floor(distance*10+0.5)/10) .. ' km)' -- (дистанция до дома)
        
                local prev_distance_text = string.match(location, '%(.*%)') -- (пред дистанция до дома)
                local prev_distance = tonumber(string.sub(prev_distance_text, 2,-5)) -- пред дистанция до дома
                

                if distance < RADIUS  then -- если телефон в радиусе дома
                    if location ~= STATUS_HOME then 
                        commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[locationName]..'|0|'..STATUS_HOME} 
                    end
                    if iPhone ~= 'On' then
                        commandArray[#commandArray+1] = {[iPhoneName] = 'On'}
                    end
                else
                    if math.abs(prev_distance - distance) > STEP then -- если телефон переместился с шагом STEP - для экономии вызовов
                        local address = getAddress(lon,lat) -- лимит вызовов гугла в сутки 2400
                        local address_distance_text = address..' '..distance_text
                        commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[locationName]..'|0|'..STATUS_NOT_HOME..' '..address_distance_text}
                        if iPhone ~= 'Off' then
                            commandArray[#commandArray+1] = {[iPhoneName] = 'Off'}
                        end
                    end
                end
            
            end
        end
    end
end  

function sleep(s)
  local ntime = os.clock() + s
  repeat until os.clock() > ntime
end

function bluetooth(iPhone, iPhoneName, locationName)
    if iPhone == 'Off' then        
        commandArray[#commandArray+1] = {[iPhoneName] = 'On'}
        commandArray[#commandArray+1] = {['UpdateDevice'] = otherdevices_idx[locationName]..'|0|'..STATUS_HOME}
        commandArray[#commandArray+1] = {['SendNotification'] = 'Presence update#' .. iPhoneName .. ' '..STATUS_HOME}
    end
end    

function pingBluetooth(bluetooth)
    sleep(2) -- пауза в секунду - за меньше не успевает пинговать все устройства
    local ping_success=os.execute('sudo l2ping -c 1 '..bluetooth)
    return ping_success
end

json = (loadfile "/home/pi/domoticz/scripts/lua/JSON.lua")()

-- Массив юзеров, паролей icloud и mac bluetooth
users = {
        Ivanov = {username = "***@icloud.com" ;   password = "***" ; deviceName = "iPhone (Ivanov)" ; bluetooth = "00:**:**:**:**:**"};
        Petrov  = {username = "***@icloud.com" ;  password = "***" ;   deviceName = "iPhone (Petrov)"  ; bluetooth = "54:**:**:**:**:**"};
        Sidorov   = {username = "***@icloud.com" ; password = "***" ;  deviceName = "iPhone (Sidorov)"  ; bluetooth = "90:**:**:**:**:**"}
        }
          
HOMELATITUDE  = 50.****** -- Координаты дома
HOMELONGITUDE = 12.******   
RADIUS = 0.5 -- Радиус дома в км
STEP   = 0.5 -- шаг перемещения для запроса адреса

STATUS_HOME     = 'Дома (0 km)'
STATUS_NOT_HOME = 'Не дома:'
STATUS_OFFLINE  = 'Не в сети (0 km)' 
INTERVAL = 10 -- Интервыал опроса в мин когда дома

for user,credentials in pairs(users) do
    
    local ping = true
    local iPhoneName   = 'iPhone ' .. user
    local locationName = 'Location ' .. user 
    local iPhone   = otherdevices[iPhoneName]
    local location = otherdevices[locationName]
    
    if iPhone == 'On' then -- если дома то период INTERVAL мин
        local m = os.date('%M')
        if (m % INTERVAL ~= 0) then
            ping = false
        end  
    end    
    
    if ping then
        ping_success = pingBluetooth(credentials.bluetooth) -- пингуем bluetooth
        if ping_success then -- если пинг прошел
            print("ping success "..user)
            bluetooth(iPhone, iPhoneName, locationName)
        else -- иначе ищем в iCloud 
            iCloud(user, credentials, iPhone, location, iPhoneName, locationName)
        end 
    end
end

return commandArray